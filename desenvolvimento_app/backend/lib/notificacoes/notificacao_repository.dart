import 'package:shared_models/shared_models.dart';

/// Uma notificação a gravar (o id e a data o repositório completa).
class NovaNotificacao {
  const NovaNotificacao({
    required this.usuarioId,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    required this.criadoEm,
    this.doacaoId,
    this.reservaId,
  });

  final int usuarioId;
  final TipoNotificacao tipo;
  final String titulo;
  final String corpo;
  final DateTime criadoEm;
  final int? doacaoId;
  final int? reservaId;
}

/// Uma ONG que PODE ser avisada de uma doação (RN11): o ponto e o raio
/// dela. A distância a central confere.
class OngParaAviso {
  const OngParaAviso({
    required this.usuarioId,
    required this.coordenadas,
    required this.raioKm,
  });

  final int usuarioId;
  final Coordenadas coordenadas;
  final double raioKm;
}

/// CONTRATO da tabela `notificacoes` (e da escolha de quem avisar).
abstract interface class NotificacaoRepository {
  Future<Notificacao> criar(NovaNotificacao nova);

  /// As do usuário com id maior que [depoisDe], da mais antiga para a mais
  /// nova (no máximo [limite]).
  Future<List<Notificacao>> depoisDe(
    int usuarioId,
    int depoisDe, {
    required int limite,
  });

  /// Marca como lidas as do usuário até o id [ate] (inclusive).
  Future<void> marcarLidas(int usuarioId, int ate);

  /// Já existe um aviso deste [tipo] para a retirada? (evita repetir o
  /// "faltam 10 minutos" a cada rodada do job)
  Future<bool> existe(TipoNotificacao tipo, int reservaId);

  /// T50: quais avisos o usuário quer receber.
  Future<PreferenciasDeAviso> preferencias(int usuarioId);

  /// RN11: ONGs com a busca ativa (e o aviso de doações ligado), não
  /// suspensas em [agora] e não bloqueadas para a doação [doacaoId].
  Future<List<OngParaAviso>> ongsParaAvisar(int doacaoId, DateTime agora);
}
