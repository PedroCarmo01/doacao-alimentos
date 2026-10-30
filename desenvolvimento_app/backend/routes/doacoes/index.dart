import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/doacoes/doacao_service.dart';

/// `GET /doacoes?situacao=ativas|historico` — minhas doações (T10).
/// `POST /doacoes` — publicar (RN10). Resposta: `{doacao, ongsAvisadas}`.
Future<Response> onRequest(RequestContext context) async {
  final usuario = context.read<UsuarioAutenticado>();
  final service = context.read<DoacaoService>();
  switch (context.request.method) {
    case HttpMethod.get:
      final pedida = context.request.uri.queryParameters['situacao'];
      final situacao = pedida == SituacaoDaLista.historico.name
          ? SituacaoDaLista.historico
          : SituacaoDaLista.ativas;
      final doacoes = await service.listarMinhas(usuario, situacao);
      return Response.json(
        body: {
          'doacoes': [for (final doacao in doacoes) doacao.toJson()],
        },
      );
    case HttpMethod.post:
      final dados = DadosNovaDoacao.fromJson(await context.lerJson());
      final resposta = await service.publicar(usuario, dados);
      return Response.json(
        statusCode: HttpStatus.created,
        body: resposta.toJson(),
      );
    default:
      throw const MetodoNaoPermitidoException();
  }
}
