import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/auth/auth_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';

/// `POST /auth/cadastro` (pública) — RN01 a RN04. Devolve token e conta.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    throw const MetodoNaoPermitidoException();
  }
  final dados = DadosCadastro.fromJson(await context.lerJson());
  final resposta = await context.read<AuthService>().cadastrar(dados);
  return Response.json(statusCode: HttpStatus.created, body: resposta.toJson());
}
