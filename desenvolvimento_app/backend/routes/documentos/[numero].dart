import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/documentos/documento_service.dart';

/// `GET /documentos/{numero}?tipo=ong|doador` (pública) — pré-consulta do
/// CNPJ para o app preencher o nome da organização no cadastro (RN03).
///
/// Erros: `DOCUMENTO_INVALIDO`, `CNPJ_NAO_ENCONTRADO`, `CNPJ_INATIVO`,
/// `CNPJ_NAO_E_ENTIDADE` (só com `tipo=ong`) e `CONSULTA_INDISPONIVEL`.
Future<Response> onRequest(RequestContext context, String numero) async {
  if (context.request.method != HttpMethod.get) {
    throw const MetodoNaoPermitidoException();
  }
  final tipoInformado = context.request.uri.queryParameters['tipo'];
  final tipo = TipoUsuario.values
      .where((opcao) => opcao.name == tipoInformado)
      .firstOrNull;
  final info = await context.read<DocumentoService>().preConsultar(
    numero,
    tipo: tipo,
  );
  return Response.json(body: info.toJson());
}
