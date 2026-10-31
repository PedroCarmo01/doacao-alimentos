import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/doacoes/foto_doacao_service.dart';

/// `POST /doacoes/{id}/fotos` — envio *multipart* de UMA foto, no campo
/// `foto`. Responde 201 com a doação atualizada (com a lista de fotos).
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    throw const MetodoNaoPermitidoException();
  }
  final bytes = await context.lerFoto();
  final doacao = await context.read<FotoDoacaoService>().adicionar(
    context.read<UsuarioAutenticado>(),
    idDaRota(id),
    bytes,
  );
  return Response.json(statusCode: HttpStatus.created, body: doacao.toJson());
}
