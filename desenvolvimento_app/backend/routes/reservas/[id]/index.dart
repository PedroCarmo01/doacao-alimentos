import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/reservas/reserva_service.dart';

/// `GET /reservas/{id}` — a retirada em andamento (T23), só a ONG dona.
/// `DELETE /reservas/{id}` — a ONG desiste (RN22–RN24). Responde se
/// contou como desistência.
Future<Response> onRequest(RequestContext context, String id) async {
  final reservaId = idDaRota(id);
  final usuario = context.read<UsuarioAutenticado>();
  final service = context.read<ReservaService>();
  switch (context.request.method) {
    case HttpMethod.get:
      final reserva = await service.buscar(usuario, reservaId);
      return Response.json(body: reserva.toJson());
    case HttpMethod.delete:
      final resposta = await service.desistir(usuario, reservaId);
      return Response.json(body: resposta.toJson());
    default:
      throw const MetodoNaoPermitidoException();
  }
}
