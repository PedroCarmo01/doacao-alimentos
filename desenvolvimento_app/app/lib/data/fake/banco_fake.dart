import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';
import 'contas_fake.dart';
import 'doacoes_fake.dart';
import 'exemplos_fake.dart';
import 'receita_fake.dart';

/// "Backend de mentira" em memória, usado pelos repositórios Fake.
///
/// Para que serve:
/// - Quem faz telas trabalha SEM backend (`--dart-define=USAR_FAKE=true`).
/// - Testes de ViewModel rodam em milissegundos, sem rede.
/// - Demonstração offline do fluxo completo (plano B da apresentação).
///
/// Ele aplica as MESMAS regras do backend e lança [ApiException] com os
/// MESMOS códigos. Assim, trocar Fake por API não muda nada nas telas
/// (princípio de substituição de Liskov). As regras ficam em classes
/// menores: [ContasFake] (cadastro e login) e [DoacoesFake] (doações).
///
/// Diferenças propositais: prazo de retirada de 2 minutos (para ver a
/// expiração acontecer) e, a cada 45 segundos, uma "doação surpresa"
/// aparece para testar o aviso de novidade da ONG.
class BancoFake {
  BancoFake({
    Relogio relogio = const RelogioSistema(),
    this.atrasoDeRede = const Duration(milliseconds: 350),
    this.prazoReserva = const Duration(minutes: 2),
    this.fusoHorarioUtc = -3,
    this.simularNovasDoacoes = true,
  }) : _relogio = relogio,
       _contas = ContasFake(relogio) {
    _doacoes = DoacoesFake(relogio, _contas, fusoHorarioUtc: fusoHorarioUtc);
    ExemplosFake(_doacoes, _contas, agora: relogio.agora()).criar();
  }

  static const senhaPadrao = ContasFake.senhaPadrao;
  static const raioPadraoKm = Perfil.raioPadraoKm;

  final Relogio _relogio;
  final Duration atrasoDeRede;
  final Duration prazoReserva;
  final int fusoHorarioUtc;
  final bool simularNovasDoacoes;

  final ContasFake _contas;
  late final DoacoesFake _doacoes;
  int? _logadoId;
  DateTime? _ultimaSimulacao;

  static const _reservaNaoAtiva = ApiException(
    codigo: 'RESERVA_NAO_ATIVA',
    mensagem: 'Esta retirada não está mais em andamento.',
    status: 409,
  );

  /// Cópias somente leitura (úteis em testes).
  List<Doacao> get doacoes => List.unmodifiable(_doacoes.doacoes);
  List<Reserva> get reservas => List.unmodifiable(_doacoes.reservas);

  DateTime get _agora => _relogio.agora();

  /// Espera um pouco (para as telas mostrarem "carregando") e aplica a
  /// expiração das retiradas vencidas, como o job do backend faria.
  Future<void> simularRede() async {
    if (atrasoDeRede > Duration.zero) {
      await Future<void>.delayed(atrasoDeRede);
    }
    _expirarReservasVencidas();
  }

  // ---------------------------------------------------------------- contas

  /// RN01–RN04 (ver [ContasFake.cadastrar]).
  Conta cadastrar(DadosCadastro dados) => _contas.cadastrar(dados);

  Conta autenticar(String email, String senha) =>
      _contas.autenticar(email, senha);

  /// Pré-consulta do CNPJ, como `GET /documentos/{numero}` (RN03).
  InfoCnpj consultarCnpj(String numero, TipoUsuario tipo) =>
      ReceitaFake.preConsultar(numero, tipo);

  /// Token falso no formato `fake-<id>`. Também marca quem está logado.
  String tokenPara(Conta conta) {
    _logadoId = conta.usuario.id;
    return 'fake-${conta.usuario.id}';
  }

  Conta? contaDoToken(String? token) {
    if (token == null || !token.startsWith('fake-')) return null;
    final conta = _contas.porId(int.tryParse(token.substring(5)));
    if (conta != null) _logadoId = conta.usuario.id;
    return conta;
  }

  // -------------------------------------------------------------- doações

  RespostaPublicacao publicarDoacao(DadosNovaDoacao dados) =>
      RespostaPublicacao(
        doacao: _doacoes.criar(_exigirLogado(TipoUsuario.doador), dados),
        ongsAvisadas: 0, // RN11: os avisos entram na etapa 5
      );

  Doacao editarDoacao(int id, DadosNovaDoacao dados) =>
      _doacoes.editar(_exigirLogado(TipoUsuario.doador), id, dados);

  Doacao adicionarFoto(int id, String caminho) =>
      _doacoes.adicionarFoto(_exigirLogado(TipoUsuario.doador), id, caminho);

  void cancelarDoacao(int id, {String? motivo}) =>
      _doacoes.cancelar(_exigirLogado(TipoUsuario.doador), id, motivo: motivo);

  List<Doacao> doacoesDoDoadorLogado(SituacaoDaLista situacao) =>
      _doacoes.doDoador(_exigirLogado(TipoUsuario.doador), situacao);

  DetalheDoacao detalharDoacao(int id) =>
      _doacoes.detalhar(_exigirQualquerLogado(), id);

  /// Disponíveis no raio da ONG logada, da mais perto para a mais longe.
  List<Doacao> doacoesProximas({double? raioKm}) {
    final conta = _exigirLogado(TipoUsuario.ong);
    _talvezSimularNovaDoacao();
    _doacoes.expirarJanelasEncerradas();
    final raio = (raioKm ?? conta.perfil.raioKm).clamp(0.5, 50.0);
    final proximas = <Doacao>[];
    for (final doacao in _doacoes.doacoes) {
      if (!doacao.podeSerReservada(_agora)) continue;
      if (_doacoes.bloqueios.contains('${conta.usuario.id}-${doacao.id}')) {
        continue; // RN22
      }
      final km = Geo.distanciaKm(conta.perfil.coordenadas, doacao.coordenadas);
      if (km <= raio) proximas.add(doacao.copyWith(distanciaKm: km));
    }
    proximas.sort((a, b) => a.distanciaKm!.compareTo(b.distanciaKm!));
    return proximas;
  }

  // ------------------------------------------- retiradas (refeitas na etapa 4)

  Reserva reservar(int doacaoId) {
    final conta = _exigirLogado(TipoUsuario.ong);
    final doacao = _doacoes.porId(doacaoId);
    if (!doacao.podeSerReservada(_agora)) {
      throw const ApiException(
        codigo: 'DOACAO_INDISPONIVEL',
        mensagem: 'Que pena! Outra ONG aceitou esta doação primeiro.',
        status: 409,
      );
    }
    // RN21: o prazo nunca passa do fim do horário de retirada.
    final limite = _agora.add(prazoReserva);
    final reserva = Reserva(
      id: _doacoes.novoId(),
      doacaoId: doacaoId,
      ongId: conta.usuario.id,
      status: StatusReserva.ativa,
      reservadoEm: _agora,
      expiraEm: limite.isBefore(doacao.janelaFim) ? limite : doacao.janelaFim,
      tituloDoacao: doacao.titulo,
      nomeOng: conta.perfil.nomeOrganizacao,
    );
    _doacoes.reservas.add(reserva);
    _doacoes.salvar(doacao.copyWith(status: StatusDoacao.reservada));
    return reserva;
  }

  List<Reserva> reservasDaOngLogada() {
    final conta = _exigirLogado(TipoUsuario.ong);
    return _doacoes.reservas.where((r) => r.ongId == conta.usuario.id).toList()
      ..sort((a, b) => b.reservadoEm.compareTo(a.reservadoEm));
  }

  void cancelarReserva(int reservaId) {
    final conta = _exigirLogado(TipoUsuario.ong);
    final reserva = _reserva(reservaId);
    if (reserva.ongId != conta.usuario.id) throw DoacoesFake.naoEncontrada;
    if (!reserva.estaAtiva) throw _reservaNaoAtiva;
    _doacoes.trocarReserva(
      reserva,
      StatusReserva.canceladaOng,
      encerradaEm: _agora,
    );
    _voltarParaDisponivel(reserva.doacaoId);
  }

  /// A ONG dona da retirada OU o doador dono da doação podem confirmar.
  Reserva confirmarRetirada(int reservaId) {
    final usuario = _exigirQualquerLogado().usuario;
    final reserva = _reserva(reservaId);
    final doacao = _doacoes.porId(reserva.doacaoId);
    final permitido = usuario.ehOng
        ? reserva.ongId == usuario.id
        : doacao.doadorId == usuario.id;
    if (!permitido) throw DoacoesFake.naoEncontrada;
    if (!reserva.estaAtiva) throw _reservaNaoAtiva;
    _doacoes.trocarReserva(
      reserva,
      StatusReserva.concluida,
      encerradaEm: _agora,
    );
    _doacoes.salvar(doacao.copyWith(status: StatusDoacao.concluida));
    return _reserva(reservaId);
  }

  // -------------------------------------------------------------- internos

  Conta _exigirQualquerLogado() {
    final conta = _contas.porId(_logadoId);
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
        mensagem:
            'Esta ação está disponível apenas para o perfil '
            '${tipo.rotulo}.',
        status: 403,
      );
    }
    return conta;
  }

  Reserva _reserva(int id) =>
      _doacoes.reservas.where((r) => r.id == id).firstOrNull ??
      (throw DoacoesFake.naoEncontrada);

  void _voltarParaDisponivel(int doacaoId) => _doacoes.salvar(
    _doacoes.porId(doacaoId).copyWith(status: StatusDoacao.disponivel),
  );

  void _expirarReservasVencidas() {
    for (final reserva in List.of(_doacoes.reservas)) {
      if (reserva.estaVencida(_agora)) {
        _doacoes.trocarReserva(
          reserva,
          StatusReserva.expirada,
          encerradaEm: _agora,
        );
        _voltarParaDisponivel(reserva.doacaoId);
      }
    }
  }

  /// Modo demonstração: a cada 45 s aparece uma doação nova do mercado.
  void _talvezSimularNovaDoacao() {
    if (!simularNovasDoacoes) return;
    final ultima = _ultimaSimulacao;
    _ultimaSimulacao ??= _agora;
    if (ultima == null || _agora.difference(ultima).inSeconds < 45) return;
    _ultimaSimulacao = _agora;
    final numero = _doacoes.doacoes.length + 1;
    _doacoes.criar(
      _contas.primeiroDoador,
      DadosNovaDoacao(
        titulo: 'Doação surpresa nº $numero',
        descricao: 'Criada automaticamente no modo demonstração.',
        categoria: CategoriaAlimento.hortifruti,
        quantidade: 2 + numero % 5,
        unidade: Unidade.caixas,
        pesoKg: 10,
        conservacao: Conservacao.ambiente,
        validade: Calendario.somenteData(_agora.add(const Duration(days: 2))),
        janelaInicio: _agora,
        janelaFim: _agora.add(const Duration(hours: 3)),
        declaracaoAlimentosProprios: true,
      ),
    );
  }
}
