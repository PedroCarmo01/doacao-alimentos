import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:summit_app/core/api/api_client.dart';
import 'package:summit_app/core/api/api_exception.dart';
import 'package:summit_app/core/sessao/armazenamento_token.dart';

/// Testes do ApiClient usando o `MockClient` oficial do pacote http:
/// nenhuma requisição sai do computador.
void main() {
  late ArmazenamentoTokenMemoria armazenamento;

  ApiClient criarCliente(MockClientHandler responder) => ApiClient(
        urlBase: 'http://api.teste',
        armazenamentoToken: armazenamento,
        cliente: MockClient(responder),
      );

  setUp(() => armazenamento = ArmazenamentoTokenMemoria());

  test('envia o token salvo e lê JSON com acentos (UTF-8)', () async {
    await armazenamento.salvar('token-123');
    late http.Request recebida;
    final api = criarCliente((requisicao) async {
      recebida = requisicao;
      return http.Response.bytes(
        utf8.encode('{"titulo": "Doação de pães"}'),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final json = ApiClient.objeto(await api.get('/doacoes/1'));

    expect(recebida.url.toString(), 'http://api.teste/doacoes/1');
    expect(recebida.headers['Authorization'], 'Bearer token-123');
    expect(json['titulo'], 'Doação de pães');
  });

  test('converte o erro padrão da API em ApiException', () async {
    final api = criarCliente(
      (_) async => http.Response(
        jsonEncode({
          'erro': {
            'codigo': 'DOACAO_INDISPONIVEL',
            'mensagem': 'Outra ONG reservou antes.',
          },
        }),
        409,
      ),
    );

    expect(
      () => api.post('/reservas', corpo: {'doacaoId': 1}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.codigo, 'codigo', 'DOACAO_INDISPONIVEL')
            .having((e) => e.status, 'status', 409),
      ),
    );
  });

  test('falha de rede vira ApiException SEM_CONEXAO', () async {
    final api = criarCliente((_) async => throw http.ClientException('off'));

    expect(
      () => api.get('/'),
      throwsA(isA<ApiException>().having((e) => e.codigo, 'codigo', 'SEM_CONEXAO')),
    );
  });

  test('204 sem corpo devolve null', () async {
    final api = criarCliente((_) async => http.Response('', 204));

    expect(await api.delete('/doacoes/1'), isNull);
  });
}
