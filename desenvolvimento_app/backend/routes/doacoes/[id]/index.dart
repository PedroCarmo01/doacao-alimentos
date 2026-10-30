import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/doacoes/doacao_service.dart';

/// `GET /doacoes/{id}` — detalhe (T12 para o doador, T22 para a ONG).
/// `PUT /doacoes/{id}` — editar enquanto disponível (RN12).
/// `DELETE /doacoes/{id}` — cancelar; corpo `{"motivo": "..."}` se
/// reservada (RN12). Responde 204.
Future<Response> onRequest(RequestContext context, String id) async {
  final doacaoId = idDaRota(id);
  final usuario = context.read<UsuarioAutenticado>();
  final service = context.read<DoacaoService>();
  switch (context.request.method) {
    case HttpMethod.get:
      final detalhe = await service.detalhar(usuario, doacaoId);
      return Response.json(body: detalhe.toJson());
    case HttpMethod.put:
      final dados = DadosNovaDoacao.fromJson(await context.lerJson());
      final doacao = await service.editar(usuario, doacaoId, dados);
      return Response.json(body: doacao.toJson());
    case HttpMethod.delete:
      // O corpo é opcional: sem corpo = cancelar sem motivo.
      final texto = await context.request.body();
      var dados = const DadosCancelamento();
      if (texto.trim().isNotEmpty) {
        final json = jsonDecode(texto); // JSON malformado → 400 (middleware)
        if (json is! Map<String, dynamic>) {
          throw const ValidacaoException('Envie {"motivo": "..."}.');
        }
        dados = DadosCancelamento.fromJson(json);
      }
      await service.cancelar(usuario, doacaoId, motivo: dados.motivo);
      return Response(statusCode: HttpStatus.noContent);
    default:
      throw const MetodoNaoPermitidoException();
  }
}
