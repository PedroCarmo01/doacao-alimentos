import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/features/auth/presentation/escolha_perfil_page.dart';
import 'package:summit_app/features/auth/presentation/escolha_perfil_view_model.dart';
import 'package:shared_models/shared_models.dart';

/// Exemplo de referência de testes de ViewModel e de widget.
/// Repare que nenhum teste precisa de backend: usamos Dependencias.fake().
void main() {
  late Dependencias deps;

  setUp(() {
    deps = Dependencias.fake(
      banco: BancoFake(atrasoDeRede: Duration.zero, simularNovasDoacoes: false),
    );
  });

  group('EscolhaPerfilViewModel', () {
    test('sem token salvo, não restaura sessão', () async {
      final vm = EscolhaPerfilViewModel(
        sistema: deps.sistema,
        auth: deps.auth,
        sessao: deps.sessao,
      );

      await vm.iniciar();

      expect(vm.status?.tudoCerto, isTrue);
      expect(vm.contaRestaurada, isNull);
      expect(deps.sessao.logado, isFalse);
    });

    test('com token válido, restaura a sessão', () async {
      final resposta = await deps.auth.entrar(
        const DadosLogin(email: 'mercado@exemplo.com', senha: 'senha123'),
      );
      await deps.sessao.iniciar(resposta); // salva o token, como no login

      final vm = EscolhaPerfilViewModel(
        sistema: deps.sistema,
        auth: deps.auth,
        sessao: deps.sessao,
      );
      await vm.iniciar();

      expect(vm.contaRestaurada?.usuario.tipo, TipoUsuario.doador);
    });
  });

  testWidgets('mostra os dois perfis e o status do servidor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EscolhaPerfilPage(
          sistema: deps.sistema,
          auth: deps.auth,
          sessao: deps.sessao,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('botao_doador')), findsOneWidget);
    expect(find.byKey(const Key('botao_ong')), findsOneWidget);
    expect(find.text('Modo demonstração (dados fictícios)'), findsOneWidget);
  });
}
