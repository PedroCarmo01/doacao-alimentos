import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/data/fotos/seletor_de_fotos.dart';
import 'package:summit_app/features/doador/nova_doacao_page.dart';

/// Teste de widget do formulário T11: preencher, publicar e ver o sucesso.
void main() {
  testWidgets('preenche o formulário, publica e mostra "Doação publicada!"', (
    tester,
  ) async {
    final relogio = RelogioFixo(DateTime.utc(2026, 9, 15, 15));
    final deps = Dependencias.fake(
      banco: BancoFake(
        relogio: relogio,
        atrasoDeRede: Duration.zero,
        simularNovasDoacoes: false,
      ),
      seletorDeFotos: const SeletorDeFotosFake(),
    );
    await deps.sessao.iniciar(
      await deps.auth.entrar(
        const DadosLogin(email: 'padaria@exemplo.com', senha: 'senha123'),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NovaDoacaoPage(
          doacoes: deps.doacoes,
          seletor: deps.seletorDeFotos,
          sessao: deps.sessao,
          relogio: relogio,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('campo_titulo')), 'Pães');
    await tester.enterText(find.byKey(const Key('campo_quantidade')), '30');
    await tester.enterText(find.byKey(const Key('campo_peso')), '6');
    await tester.scrollUntilVisible(
      find.byKey(const Key('declaracao')),
      300,
      // A lista do formulário (cada campo de texto também rola por dentro).
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    // Garante a caixa inteira na tela (não escondida atrás do rodapé).
    await tester.ensureVisible(find.byKey(const Key('declaracao')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('declaracao')));
    await tester.tap(find.byKey(const Key('botao_publicar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('doacao_publicada')), findsOneWidget);
    expect(
      find.text('As ONGs próximas já podem vê-la na lista de doações.'),
      findsOneWidget,
    );
  });
}
