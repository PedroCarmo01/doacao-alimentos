import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/chat/chat_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';

/// `POST /conversas/{reservaId}/lidas` — marca como lidas as mensagens da
/// outra pessoa ("✓ lida" do lado dela). Responde 204.
Future<Response> onRequest(RequestContext context, String reservaId) async {
  if (context.request.method != HttpMethod.post) {
    throw const MetodoNaoPermitidoException();
  }
  await context.read<ChatService>().marcarLidas(
    context.read<UsuarioAutenticado>(),
    idDaRota(reservaId),
  );
  return Response(statusCode: HttpStatus.noContent);
}
