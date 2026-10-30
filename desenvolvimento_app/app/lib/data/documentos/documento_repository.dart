import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../fake/banco_fake.dart';

/// CONTRATO: pré-consulta do CNPJ no cadastro (T4, etapa 3; RN03).
///
/// Duas implementações (polimorfismo):
/// - [DocumentoRepositoryApi]: `GET /documentos/{cnpj}?tipo=...`;
/// - [DocumentoRepositoryFake]: "Receita" de mentira do modo Fake.
abstract interface class DocumentoRepository {
  /// Devolve os dados do CNPJ ou lança `ApiException` com o código do
  /// problema (`DOCUMENTO_INVALIDO`, `CNPJ_INATIVO`, `CNPJ_NAO_E_ENTIDADE`,
  /// `CNPJ_NAO_ENCONTRADO` ou `CONSULTA_INDISPONIVEL`).
  Future<InfoCnpj> consultarCnpj(String cnpj, TipoUsuario tipo);
}

class DocumentoRepositoryApi implements DocumentoRepository {
  DocumentoRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<InfoCnpj> consultarCnpj(String cnpj, TipoUsuario tipo) async {
    // Só números: a barra do "0001/81" quebraria o caminho da URL.
    final numero = ValidadorDocumento.somenteDigitos(cnpj);
    final json = await _api.get(
      '/documentos/$numero',
      consulta: {'tipo': tipo.name},
    );
    return InfoCnpj.fromJson(ApiClient.objeto(json));
  }
}

class DocumentoRepositoryFake implements DocumentoRepository {
  DocumentoRepositoryFake(this._banco);

  final BancoFake _banco;

  @override
  Future<InfoCnpj> consultarCnpj(String cnpj, TipoUsuario tipo) async {
    await _banco.simularRede();
    return _banco.consultarCnpj(cnpj, tipo);
  }
}
