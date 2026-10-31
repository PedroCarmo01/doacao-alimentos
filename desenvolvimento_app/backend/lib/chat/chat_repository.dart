import 'package:shared_models/shared_models.dart';

/// Quem participa de uma conversa e em que pé está a retirada.
class ConversaInfo {
  const ConversaInfo({
    required this.reservaId,
    required this.doacaoId,
    required this.ongId,
    required this.doadorId,
    required this.nomeOng,
    required this.nomeDoador,
    required this.ativa,
    this.encerradaEm,
  });

  final int reservaId;
  final int doacaoId;
  final int ongId;
  final int doadorId;
  final String nomeOng;
  final String nomeDoador;

  /// A retirada ainda está em andamento?
  final bool ativa;
  final DateTime? encerradaEm;

  /// RN30: só o doador da doação e a ONG da retirada.
  bool participa(int usuarioId) => usuarioId == ongId || usuarioId == doadorId;

  /// O id da outra pessoa da conversa.
  int outro(int usuarioId) => usuarioId == ongId ? doadorId : ongId;
}

/// CONTRATO da tabela `mensagens` (uma conversa por retirada).
abstract interface class ChatRepository {
  /// T31: as conversas do usuário (como doador ou como ONG) com retirada
  /// em andamento ou encerrada depois de [desde] (RN31).
  Future<List<ResumoConversa>> conversasDe(int usuarioId, DateTime desde);

  Future<ConversaInfo?> info(int reservaId);

  /// As mensagens com id maior que [depoisDe], da mais antiga para a mais
  /// nova.
  Future<List<Mensagem>> mensagens(int reservaId, int depoisDe);

  /// Maior id das mensagens de [autorId] que a outra pessoa já leu.
  Future<int> lidasAte(int reservaId, int autorId);

  /// [autorId] `null` = mensagem do sistema.
  Future<Mensagem> inserir(
    int reservaId, {
    required int? autorId,
    required String texto,
    required DateTime agora,
  });

  /// Marca como lidas as mensagens da OUTRA pessoa (não as do sistema).
  Future<void> marcarLidas(int reservaId, int leitorId, DateTime agora);
}
