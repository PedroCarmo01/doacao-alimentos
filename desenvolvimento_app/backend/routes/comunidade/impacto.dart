import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/comunidade/comunidade_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';

/// `GET /comunidade/impacto` — o painel de impacto de todos (T40).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    throw const MetodoNaoPermitidoException();
  }
  final impacto = await context.read<ComunidadeService>().impacto();
  return Response.json(body: impacto.toJson());
}
