import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/reservas/reserva_service.dart';

/// `GET /reservas/situacao-da-ong` — desistências recentes, suspensão,
/// retiradas em andamento e os números das regras (para os avisos do app).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    throw const MetodoNaoPermitidoException();
  }
  final situacao = await context.read<ReservaService>().situacao(
    context.read<UsuarioAutenticado>(),
  );
  return Response.json(body: situacao.toJson());
}
