import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import 'consulta_cnpj.dart';

/// Consulta o CNPJ na BrasilAPI (gratuita, sem chave de acesso).
///
/// `GET https://brasilapi.com.br/api/cnpj/v1/{cnpj}`. Os campos que usamos
/// da resposta: `razao_social`, `nome_fantasia`,
/// `descricao_situacao_cadastral`, `natureza_juridica` e
/// `codigo_natureza_juridica`.
class ConsultaCnpjBrasilApi implements ConsultaCnpj {
  ConsultaCnpjBrasilApi({http.Client? cliente})
    : _cliente = cliente ?? http.Client();

  static const _endereco = 'https://brasilapi.com.br/api/cnpj/v1/';

  /// RN03: se a BrasilAPI demorar mais do que isso, o cadastro segue com
  /// "verificação pendente".
  static const tempoLimite = Duration(seconds: 5);

  final http.Client _cliente;

  @override
  Future<ResultadoConsultaCnpj> consultar(String cnpj) async {
    final http.Response resposta;
    try {
      resposta = await _cliente
          .get(Uri.parse('$_endereco$cnpj'))
          .timeout(tempoLimite);
    } on TimeoutException {
      return const ResultadoConsultaCnpj.indisponivel();
    } on http.ClientException {
      return const ResultadoConsultaCnpj.indisponivel();
    } on SocketException {
      return const ResultadoConsultaCnpj.indisponivel();
    }

    if (resposta.statusCode == HttpStatus.notFound) {
      return const ResultadoConsultaCnpj.naoEncontrado();
    }
    if (resposta.statusCode != HttpStatus.ok) {
      // 429 (muitas consultas), 500, 502...: problema do lado de lá.
      return const ResultadoConsultaCnpj.indisponivel();
    }
    return _ler(cnpj, resposta);
  }

  /// Converte o JSON da BrasilAPI (snake_case) no nosso [InfoCnpj].
  ResultadoConsultaCnpj _ler(String cnpj, http.Response resposta) {
    try {
      final json = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return const ResultadoConsultaCnpj.indisponivel();
      }
      final codigo = json['codigo_natureza_juridica'];
      return ResultadoConsultaCnpj.encontrado(
        InfoCnpj(
          cnpj: cnpj,
          razaoSocial: '${json['razao_social'] ?? ''}',
          nomeFantasia: json['nome_fantasia'] as String?,
          situacao: '${json['descricao_situacao_cadastral'] ?? ''}',
          naturezaJuridica: json['natureza_juridica'] as String?,
          // Às vezes vem como número (3999), às vezes como texto ("3999").
          codigoNaturezaJuridica: codigo is int
              ? codigo
              : int.tryParse('${codigo ?? ''}'),
        ),
      );
    } on FormatException {
      return const ResultadoConsultaCnpj.indisponivel();
    } on TypeError {
      // Um campo veio com o tipo inesperado: tratamos como "não deu".
      return const ResultadoConsultaCnpj.indisponivel();
    }
  }
}
