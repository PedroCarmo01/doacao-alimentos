import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/comunidade/comunidade_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';

/// `GET /comunidade/publicacoes?antesDe={id}` — feed, 20 por vez (T40).
/// `POST /comunidade/publicacoes` — nova publicação (RN40, T41).
Future<Response> onRequest(RequestContext context) async {
  final usuario = context.read<UsuarioAutenticado>();
  final service = context.read<ComunidadeService>();
  switch (context.request.method) {
    case HttpMethod.get:
      final texto = context.request.uri.queryParameters['antesDe'] ?? '0';
      final antesDe = int.tryParse(texto);
      if (antesDe == null || antesDe < 0) {
        throw const ValidacaoException(
          'O parâmetro "antesDe" deve ser um número.',
        );
      }
      final publicacoes = await service.feed(usuario, antesDe);
      return Response.json(
        body: {
          'publicacoes': [for (final p in publicacoes) p.toJson()],
        },
      );
    case HttpMethod.post:
      final dados = DadosPublicacao.fromJson(await context.lerJson());
      final publicacao = await service.publicar(usuario, dados);
      return Response.json(
        statusCode: HttpStatus.created,
        body: publicacao.toJson(),
      );
    default:
      throw const MetodoNaoPermitidoException();
  }
}
