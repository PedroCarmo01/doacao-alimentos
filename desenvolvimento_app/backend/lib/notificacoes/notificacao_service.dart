import 'package:shared_models/shared_models.dart';

import '../core/seguranca/usuario_autenticado.dart';
import 'notificacao_repository.dart';

/// O app busca os avisos novos e marca como lidos (`/notificacoes`).
///
/// Cada pessoa só vê as próprias: o id do usuário vem do TOKEN, nunca da
/// URL.
class NotificacaoService {
  NotificacaoService(this._notificacoes);

  final NotificacaoRepository _notificacoes;

  /// No máximo isto por consulta (se o app ficou dias fechado, não manda
  /// centenas de uma vez).
  static const limite = 50;

  /// `GET /notificacoes?depois={id}`
  Future<List<Notificacao>> novas(UsuarioAutenticado usuario, int depoisDe) =>
      _notificacoes.depoisDe(usuario.id, depoisDe, limite: limite);

  /// `POST /notificacoes/lidas {ate}`
  Future<void> marcarLidas(UsuarioAutenticado usuario, int ate) =>
      _notificacoes.marcarLidas(usuario.id, ate);
}
