import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/notificacoes/notificacao_service.dart';

/// `GET /notificacoes?depois={id}` — os avisos com id maior que `depois`,
/// do mais antigo para o mais novo. O app consulta a cada 15 s.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    throw const MetodoNaoPermitidoException();
  }
  final texto = context.request.uri.queryParameters['depois'] ?? '0';
  final depois = int.tryParse(texto);
  if (depois == null || depois < 0) {
    throw const ValidacaoException('O parâmetro "depois" deve ser um número.');
  }
  final novas = await context.read<NotificacaoService>().novas(
    context.read<UsuarioAutenticado>(),
    depois,
  );
  return Response.json(
    body: {
      'notificacoes': [for (final n in novas) n.toJson()],
    },
  );
}
