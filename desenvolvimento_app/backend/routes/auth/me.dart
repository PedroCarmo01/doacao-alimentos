import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/auth/auth_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/autenticacao.dart';

/// `GET /auth/me` — usado pela tela de abertura (T1) para restaurar a
/// sessão. Token vencido responde 401 `TOKEN_EXPIRADO` (RN05).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    throw const MetodoNaoPermitidoException();
  }
  final usuario = autenticar(context); // 401 se não houver token válido
  final conta = await context.read<AuthService>().contaDe(usuario);
  return Response.json(body: conta.toJson());
}
