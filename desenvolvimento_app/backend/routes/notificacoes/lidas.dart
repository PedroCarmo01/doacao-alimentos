import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/notificacoes/notificacao_service.dart';

/// `POST /notificacoes/lidas` `{"ate": 42}` — marca como lidas as do
/// usuário até o id 42. Responde 204.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    throw const MetodoNaoPermitidoException();
  }
  final ate = (await context.lerJson())['ate'];
  if (ate is! int) {
    throw const ValidacaoException('Envie {"ate": <id da notificação>}.');
  }
  await context.read<NotificacaoService>().marcarLidas(
    context.read<UsuarioAutenticado>(),
    ate,
  );
  return Response(statusCode: HttpStatus.noContent);
}
