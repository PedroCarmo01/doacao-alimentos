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
  final List<int> bytes;
  try {
    final formulario = await context.request.formData();
    final arquivo = formulario.files['foto'];
    if (arquivo == null) {
      throw const ValidacaoException(
        'Envie a foto no campo "foto" (multipart/form-data).',
      );
    }
    bytes = await arquivo.readAsBytes();
  } on StateError {
    // O corpo não era multipart/form-data.
    throw const ValidacaoException(
      'Envie a foto como multipart/form-data, no campo "foto".',
    );
  }
  final doacao = await context.read<FotoDoacaoService>().adicionar(
    context.read<UsuarioAutenticado>(),
    idDaRota(id),
    bytes,
  );
  return Response.json(statusCode: HttpStatus.created, body: doacao.toJson());
}
