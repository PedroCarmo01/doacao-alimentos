import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/auth/auth_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';

/// `POST /auth/login` (pública). Devolve token (RN05) e conta.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    throw const MetodoNaoPermitidoException();
  }
  final dados = DadosLogin.fromJson(await context.lerJson());
  final resposta = await context.read<AuthService>().entrar(dados);
  return Response.json(body: resposta.toJson());
}
