import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/perfil/perfil_service.dart';

/// `GET /perfil/estatisticas` — os números do Perfil (T50).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    throw const MetodoNaoPermitidoException();
  }
  final estatisticas = await context.read<PerfilService>().estatisticas(
    context.read<UsuarioAutenticado>(),
  );
  return Response.json(body: estatisticas.toJson());
}
