import 'package:flutter_test/flutter_test.dart';
import 'package:summit_app/core/notificacoes/mostrador_de_notificacoes.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/features/auth/login_view_model.dart';

/// T3 — login.
void main() {
  late Dependencias deps;
  late LoginViewModel vm;

  setUp(() {
    deps = Dependencias.fake(
      mostrador: MostradorEmMemoria(),
      banco: BancoFake(atrasoDeRede: Duration.zero, simularNovasDoacoes: false),
    );
    vm = LoginViewModel(auth: deps.auth, sessao: deps.sessao);
  });

  test('RN05: login certo inicia a sessão e salva o token', () async {
    final entrou = await vm.entrar(
      email: 'maosamigas@exemplo.com',
      senha: 'senha123',
    );

    expect(entrou, isTrue);
    expect(deps.sessao.usuario?.ehOng, isTrue);
    // O token salvo é o que permite abrir o app já logado.
    expect(await deps.auth.contaAtual(), isNotNull);
  });

  test('senha errada mostra "E-mail ou senha incorretos."', () async {
    final entrou = await vm.entrar(
      email: 'maosamigas@exemplo.com',
      senha: 'errada',
    );

    expect(entrou, isFalse);
    expect(vm.erro, 'E-mail ou senha incorretos.');
    expect(deps.sessao.logado, isFalse);
  });

  test('os 7 usuários do seed também existem no modo Fake', () async {
    for (final email in [
      'mercado@exemplo.com',
      'padaria@exemplo.com',
      'feirante@exemplo.com',
      'maosamigas@exemplo.com',
      'pratocheio@exemplo.com',
      'suspensa@exemplo.com',
      'distante@exemplo.com',
    ]) {
      expect(
        await vm.entrar(email: email, senha: 'senha123'),
        isTrue,
        reason: email,
      );
    }
  });
}
