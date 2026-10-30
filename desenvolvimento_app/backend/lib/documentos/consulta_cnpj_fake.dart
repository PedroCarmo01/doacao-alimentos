import 'package:shared_models/shared_models.dart';

import 'consulta_cnpj.dart';

/// Consulta de CNPJ sem internet.
///
/// - Nos testes: recebe uma lista de CNPJs "cadastrados na Receita" para
///   simular cada caso da RN03 (ativo, inativo, empresa, não encontrado).
/// - No servidor com `CONSULTAR_BRASILAPI=false`: a lista fica vazia e
///   qualquer CNPJ volta como "indisponível", ou seja, a conta é criada com
///   "verificação pendente" (como diz o 03-DADOS-E-API.md).
class ConsultaCnpjFake implements ConsultaCnpj {
  ConsultaCnpjFake({
    List<InfoCnpj> cadastrados = const [],
    this.naoEncontrados = const {},
  }) : _cadastrados = {for (final info in cadastrados) info.cnpj: info};

  final Map<String, InfoCnpj> _cadastrados;

  /// CNPJs que a "Receita" diz que não existem.
  final Set<String> naoEncontrados;

  /// Quantas consultas foram feitas (os testes conferem isso).
  int consultasFeitas = 0;

  @override
  Future<ResultadoConsultaCnpj> consultar(String cnpj) async {
    consultasFeitas++;
    final info = _cadastrados[cnpj];
    if (info != null) return ResultadoConsultaCnpj.encontrado(info);
    if (naoEncontrados.contains(cnpj)) {
      return const ResultadoConsultaCnpj.naoEncontrado();
    }
    return const ResultadoConsultaCnpj.indisponivel();
  }
}
