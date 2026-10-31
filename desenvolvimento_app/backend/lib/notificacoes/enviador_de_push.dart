import 'package:shared_models/shared_models.dart';

/// Como a notificação CHEGA ao celular (seção 9 da especificação).
///
/// POLIMORFISMO: hoje usamos o [EnviadorPushDesligado] (o app consulta o
/// servidor a cada 15 s). Para o push real, basta criar um `EnviadorFcm`
/// (Firebase) que implemente esta interface e trocar UMA linha no
/// `main.dart`. A `CentralDeNotificacoes` e os Services não mudam.
abstract interface class EnviadorDePush {
  Future<void> enviar(int usuarioId, Notificacao notificacao);
}

/// Não envia nada: a notificação fica gravada na tabela e o app busca.
class EnviadorPushDesligado implements EnviadorDePush {
  const EnviadorPushDesligado();

  @override
  Future<void> enviar(int usuarioId, Notificacao notificacao) async {}
}
