import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/reservas/confirmacao_service.dart';

/// `POST /reservas/{id}/nao-compareceu` — depois do prazo, o doador marca
/// que a ONG não veio (RN28). Responde 204.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    throw const MetodoNaoPermitidoException();
  }
  await context.read<ConfirmacaoService>().naoCompareceu(
    context.read<UsuarioAutenticado>(),
    idDaRota(id),
  );
  return Response(statusCode: HttpStatus.noContent);
}
