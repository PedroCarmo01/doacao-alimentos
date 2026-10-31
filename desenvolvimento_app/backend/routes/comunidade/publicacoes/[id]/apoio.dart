import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/comunidade/comunidade_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';

/// `POST /comunidade/publicacoes/{id}/apoio` — apoiar (RN41).
/// `DELETE /comunidade/publicacoes/{id}/apoio` — desfazer.
/// Os dois devolvem a publicação com o número de apoios atualizado.
Future<Response> onRequest(RequestContext context, String id) async {
  final usuario = context.read<UsuarioAutenticado>();
  final service = context.read<ComunidadeService>();
  final publicacaoId = idDaRota(id);
  final publicacao = switch (context.request.method) {
    HttpMethod.post => await service.apoiar(usuario, publicacaoId),
    HttpMethod.delete => await service.desfazerApoio(usuario, publicacaoId),
    _ => throw const MetodoNaoPermitidoException(),
  };
  return Response.json(body: publicacao.toJson());
}
