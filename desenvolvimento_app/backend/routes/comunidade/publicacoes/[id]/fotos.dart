import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/comunidade/comunidade_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';

/// `POST /comunidade/publicacoes/{id}/fotos` — *multipart*, UMA foto no
/// campo `foto` (até 3 por publicação, só o autor).
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    throw const MetodoNaoPermitidoException();
  }
  final bytes = await context.lerFoto();
  final publicacao = await context.read<ComunidadeService>().adicionarFoto(
    context.read<UsuarioAutenticado>(),
    idDaRota(id),
    bytes,
  );
  return Response.json(
    statusCode: HttpStatus.created,
    body: publicacao.toJson(),
  );
}
