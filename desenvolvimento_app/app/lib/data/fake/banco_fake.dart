import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';
import 'chat_fake.dart';
import 'contas_fake.dart';
import 'doacoes_fake.dart';
import 'exemplos_fake.dart';
import 'notificacoes_fake.dart';
import 'receita_fake.dart';
import 'retiradas_fake.dart';

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
/// menores: [ContasFake] (cadastro e login), [DoacoesFake] (doações) e
/// [RetiradasFake] (aceite, código, desistência e suspensão).
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
    notificacoes = NotificacoesFake(relogio, _contas)
      ..bloqueios = _doacoes.bloqueios;
    chat = ChatFake(relogio, _contas, _doacoes, notificacoes);
    retiradas = RetiradasFake(
      relogio,
      _contas,
      _doacoes,
      notificacoes,
      chat,
      RegrasDaRetirada(prazo: prazoReserva),
    );
    ExemplosFake(_doacoes, _contas, chat, agora: relogio.agora()).criar();
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

  /// As regras de aceite e retirada (usadas pelo `ReservaRepositoryFake`).
  late final RetiradasFake retiradas;

  /// Os avisos (usados pelo `NotificacaoRepositoryFake`).
  late final NotificacoesFake notificacoes;

  /// O chat das retiradas (usado pelo `ChatRepositoryFake`).
  late final ChatFake chat;

  /// Quem está logado agora (o "token" do Fake).
  int? get logadoId => _logadoId;
  int? _logadoId;
  DateTime? _ultimaSimulacao;

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
    retiradas.expirarVencidas();
  }

  // ---------------------------------------------------------------- contas

  /// RN01–RN04 (ver [ContasFake.cadastrar]).
  Conta cadastrar(DadosCadastro dados) => _contas.cadastrar(dados);

  Conta autenticar(String email, String senha) =>
      _contas.autenticar(email, senha);

  /// Pré-consulta do CNPJ, como `GET /documentos/{numero}` (RN03).
  InfoCnpj consultarCnpj(String numero, TipoUsuario tipo) =>
      ReceitaFake.preConsultar(numero, tipo);

  /// `PUT /perfil` (busca ativa, raio e dados da organização).
  Conta atualizarPerfil(DadosPerfil dados) =>
      _contas.atualizarPerfil(_exigirQualquerLogado().usuario.id, dados);

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

  RespostaPublicacao publicarDoacao(DadosNovaDoacao dados) {
    final doacao = _doacoes.criar(_exigirLogado(TipoUsuario.doador), dados);
    return RespostaPublicacao(
      doacao: doacao,
      ongsAvisadas: notificacoes.avisarOngsProximas(doacao), // RN11
    );
  }

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

  // ------------------------------------------------------------ retiradas

  /// A conta logada (qualquer tipo).
  Conta contaLogada() => _exigirQualquerLogado();

  /// A conta logada, se for ONG (senão, 403 como no backend).
  Conta ongLogada() => _exigirLogado(TipoUsuario.ong);

  /// A conta logada, se for doador.
  Conta doadorLogado() => _exigirLogado(TipoUsuario.doador);

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

  /// Modo demonstração: a cada 45 s aparece uma doação nova do mercado.
  void _talvezSimularNovaDoacao() {
    if (!simularNovasDoacoes) return;
    final ultima = _ultimaSimulacao;
    _ultimaSimulacao ??= _agora;
    if (ultima == null || _agora.difference(ultima).inSeconds < 45) return;
    _ultimaSimulacao = _agora;
    final numero = _doacoes.doacoes.length + 1;
    final surpresa = _doacoes.criar(
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
    notificacoes.avisarOngsProximas(surpresa); // RN11
  }
}
