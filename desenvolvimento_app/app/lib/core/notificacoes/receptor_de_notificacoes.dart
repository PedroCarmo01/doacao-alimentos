import 'dart:async';
import 'dart:convert';

import 'package:shared_models/shared_models.dart';

import '../../data/notificacoes/notificacao_repository.dart';
import 'mostrador_de_notificacoes.dart';

/// Como os avisos do servidor CHEGAM ao app (seção 9 da especificação).
///
/// POLIMORFISMO: hoje usamos o [ReceptorPorConsulta]. Para o push real
/// (Firebase), basta criar um `ReceptorPush` com esta mesma interface e
/// trocar UMA linha em `Dependencias`. A casca e as telas não mudam.
abstract interface class ReceptorDeNotificacoes {
  /// Começa a receber (depois do login). [aoTocar] abre a tela certa.
  Future<void> iniciar({required void Function(Notificacao) aoTocar});

  /// Para de receber (ao sair da conta).
  void parar();

  /// A conversa que está aberta na tela (ou `null`). Mensagens dela não
  /// viram notificação: a pessoa já está vendo.
  void conversaAberta(int? reservaId);
}

/// Pergunta ao servidor a cada [intervalo] se há avisos novos e mostra
/// cada um como notificação do Android (com som).
///
/// Limitação conhecida: com o app FECHADO (removido dos recentes), o
/// Timer não roda e o aviso só aparece quando o app abrir de novo.
class ReceptorPorConsulta implements ReceptorDeNotificacoes {
  ReceptorPorConsulta({
    required NotificacaoRepository notificacoes,
    required MostradorDeNotificacoes mostrador,
    required Relogio relogio,
    this.intervalo = const Duration(seconds: 15),
  }) : _notificacoes = notificacoes,
       _mostrador = mostrador,
       _relogio = relogio;

  final NotificacaoRepository _notificacoes;
  final MostradorDeNotificacoes _mostrador;
  final Relogio _relogio;
  final Duration intervalo;

  /// Avisos mais velhos que isto, na primeira consulta, não apitam (a
  /// pessoa ficou dias sem abrir o app: não vale tocar 20 vezes).
  static const idadeMaxima = Duration(hours: 1);

  Timer? _timer;
  int _ultimoId = 0;
  int? _conversaAberta;
  bool _consultando = false;

  @override
  Future<void> iniciar({required void Function(Notificacao) aoTocar}) async {
    await _mostrador.preparar((payload) => aoTocar(_ler(payload)));
    await _mostrador.pedirPermissao(); // só aparece se ainda não respondeu

    // O app foi aberto tocando numa notificação (estava fechado).
    final payload = await _mostrador.payloadQueAbriuOApp();
    if (payload != null) aoTocar(_ler(payload));

    _timer ??= Timer.periodic(intervalo, (_) => consultar());
    await consultar();
  }

  @override
  void parar() {
    _timer?.cancel();
    _timer = null;
    _ultimoId = 0;
  }

  @override
  void conversaAberta(int? reservaId) => _conversaAberta = reservaId;

  bool _jaNaTela(Notificacao n) =>
      n.tipo == TipoNotificacao.mensagemNova &&
      n.reservaId != null &&
      n.reservaId == _conversaAberta;

  /// Uma consulta. Pública para os testes chamarem sem esperar o Timer.
  Future<void> consultar() async {
    if (_consultando) return;
    _consultando = true;
    try {
      final novas = await _notificacoes.novas(_ultimoId);
      if (novas.isEmpty) return;
      final limite = _relogio.agora().subtract(idadeMaxima);
      for (final n in novas) {
        if (!n.lida && n.criadoEm.isAfter(limite) && !_jaNaTela(n)) {
          await _mostrador.mostrar(n, payload: jsonEncode(n.toJson()));
        }
      }
      _ultimoId = novas.last.id;
      await _notificacoes.marcarLidas(_ultimoId);
    } catch (_) {
      // Sem internet por um instante: a próxima consulta resolve.
    } finally {
      _consultando = false;
    }
  }

  static Notificacao _ler(String payload) =>
      Notificacao.fromJson(jsonDecode(payload) as Map<String, dynamic>);
}
