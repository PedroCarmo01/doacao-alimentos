import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/chat/chat_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';

/// `GET /conversas` — a aba Mensagens (T31): uma conversa por retirada,
/// com a última mensagem e as não lidas.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    throw const MetodoNaoPermitidoException();
  }
  final conversas = await context.read<ChatService>().conversas(
    context.read<UsuarioAutenticado>(),
  );
  return Response.json(
    body: {
      'conversas': [for (final c in conversas) c.toJson()],
    },
  );
}
