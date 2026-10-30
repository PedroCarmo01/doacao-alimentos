import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/db/database.dart';

/// `GET /` — "health check" (verificação de saúde).
///
/// Confirma que a API está no ar e se o banco responde. É a prova do Sprint 0
/// de que backend e banco estão ligados de ponta a ponta. O app chama esta
/// rota na tela inicial para mostrar "Servidor online".
Future<Response> onRequest(RequestContext context) async {
  final bancoOk = await context.read<Database>().ping();
  return Response.json(
    statusCode: bancoOk ? HttpStatus.ok : HttpStatus.serviceUnavailable,
    body: {
      'servico': 'api-doacao-alimentos',
      'status': bancoOk ? 'ok' : 'degradado',
      'banco': bancoOk ? 'conectado' : 'indisponivel',
      'horario': context.read<Relogio>().agora().toIso8601String(),
    },
  );
}
