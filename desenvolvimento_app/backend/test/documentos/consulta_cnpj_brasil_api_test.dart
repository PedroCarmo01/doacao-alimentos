import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:summit_backend/documentos/consulta_cnpj.dart';
import 'package:summit_backend/documentos/consulta_cnpj_brasil_api.dart';
import 'package:test/test.dart';

/// Lê a resposta da BrasilAPI sem acessar a internet: o `MockClient` (do
/// próprio pacote http) devolve respostas prontas, como a BrasilAPI faria.
void main() {
  ConsultaCnpjBrasilApi consultaQueResponde(http.Response resposta) =>
      ConsultaCnpjBrasilApi(cliente: MockClient((_) async => resposta));

  test('lê razão social, situação e natureza jurídica', () async {
    final corpo = jsonEncode({
      'razao_social': 'ASSOCIAÇÃO EXEMPLO',
      'nome_fantasia': 'EXEMPLO',
      'descricao_situacao_cadastral': 'ATIVA',
      'natureza_juridica': 'Associação Privada',
      'codigo_natureza_juridica': 3999,
    });
    final consulta = consultaQueResponde(
      http.Response.bytes(utf8.encode(corpo), 200),
    );

    final resultado = await consulta.consultar('11222333000181');

    expect(resultado.situacao, SituacaoDaConsulta.encontrado);
    expect(resultado.info!.razaoSocial, 'ASSOCIAÇÃO EXEMPLO');
    expect(resultado.info!.semFinsLucrativos, isTrue);
  });

  test('código da natureza jurídica em texto também funciona', () async {
    final consulta = consultaQueResponde(
      http.Response(
        jsonEncode({
          'razao_social': 'X',
          'descricao_situacao_cadastral': 'ATIVA',
          'codigo_natureza_juridica': '2062',
        }),
        200,
      ),
    );

    final resultado = await consulta.consultar('11222333000181');

    expect(resultado.info!.codigoNaturezaJuridica, 2062);
  });

  test('404 da BrasilAPI = CNPJ não encontrado', () async {
    final consulta = consultaQueResponde(http.Response('{}', 404));

    final resultado = await consulta.consultar('11222333000181');

    expect(resultado.situacao, SituacaoDaConsulta.naoEncontrado);
  });

  test('RN03: erro 500 ou resposta estranha = indisponível', () async {
    final erro500 = consultaQueResponde(http.Response('falhou', 500));
    final semJson = consultaQueResponde(http.Response('<html>', 200));

    expect(
      (await erro500.consultar('1')).situacao,
      SituacaoDaConsulta.indisponivel,
    );
    expect(
      (await semJson.consultar('1')).situacao,
      SituacaoDaConsulta.indisponivel,
    );
  });

  test('RN03: sem internet = indisponível (não lança exceção)', () async {
    final consulta = ConsultaCnpjBrasilApi(
      cliente: MockClient((_) async => throw http.ClientException('offline')),
    );

    final resultado = await consulta.consultar('11222333000181');

    expect(resultado.situacao, SituacaoDaConsulta.indisponivel);
  });

  test('RN03: demorar mais de 5 s = indisponível', () async {
    final consulta = ConsultaCnpjBrasilApi(
      cliente: MockClient((_) => Completer<http.Response>().future),
    );

    // Este teste espera os 5 s de verdade (a BrasilAPI "nunca responde").
    // O timeout de 6 s é só uma proteção para o teste não ficar travado.
    final resultado = await consulta
        .consultar('11222333000181')
        .timeout(const Duration(seconds: 6));

    expect(resultado.situacao, SituacaoDaConsulta.indisponivel);
  });
}
