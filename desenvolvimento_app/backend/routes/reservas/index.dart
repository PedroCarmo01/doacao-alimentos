import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/reservas/reserva_service.dart';

/// `GET /reservas?situacao=ativas|historico` — minhas retiradas (ONG).
/// `POST /reservas` `{doacaoId}` — "Vou retirar" (RN20–RN26).
Future<Response> onRequest(RequestContext context) async {
  final usuario = context.read<UsuarioAutenticado>();
  final service = context.read<ReservaService>();
  switch (context.request.method) {
    case HttpMethod.get:
      final pedida = context.request.uri.queryParameters['situacao'];
      final situacao = pedida == SituacaoDaLista.historico.name
          ? SituacaoDaLista.historico
          : SituacaoDaLista.ativas;
      final reservas = await service.listarMinhas(usuario, situacao);
      return Response.json(
        body: {
          'reservas': [for (final reserva in reservas) reserva.toJson()],
        },
      );
    case HttpMethod.post:
      final dados = DadosReserva.fromJson(await context.lerJson());
      final reserva = await service.aceitar(usuario, dados.doacaoId);
      return Response.json(
        statusCode: HttpStatus.created,
        body: reserva.toJson(),
      );
    default:
      throw const MetodoNaoPermitidoException();
  }
}
