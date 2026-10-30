import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../sessao/armazenamento_token.dart';
import 'api_exception.dart';

/// Único ponto do app que faz requisições HTTP.
///
/// ENCAPSULAMENTO: endereço da API, token, cabeçalhos, tempo limite,
/// conversão de JSON e tradução de erros ficam escondidos aqui dentro.
/// Os repositórios só chamam `get`, `post` e `delete`.
class ApiClient {
  ApiClient({
    required String urlBase,
    required ArmazenamentoToken armazenamentoToken,
    http.Client? cliente,
    this.tempoLimite = const Duration(seconds: 15),
  }) : _urlBase = urlBase.endsWith('/')
           ? urlBase.substring(0, urlBase.length - 1)
           : urlBase,
       _armazenamentoToken = armazenamentoToken,
       _cliente = cliente ?? http.Client();

  final String _urlBase;
  final ArmazenamentoToken _armazenamentoToken;
  final http.Client _cliente;
  final Duration tempoLimite;

  Future<Object?> get(String caminho, {Map<String, String>? consulta}) =>
      _enviar('GET', caminho, consulta: consulta);

  Future<Object?> post(String caminho, {Object? corpo}) =>
      _enviar('POST', caminho, corpo: corpo);

  Future<Object?> put(String caminho, {Object? corpo}) =>
      _enviar('PUT', caminho, corpo: corpo);

  /// O [corpo] é opcional (ex.: o motivo ao cancelar uma doação).
  Future<Object?> delete(String caminho, {Object? corpo}) =>
      _enviar('DELETE', caminho, corpo: corpo);

  /// Envia um arquivo (foto) como `multipart/form-data`, no [campo] dado.
  Future<Object?> enviarArquivo(
    String caminho, {
    required String campo,
    required List<int> bytes,
    required String nomeArquivo,
  }) async {
    final requisicao = http.MultipartRequest('POST', _uri(caminho, null))
      ..files.add(
        http.MultipartFile.fromBytes(campo, bytes, filename: nomeArquivo),
      );
    return _mandar(requisicao);
  }

  /// Garante que a resposta é um objeto JSON (`{...}`).
  static Map<String, dynamic> objeto(Object? json) {
    if (json is Map<String, dynamic>) return json;
    throw const ApiException.respostaInvalida();
  }

  /// Lê uma lista de objetos dentro de [chave]: `{"doacoes": [ {...}, ... ]}`.
  static List<Map<String, dynamic>> lista(Object? json, String chave) {
    final itens = objeto(json)[chave];
    if (itens is List) {
      return [
        for (final item in itens)
          if (item is Map<String, dynamic>)
            item
          else
            throw const ApiException.respostaInvalida(),
      ];
    }
    throw const ApiException.respostaInvalida();
  }

  Uri _uri(String caminho, Map<String, String>? consulta) =>
      Uri.parse('$_urlBase$caminho').replace(
        queryParameters: (consulta == null || consulta.isEmpty)
            ? null
            : consulta,
      );

  Future<Object?> _enviar(
    String metodo,
    String caminho, {
    Object? corpo,
    Map<String, String>? consulta,
  }) {
    final requisicao = http.Request(metodo, _uri(caminho, consulta));
    if (corpo != null) {
      requisicao.headers['Content-Type'] = 'application/json; charset=utf-8';
      requisicao.body = jsonEncode(corpo);
    }
    return _mandar(requisicao);
  }

  /// Põe o token e os cabeçalhos, envia e interpreta a resposta.
  Future<Object?> _mandar(http.BaseRequest requisicao) async {
    requisicao.headers['Accept'] = 'application/json';
    final token = await _armazenamentoToken.ler();
    if (token != null) requisicao.headers['Authorization'] = 'Bearer $token';

    final http.Response resposta;
    try {
      final enviada = await _cliente.send(requisicao).timeout(tempoLimite);
      resposta = await http.Response.fromStream(enviada).timeout(tempoLimite);
    } on TimeoutException {
      throw const ApiException.tempoEsgotado();
    } on http.ClientException {
      throw const ApiException.semConexao();
    }
    return _interpretar(resposta);
  }

  Object? _interpretar(http.Response resposta) {
    final sucesso = resposta.statusCode >= 200 && resposta.statusCode < 300;

    // Decodifica SEMPRE como UTF-8: sem isso, "Doação" vira "DoaÃ§Ã£o"
    // (achado A26 da análise técnica).
    final texto = utf8.decode(resposta.bodyBytes, allowMalformed: true);
    Object? json;
    if (texto.trim().isNotEmpty) {
      try {
        json = jsonDecode(texto);
      } on FormatException {
        if (sucesso) throw const ApiException.respostaInvalida();
      }
    }
    if (sucesso) return json;

    if (json is Map && json['erro'] is Map) {
      final erro = json['erro'] as Map;
      final detalhes = erro['detalhes'];
      throw ApiException(
        codigo: '${erro['codigo'] ?? 'ERRO'}',
        mensagem: '${erro['mensagem'] ?? 'Erro inesperado.'}',
        status: resposta.statusCode,
        detalhes: detalhes is List
            ? [for (final d in detalhes) '$d']
            : const [],
      );
    }
    throw ApiException(
      codigo: 'HTTP_${resposta.statusCode}',
      mensagem: _mensagemPadrao(resposta.statusCode),
      status: resposta.statusCode,
    );
  }

  static String _mensagemPadrao(int status) => switch (status) {
    401 => 'Faça login novamente.',
    404 => 'Rota não encontrada no servidor (ela já foi implementada?).',
    >= 500 => 'Erro no servidor. Tente novamente em instantes.',
    _ => 'Erro inesperado (HTTP $status).',
  };
}
