import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';

/// "Backend de mentira" em memória, usado pelos repositórios Fake.
///
/// Para que serve:
/// - Quem faz telas trabalha SEM backend (`--dart-define=USAR_FAKE=true`).
/// - Testes de ViewModel rodam em milissegundos, sem rede.
/// - Demonstração offline do fluxo completo.
///
/// Ele aplica as MESMAS regras do backend (usa os validadores do
/// shared_models) e lança [ApiException] com os MESMOS códigos. Assim, trocar
/// Fake por API não muda nada nas telas (princípio de substituição de Liskov).
///
/// Diferenças propositais: prazo de reserva de 2 minutos (para ver a
/// expiração acontecer) e, a cada 45 segundos, uma "doação surpresa" aparece
/// para testar o aviso de novidade da ONG.
class BancoFake {
  BancoFake({
    Relogio relogio = const RelogioSistema(),
    this.atrasoDeRede = const Duration(milliseconds: 350),
    this.prazoReserva = const Duration(minutes: 2),
    this.fusoHorarioUtc = -3,
    this.simularNovasDoacoes = true,
  }) : _relogio = relogio {
    _popular();
  }

  static const senhaPadrao = 'senha123';
  static const raioPadraoKm = 10.0;

  final Relogio _relogio;
  final Duration atrasoDeRede;
  final Duration prazoReserva;
  final int fusoHorarioUtc;
  final bool simularNovasDoacoes;

  final Map<int, _ContaFake> _contas = {};
  final List<Doacao> _doacoes = [];
  final List<Reserva> _reservas = [];
  int _proximoId = 1;
  int? _logadoId;
  DateTime? _ultimaSimulacao;

  static const _naoEncontrada = ApiException(
    codigo: 'NAO_ENCONTRADO',
    mensagem: 'Registro não encontrado.',
    status: 404,
  );

  static const _reservaNaoAtiva = ApiException(
    codigo: 'RESERVA_NAO_ATIVA',
    mensagem: 'Esta reserva não está mais ativa.',
    status: 409,
  );

  /// Cópias somente leitura (úteis em testes).
  List<Doacao> get doacoes => List.unmodifiable(_doacoes);
  List<Reserva> get reservas => List.unmodifiable(_reservas);

  DateTime get _agora => _relogio.agora();

  /// Espera um pouco (para as telas mostrarem "carregando") e aplica a
  /// expiração das reservas vencidas, como o job do backend faria.
  Future<void> simularRede() async {
    if (atrasoDeRede > Duration.zero) {
      await Future<void>.delayed(atrasoDeRede);
    }
    _expirarReservasVencidas();
  }

  // ---------------------------------------------------------------- contas

  Conta cadastrar(DadosCadastro dadosRecebidos) {
    final dados = dadosRecebidos.normalizado();
    final erros = ValidadorUsuario.validarCadastro(dados);
    if (erros.isNotEmpty) {
      throw ApiException(
        codigo: 'VALIDACAO',
        mensagem: erros.first,
        status: 400,
        detalhes: erros,
      );
    }
    if (_contas.values.any((c) => c.conta.usuario.email == dados.email)) {
      throw const ApiException(
        codigo: 'EMAIL_EM_USO',
        mensagem: 'Este e-mail já está cadastrado.',
        status: 409,
      );
    }
    final id = _proximoId++;
    final conta = Conta(
      usuario: Usuario(
        id: id,
        nome: dados.nome,
        email: dados.email,
        tipo: dados.tipo,
      ),
      perfil: Perfil(
        usuarioId: id,
        nomeOrganizacao: dados.nomeOrganizacao,
        telefone: dados.telefone,
        endereco: dados.endereco,
        latitude: dados.latitude,
        longitude: dados.longitude,
      ),
    );
    _contas[id] = _ContaFake(conta, dados.senha);
    return conta;
  }

  Conta autenticar(String email, String senha) {
    final procurado = email.trim().toLowerCase();
    for (final registro in _contas.values) {
      if (registro.conta.usuario.email == procurado &&
          registro.senha == senha) {
        return registro.conta;
      }
    }
    throw const ApiException(
      codigo: 'CREDENCIAIS_INVALIDAS',
      mensagem: 'E-mail ou senha incorretos.',
      status: 401,
    );
  }

  /// Token falso no formato `fake-<id>`. Também marca quem está logado.
  String tokenPara(Conta conta) {
    _logadoId = conta.usuario.id;
    return 'fake-${conta.usuario.id}';
  }

  Conta? contaDoToken(String? token) {
    if (token == null || !token.startsWith('fake-')) return null;
    final conta = _contas[int.tryParse(token.substring(5))]?.conta;
    if (conta != null) _logadoId = conta.usuario.id;
    return conta;
  }

  // -------------------------------------------------------------- doações

  Doacao criarDoacao(DadosNovaDoacao dados) {
    final conta = _exigirLogado(TipoUsuario.doador);
    final agora = _agora;
    final erros = ValidadorDoacao.validar(
      dados,
      agora: agora,
      hoje: Calendario.dataNoFuso(agora, fusoHorarioUtc),
    );
    if (erros.isNotEmpty) {
      throw ApiException(
        codigo: 'VALIDACAO',
        mensagem: erros.first,
        status: 400,
        detalhes: erros,
      );
    }
    final doacao = Doacao(
      id: _proximoId++,
      doadorId: conta.usuario.id,
      titulo: dados.titulo.trim(),
      descricao: dados.descricao,
      categoria: dados.categoria,
      quantidade: dados.quantidade.trim(),
      validade: dados.validade,
      janelaInicio: dados.janelaInicio,
      janelaFim: dados.janelaFim,
      endereco: dados.endereco ?? conta.perfil.endereco,
      latitude: dados.latitude ?? conta.perfil.latitude,
      longitude: dados.longitude ?? conta.perfil.longitude,
      status: StatusDoacao.disponivel,
      criadoEm: agora,
      nomeDoador: conta.perfil.nomeOrganizacao,
    );
    _doacoes.add(doacao);
    return doacao;
  }

  List<Doacao> doacoesDoDoadorLogado() {
    final conta = _exigirLogado(TipoUsuario.doador);
    return _doacoes.where((d) => d.doadorId == conta.usuario.id).toList()
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
  }

  /// Regras de acesso (iguais às do backend): o doador vê só as próprias;
  /// a ONG vê as disponíveis e a que ela mesma reservou.
  DetalheDoacao detalharDoacao(int doacaoId) {
    final conta = _exigirQualquerLogado();
    final doacao = _doacao(doacaoId);
    final reserva = _reservaAtivaDa(doacaoId);
    final usuario = conta.usuario;
    if (usuario.ehDoador && doacao.doadorId != usuario.id) throw _naoEncontrada;
    if (usuario.ehOng &&
        !doacao.podeSerReservada(_agora) &&
        reserva?.ongId != usuario.id) {
      throw _naoEncontrada;
    }
    return DetalheDoacao(doacao: doacao, reserva: reserva);
  }

  void cancelarDoacao(int doacaoId) {
    final conta = _exigirLogado(TipoUsuario.doador);
    final doacao = _doacao(doacaoId);
    if (doacao.doadorId != conta.usuario.id) throw _naoEncontrada;
    if (!doacao.podeSerCancelada) {
      throw const ApiException(
        codigo: 'DOACAO_NAO_CANCELAVEL',
        mensagem: 'Só é possível cancelar doações que ainda não foram '
            'reservadas.',
        status: 409,
      );
    }
    _substituirDoacao(doacao.copyWith(status: StatusDoacao.cancelada));
  }

  // ---------------------------------------------------------- proximidade

  List<Doacao> doacoesProximas({double? raioKm}) {
    final conta = _exigirLogado(TipoUsuario.ong);
    _talvezSimularNovaDoacao();
    final raio = (raioKm ?? raioPadraoKm).clamp(0.5, 50.0);
    final agora = _agora;
    final proximas = <Doacao>[];
    for (final doacao in _doacoes) {
      if (!doacao.podeSerReservada(agora)) continue;
      final km = Geo.distanciaKm(conta.perfil.coordenadas, doacao.coordenadas);
      if (km <= raio) proximas.add(doacao.copyWith(distanciaKm: km));
    }
    proximas.sort((a, b) => a.distanciaKm!.compareTo(b.distanciaKm!));
    return proximas;
  }

  // -------------------------------------------------------------- reservas

  Reserva reservar(int doacaoId) {
    final conta = _exigirLogado(TipoUsuario.ong);
    final agora = _agora;
    final doacao = _doacao(doacaoId);
    if (!doacao.podeSerReservada(agora)) {
      throw const ApiException(
        codigo: 'DOACAO_INDISPONIVEL',
        mensagem: 'Esta doação acabou de ser reservada por outra ONG ou não '
            'está mais disponível.',
        status: 409,
      );
    }
    // Regra: o prazo nunca passa do fim da janela de retirada.
    final limite = agora.add(prazoReserva);
    final reserva = Reserva(
      id: _proximoId++,
      doacaoId: doacaoId,
      ongId: conta.usuario.id,
      status: StatusReserva.ativa,
      reservadoEm: agora,
      expiraEm: limite.isBefore(doacao.janelaFim) ? limite : doacao.janelaFim,
      tituloDoacao: doacao.titulo,
      nomeOng: conta.perfil.nomeOrganizacao,
    );
    _reservas.add(reserva);
    _substituirDoacao(doacao.copyWith(status: StatusDoacao.reservada));
    return reserva;
  }

  List<Reserva> reservasDaOngLogada() {
    final conta = _exigirLogado(TipoUsuario.ong);
    return _reservas.where((r) => r.ongId == conta.usuario.id).toList()
      ..sort((a, b) => b.reservadoEm.compareTo(a.reservadoEm));
  }

  void cancelarReserva(int reservaId) {
    final conta = _exigirLogado(TipoUsuario.ong);
    final reserva = _reserva(reservaId);
    if (reserva.ongId != conta.usuario.id) throw _naoEncontrada;
    if (!reserva.estaAtiva) throw _reservaNaoAtiva;
    _substituirReserva(_comStatus(reserva, StatusReserva.cancelada));
    _mudarStatusDoacao(reserva.doacaoId, StatusDoacao.disponivel);
  }

  /// A ONG dona da reserva OU o doador dono da doação podem confirmar.
  Reserva confirmarRetirada(int reservaId) {
    final conta = _exigirQualquerLogado();
    final reserva = _reserva(reservaId);
    final doacao = _doacao(reserva.doacaoId);
    final usuario = conta.usuario;
    final permitido = usuario.ehOng
        ? reserva.ongId == usuario.id
        : doacao.doadorId == usuario.id;
    if (!permitido) throw _naoEncontrada;
    if (!reserva.estaAtiva) throw _reservaNaoAtiva;
    final concluida = _comStatus(
      reserva,
      StatusReserva.concluida,
      retiradoEm: _agora,
    );
    _substituirReserva(concluida);
    _substituirDoacao(doacao.copyWith(status: StatusDoacao.concluida));
    return concluida;
  }

  // -------------------------------------------------------------- internos

  Conta _exigirQualquerLogado() {
    final conta = _contas[_logadoId]?.conta;
    if (conta == null) {
      throw const ApiException(
        codigo: 'NAO_AUTENTICADO',
        mensagem: 'Faça login para continuar.',
        status: 401,
      );
    }
    return conta;
  }

  Conta _exigirLogado(TipoUsuario tipo) {
    final conta = _exigirQualquerLogado();
    if (conta.usuario.tipo != tipo) {
      throw ApiException(
        codigo: 'SEM_PERMISSAO',
        mensagem: 'Esta ação está disponível apenas para o perfil '
            '${tipo.rotulo}.',
        status: 403,
      );
    }
    return conta;
  }

  Doacao _doacao(int id) {
    for (final doacao in _doacoes) {
      if (doacao.id == id) return doacao;
    }
    throw _naoEncontrada;
  }

  Reserva _reserva(int id) {
    for (final reserva in _reservas) {
      if (reserva.id == id) return reserva;
    }
    throw _naoEncontrada;
  }

  Reserva? _reservaAtivaDa(int doacaoId) {
    for (final reserva in _reservas) {
      if (reserva.doacaoId == doacaoId && reserva.estaAtiva) return reserva;
    }
    return null;
  }

  void _substituirDoacao(Doacao nova) {
    final i = _doacoes.indexWhere((d) => d.id == nova.id);
    if (i >= 0) _doacoes[i] = nova;
  }

  void _mudarStatusDoacao(int doacaoId, StatusDoacao status) =>
      _substituirDoacao(_doacao(doacaoId).copyWith(status: status));

  void _substituirReserva(Reserva nova) {
    final i = _reservas.indexWhere((r) => r.id == nova.id);
    if (i >= 0) _reservas[i] = nova;
  }

  static Reserva _comStatus(
    Reserva reserva,
    StatusReserva status, {
    DateTime? retiradoEm,
  }) =>
      Reserva(
        id: reserva.id,
        doacaoId: reserva.doacaoId,
        ongId: reserva.ongId,
        status: status,
        reservadoEm: reserva.reservadoEm,
        expiraEm: reserva.expiraEm,
        retiradoEm: retiradoEm ?? reserva.retiradoEm,
        tituloDoacao: reserva.tituloDoacao,
        nomeOng: reserva.nomeOng,
      );

  void _expirarReservasVencidas() {
    final agora = _agora;
    for (final reserva in List.of(_reservas)) {
      if (reserva.estaVencida(agora)) {
        _substituirReserva(_comStatus(reserva, StatusReserva.expirada));
        _mudarStatusDoacao(reserva.doacaoId, StatusDoacao.disponivel);
      }
    }
  }

  void _talvezSimularNovaDoacao() {
    if (!simularNovasDoacoes) return;
    final agora = _agora;
    final ultima = _ultimaSimulacao;
    if (ultima == null) {
      _ultimaSimulacao = agora;
      return;
    }
    if (agora.difference(ultima) < const Duration(seconds: 45)) return;
    _ultimaSimulacao = agora;

    final doador = _contas.values
        .map((registro) => registro.conta)
        .firstWhere((conta) => conta.usuario.ehDoador);
    final numero = _doacoes.length + 1;
    _doacoes.add(
      Doacao(
        id: _proximoId++,
        doadorId: doador.usuario.id,
        titulo: 'Doação surpresa nº $numero',
        descricao: 'Criada automaticamente no modo demonstração.',
        categoria: CategoriaAlimento
            .values[numero % CategoriaAlimento.values.length],
        quantidade: '${2 + numero % 5} caixas',
        validade: Calendario.dataNoFuso(agora, fusoHorarioUtc)
            .add(const Duration(days: 2)),
        janelaInicio: agora,
        janelaFim: agora.add(const Duration(hours: 3)),
        endereco: doador.perfil.endereco,
        latitude: doador.perfil.latitude,
        longitude: doador.perfil.longitude,
        status: StatusDoacao.disponivel,
        criadoEm: agora,
        nomeDoador: doador.perfil.nomeOrganizacao,
      ),
    );
  }

  /// Mesmos dados do `backend/tool/seed.dart`.
  void _popular() {
    final agora = _agora;
    final hoje = Calendario.dataNoFuso(agora, fusoHorarioUtc);

    Conta conta(
      TipoUsuario tipo,
      String nome,
      String email,
      String organizacao,
      String endereco,
      double latitude,
      double longitude,
    ) =>
        cadastrar(
          DadosCadastro(
            tipo: tipo,
            nome: nome,
            email: email,
            senha: senhaPadrao,
            nomeOrganizacao: organizacao,
            endereco: endereco,
            latitude: latitude,
            longitude: longitude,
          ),
        );

    final mercado = conta(TipoUsuario.doador, 'Gerente do Mercado',
        'mercado@exemplo.com', 'Mercado Bom Preço',
        'Rua Principal, 100 - Centro', -23.5229, -46.1880);
    final padaria = conta(TipoUsuario.doador, 'Dono da Padaria',
        'padaria@exemplo.com', 'Padaria Pão Quente',
        'Avenida das Flores, 250', -23.5262, -46.1932);
    final maosAmigas = conta(TipoUsuario.ong, 'Coordenação Mãos Amigas',
        'maosamigas@exemplo.com', 'ONG Mãos Amigas',
        'Rua da Solidariedade, 45', -23.5180, -46.1850);
    final pratoCheio = conta(TipoUsuario.ong, 'Coordenação Prato Cheio',
        'pratocheio@exemplo.com', 'Instituto Prato Cheio',
        'Travessa do Bem, 12', -23.5400, -46.2100);
    conta(TipoUsuario.ong, 'Coordenação Distante', 'distante@exemplo.com',
        'Associação Distante', 'Praça da Sé - São Paulo', -23.5505, -46.6333);

    Doacao doacao(
      Conta doador,
      String titulo,
      CategoriaAlimento categoria,
      String quantidade,
      int diasDeValidade,
      Duration inicio,
      Duration fim,
      StatusDoacao status,
    ) {
      final nova = Doacao(
        id: _proximoId++,
        doadorId: doador.usuario.id,
        titulo: titulo,
        categoria: categoria,
        quantidade: quantidade,
        validade: hoje.add(Duration(days: diasDeValidade)),
        janelaInicio: agora.add(inicio),
        janelaFim: agora.add(fim),
        endereco: doador.perfil.endereco,
        latitude: doador.perfil.latitude,
        longitude: doador.perfil.longitude,
        status: status,
        criadoEm: agora.subtract(const Duration(minutes: 30)),
        nomeDoador: doador.perfil.nomeOrganizacao,
      );
      _doacoes.add(nova);
      return nova;
    }

    doacao(mercado, 'Frutas e verduras do dia', CategoriaAlimento.hortifruti,
        '5 caixas', 2, const Duration(hours: -1), const Duration(hours: 6),
        StatusDoacao.disponivel);
    doacao(padaria, 'Pães do dia anterior', CategoriaAlimento.padaria,
        '30 unidades', 1, Duration.zero, const Duration(hours: 4),
        StatusDoacao.disponivel);
    doacao(mercado, 'Iogurtes perto do vencimento',
        CategoriaAlimento.laticinios, '24 potes', 3,
        const Duration(hours: 1), const Duration(hours: 8),
        StatusDoacao.disponivel);

    final cestas = doacao(mercado, 'Cestas de mercearia',
        CategoriaAlimento.mercearia, '10 cestas', 30, Duration.zero,
        const Duration(hours: 5), StatusDoacao.reservada);
    _reservas.add(
      Reserva(
        id: _proximoId++,
        doacaoId: cestas.id,
        ongId: maosAmigas.usuario.id,
        status: StatusReserva.ativa,
        reservadoEm: agora,
        expiraEm: agora.add(prazoReserva),
        tituloDoacao: cestas.titulo,
        nomeOng: maosAmigas.perfil.nomeOrganizacao,
      ),
    );

    final bolos = doacao(padaria, 'Bolos e salgados',
        CategoriaAlimento.refeicoesProntas, '15 porções', 0,
        const Duration(hours: -5), const Duration(hours: -1),
        StatusDoacao.concluida);
    _reservas.add(
      Reserva(
        id: _proximoId++,
        doacaoId: bolos.id,
        ongId: pratoCheio.usuario.id,
        status: StatusReserva.concluida,
        reservadoEm: agora.subtract(const Duration(hours: 4)),
        expiraEm: agora.subtract(const Duration(hours: 2)),
        retiradoEm: agora.subtract(const Duration(hours: 3)),
        tituloDoacao: bolos.titulo,
        nomeOng: pratoCheio.perfil.nomeOrganizacao,
      ),
    );
  }
}

class _ContaFake {
  _ContaFake(this.conta, this.senha);

  final Conta conta;
  final String senha;
}
