import 'package:shared_models/shared_models.dart';

import '../routing/app_routes.dart';

/// Para onde o toque numa notificação leva (seção 9: "tocar na notificação
/// abre a tela certa").
class DestinoDaNotificacao {
  const DestinoDaNotificacao(this.rota, [this.argumento]);

  final String rota;
  final Object? argumento;

  /// `null` = só abre o app (faltou o id da doação ou da retirada).
  static DestinoDaNotificacao? para(
    Notificacao notificacao, {
    required bool ehOng,
  }) {
    final doacao = notificacao.doacaoId;
    final reserva = notificacao.reservaId;
    return switch (notificacao.tipo) {
      // ONG: uma doação para aceitar.
      TipoNotificacao.doacaoNova || TipoNotificacao.doacaoDisponivelDeNovo =>
        doacao == null
            ? null
            : DestinoDaNotificacao(AppRoutes.detalheDoacaoOng, doacao),
      // ONG: a retirada em andamento (ou já confirmada).
      TipoNotificacao.prazoAcabando => _retirada(reserva),
      TipoNotificacao.retiradaConfirmada when ehOng => _retirada(reserva),
      // ONG: o histórico explica o que aconteceu.
      TipoNotificacao.prazoAcabouOng ||
      TipoNotificacao.doacaoCancelada ||
      TipoNotificacao.suspensao => const DestinoDaNotificacao(
        AppRoutes.minhasReservas,
      ),
      // Doador: o detalhe da doação.
      TipoNotificacao.doacaoAceita ||
      TipoNotificacao.prazoAcabouDoador ||
      TipoNotificacao.retiradaConfirmada =>
        doacao == null
            ? null
            : DestinoDaNotificacao(AppRoutes.detalheDoacaoDoador, doacao),
      // Os dois: a conversa da retirada (T30).
      TipoNotificacao.mensagemNova =>
        reserva == null ? null : DestinoDaNotificacao(AppRoutes.chat, reserva),
    };
  }

  static DestinoDaNotificacao? _retirada(int? reservaId) => reservaId == null
      ? null
      : DestinoDaNotificacao(AppRoutes.retirada, reservaId);
}
