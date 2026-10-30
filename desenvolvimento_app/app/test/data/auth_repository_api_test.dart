import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:summit_app/core/api/api_client.dart';
import 'package:summit_app/core/api/api_exception.dart';
import 'package:summit_app/core/sessao/armazenamento_token.dart';
import 'package:summit_app/data/auth/auth_repository.dart';

/// RN05: o que a abertura recebe quando o token salvo não serve mais.
void main() {
  late ArmazenamentoTokenMemoria armazenamento;

  AuthRepositoryApi repositorioQueResponde(int status, String codigo) {
    final api = ApiClient(
      urlBase: 'http://api.teste',
      armazenamentoToken: armazenamento,
      cliente: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'erro': {'codigo': codigo, 'mensagem': 'x'},
          }),
          status,
        ),
      ),
    );
    return AuthRepositoryApi(api, armazenamento);
  }

  setUp(() async {
    armazenamento = ArmazenamentoTokenMemoria();
    await armazenamento.salvar('token-antigo');
  });

  test(
    'RN05: token vencido apaga o token e avisa com TOKEN_EXPIRADO',
    () async {
      final repositorio = repositorioQueResponde(401, codigoTokenExpirado);

      await expectLater(
        repositorio.contaAtual(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.codigo,
            'codigo',
            codigoTokenExpirado,
          ),
        ),
      );
      expect(await armazenamento.ler(), isNull);
    },
  );

  test('token inválido (ex.: banco recriado) só volta sem conta', () async {
    final repositorio = repositorioQueResponde(401, 'TOKEN_INVALIDO');

    expect(await repositorio.contaAtual(), isNull);
    expect(await armazenamento.ler(), isNull);
  });

  test('sem token salvo, nem chama o servidor', () async {
    await armazenamento.apagar();
    final repositorio = repositorioQueResponde(500, 'NUNCA_CHAMADO');

    expect(await repositorio.contaAtual(), isNull);
  });
}
