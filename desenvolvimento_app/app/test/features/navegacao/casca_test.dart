import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/features/navegacao/casca_page.dart';
import 'package:summit_app/features/perfil/perfil_page.dart';
import 'package:summit_app/shared/widgets/barra_inferior.dart';

/// Barra inferior de 5 itens, diferente para doador e ONG (seção 2).
void main() {
  late Dependencias deps;

  setUp(() {
    deps = Dependencias.fake(
      banco: BancoFake(atrasoDeRede: Duration.zero, simularNovasDoacoes: false),
    );
  });

  Future<void> abrirCascaComo(WidgetTester tester, String email) async {
    final resposta = await deps.auth.entrar(
      DadosLogin(email: email, senha: 'senha123'),
    );
    await deps.sessao.iniciar(resposta);
    await tester.pumpWidget(MaterialApp(home: CascaPage(dependencias: deps)));
  }

  testWidgets('doador vê Início, Mensagens, Doar, Comunidade e Perfil', (
    tester,
  ) async {
    await abrirCascaComo(tester, 'mercado@exemplo.com');

    final barra = find.byType(BarraInferior);
    for (final rotulo in [
      'Início',
      'Mensagens',
      'Doar',
      'Comunidade',
      'Perfil',
    ]) {
      expect(
        find.descendant(of: barra, matching: find.text(rotulo)),
        findsOneWidget,
        reason: rotulo,
      );
    }
  });

  testWidgets('para a ONG, o botão do meio é o Mapa', (tester) async {
    await abrirCascaComo(tester, 'maosamigas@exemplo.com');

    final barra = find.byType(BarraInferior);
    expect(
      find.descendant(of: barra, matching: find.text('Mapa')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: barra, matching: find.text('Doar')),
      findsNothing,
    );
  });

  testWidgets('tocar em Perfil mostra a conta e o botão Sair', (tester) async {
    await abrirCascaComo(tester, 'maosamigas@exemplo.com');

    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(find.text('ONG Mãos Amigas'), findsOneWidget);
    expect(find.text('Verificada'), findsOneWidget);
    // A tela de teste é pequena: rola a lista do perfil até o botão.
    await tester.scrollUntilVisible(
      find.byKey(const Key('botao_sair')),
      200,
      scrollable: find.descendant(
        of: find.byType(PerfilPage),
        matching: find.byType(Scrollable),
      ),
    );

    expect(find.byKey(const Key('botao_sair')), findsOneWidget);
  });

  testWidgets('ONG com retirada em andamento vê a faixa laranja', (
    tester,
  ) async {
    await abrirCascaComo(tester, 'maosamigas@exemplo.com');
    await tester.pump(); // a primeira consulta da faixa

    expect(find.byKey(const Key('faixa_retirada')), findsOneWidget);
    expect(find.textContaining('Retirada em andamento'), findsOneWidget);
  });
}
