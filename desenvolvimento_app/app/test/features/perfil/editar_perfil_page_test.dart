import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/notificacoes/mostrador_de_notificacoes.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/features/perfil/editar_perfil_page.dart';

/// Teste de widget da T50 ("Editar dados").
///
/// O que a tela precisa garantir: cada campo confere as MESMAS regras que
/// `EditarPerfilViewModel.salvar()` confere (`ValidadorUsuario.validarPerfil`),
/// mas **embaixo do campo**, enquanto a pessoa digita — como já acontece no
/// cadastro (T03). Antes, o erro só aparecia num snackbar depois de apertar
/// "Salvar", sem dizer qual campo estava errado.
void main() {
  late Dependencias deps;
  late RelogioFixo relogio;

  setUp(() async {
    relogio = RelogioFixo(DateTime.utc(2026, 9, 15, 15));
    deps = Dependencias.fake(
      mostrador: MostradorEmMemoria(),
      banco: BancoFake(
        relogio: relogio,
        atrasoDeRede: Duration.zero,
        simularNovasDoacoes: false,
      ),
    );
  });

  /// Abre a T50 logada como a ONG Mãos Amigas (é ela que tem o campo de
  /// famílias atendidas).
  Future<void> abrirEditarPerfil(WidgetTester tester) async {
    await deps.sessao.iniciar(
      await deps.auth.entrar(
        const DadosLogin(email: 'maosamigas@exemplo.com', senha: 'senha123'),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EditarPerfilPage(
          sessao: deps.sessao,
          perfis: deps.perfis,
          cep: deps.cep,
          localizacao: deps.localizacao,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Os campos de texto na ordem em que aparecem na lista da tela:
  // 0 = nome, 1 = organização, 2 = telefone, 3 = CEP, 4 = endereço,
  // 5 = famílias atendidas.
  const campoNome = 0;
  const campoTelefone = 2;

  Future<void> digitar(WidgetTester tester, int posicao, String texto) async {
    final campo = find.byType(TextFormField).at(posicao);
    await tester.tap(campo);
    await tester.pumpAndSettle();
    await tester.enterText(campo, texto);
    await tester.pumpAndSettle();
  }

  group('T50: validação embaixo do campo', () {
    testWidgets('abre com os dados salvos, sem nenhum erro na tela', (
      tester,
    ) async {
      await abrirEditarPerfil(tester);

      // Nada foi mexido: os valores vieram do perfil, então nada é recusado.
      expect(find.text('Informe o nome.'), findsNothing);
      expect(find.text('Informe o telefone com DDD.'), findsNothing);
      expect(find.text('O nome deve ter pelo menos 3 letras.'), findsNothing);
    });

    testWidgets('nome com 2 letras mostra o erro na hora, sem apertar Salvar', (
      tester,
    ) async {
      await abrirEditarPerfil(tester);
      await digitar(tester, campoNome, 'Ab');

      expect(find.text('O nome deve ter pelo menos 3 letras.'), findsOneWidget);
    });

    testWidgets('telefone sem DDD mostra o erro embaixo do próprio campo', (
      tester,
    ) async {
      await abrirEditarPerfil(tester);
      await digitar(tester, campoTelefone, '99999999');

      final erro = find.text('Informe o telefone com DDD.');
      expect(erro, findsOneWidget);

      // O erro pertence ao campo do telefone (e não a um snackbar da tela).
      final campoDoTelefone = find
          .ancestor(of: erro, matching: find.byType(TextFormField))
          .first;
      expect(campoDoTelefone, findsOneWidget);
      expect(
        tester.widget<TextFormField>(campoDoTelefone).controller!.text,
        '99999999',
      );
    });

    testWidgets('corrige o telefone e o erro some sozinha', (tester) async {
      await abrirEditarPerfil(tester);
      await digitar(tester, campoTelefone, '99999999');
      expect(find.text('Informe o telefone com DDD.'), findsOneWidget);

      await digitar(tester, campoTelefone, '11999998888');
      expect(find.text('Informe o telefone com DDD.'), findsNothing);
    });
  });
}
