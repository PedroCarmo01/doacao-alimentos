import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/dispositivos/dispositivo_service.dart';

/// `POST /dispositivos` `{token, plataforma}` — guarda o identificador do
/// celular para o push real (etapa futura). Responde 204, sem corpo.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    throw const MetodoNaoPermitidoException();
  }
  final dados = DadosDispositivo.fromJson(await context.lerJson());
  await context.read<DispositivoService>().registrar(
    context.read<UsuarioAutenticado>(),
    dados,
  );
  return Response(statusCode: HttpStatus.noContent);
}
