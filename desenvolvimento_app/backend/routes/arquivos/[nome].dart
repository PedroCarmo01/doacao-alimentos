import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/arquivos/armazenamento_de_fotos.dart';
import 'package:summit_backend/core/erros/app_exception.dart';

/// `GET /arquivos/{nome}` (pública) — devolve uma foto.
///
/// Pública porque o `Image.network` do Flutter não manda o token. Não há
/// risco: o nome é aleatório (32 caracteres) e só nomes nesse formato são
/// aceitos (ver `ArmazenamentoEmPasta.formatoDoNome`).
Future<Response> onRequest(RequestContext context, String nome) async {
  if (context.request.method != HttpMethod.get) {
    throw const MetodoNaoPermitidoException();
  }
  final bytes = await context.read<ArmazenamentoDeFotos>().ler(nome);
  final formato = FormatoDeFoto.doNome(nome);
  if (bytes == null || formato == null) {
    throw const NaoEncontradoException('Foto não encontrada.');
  }
  return Response.bytes(
    body: bytes,
    headers: {
      HttpHeaders.contentTypeHeader: formato.tipoMime,
      // A foto nunca muda (cada uma tem nome novo): o celular pode guardar.
      HttpHeaders.cacheControlHeader: 'public, max-age=604800, immutable',
    },
  );
}
