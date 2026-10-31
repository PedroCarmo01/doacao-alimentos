import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/chat/chat_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';

/// `GET /conversas/{reservaId}/mensagens?depois={id}` — as novas (o app
/// consulta a cada 4 s com a conversa aberta).
/// `POST /conversas/{reservaId}/mensagens` `{"texto": "..."}` — envia.
Future<Response> onRequest(RequestContext context, String reservaId) async {
  final id = idDaRota(reservaId);
  final usuario = context.read<UsuarioAutenticado>();
  final service = context.read<ChatService>();
  switch (context.request.method) {
    case HttpMethod.get:
      final texto = context.request.uri.queryParameters['depois'] ?? '0';
      final depois = int.tryParse(texto);
      if (depois == null || depois < 0) {
        throw const ValidacaoException(
          'O parâmetro "depois" deve ser um número.',
        );
      }
      final resposta = await service.mensagens(usuario, id, depois);
      return Response.json(body: resposta.toJson());
    case HttpMethod.post:
      final texto = (await context.lerJson())['texto'];
      if (texto is! String) {
        throw const ValidacaoException('Envie {"texto": "..."}.');
      }
      final mensagem = await service.enviar(usuario, id, texto);
      return Response.json(
        statusCode: HttpStatus.created,
        body: mensagem.toJson(),
      );
    default:
      throw const MetodoNaoPermitidoException();
  }
}
