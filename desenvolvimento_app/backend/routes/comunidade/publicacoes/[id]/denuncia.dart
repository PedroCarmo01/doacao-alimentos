import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/comunidade/comunidade_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';

/// `POST /comunidade/publicacoes/{id}/denuncia` `{"motivo": "improprio"}`
/// — RN42. Responde 204.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    throw const MetodoNaoPermitidoException();
  }
  final texto = (await context.lerJson())['motivo'];
  final motivo = MotivoDenuncia.values
      .where((m) => m.name == texto)
      .firstOrNull;
  if (motivo == null) {
    throw const ValidacaoException(
      'Envie {"motivo": "improprio" | "falso" | "outro"}.',
    );
  }
  await context.read<ComunidadeService>().denunciar(
    context.read<UsuarioAutenticado>(),
    idDaRota(id),
    motivo,
  );
  return Response(statusCode: HttpStatus.noContent);
}
