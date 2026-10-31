import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/notificacoes/mostrador_de_notificacoes.dart';
import 'package:summit_app/core/api/api_exception.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/data/auth/auth_repository.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/features/abertura/abertura_view_model.dart';

/// T1 — a abertura decide para onde ir. Nenhum teste precisa de backend:
/// usamos `Dependencias.fake()`.
void main() {
  late Dependencias deps;

  setUp(() {
    deps = Dependencias.fake(
      mostrador: MostradorEmMemoria(),
      banco: BancoFake(atrasoDeRede: Duration.zero, simularNovasDoacoes: false),
    );
  });

  AberturaViewModel criar({AuthRepository? auth}) => AberturaViewModel(
    auth: auth ?? deps.auth,
    sessao: deps.sessao,
    preferencias: deps.preferencias,
    tempoMinimo: Duration.zero,
  );

  test('primeira vez, sem login: vai para as boas-vindas', () async {
    final vm = criar();

    await vm.iniciar();

    expect(vm.destino, DestinoDaAbertura.boasVindas);
  });

  test('já viu as boas-vindas, sem login: vai para o login', () async {
    await deps.preferencias.marcarBoasVindasVistas();
    final vm = criar();

    await vm.iniciar();

    expect(vm.destino, DestinoDaAbertura.login);
  });

  test('RN05: com token salvo e válido, entra direto no início', () async {
    final resposta = await deps.auth.entrar(
      const DadosLogin(email: 'mercado@exemplo.com', senha: 'senha123'),
    );
    await deps.sessao.iniciar(resposta); // salva o token, como no login
    final vm = criar();

    await vm.iniciar();

    expect(vm.destino, DestinoDaAbertura.inicio);
    expect(deps.sessao.usuario?.email, 'mercado@exemplo.com');
  });

  test('RN05: token vencido vai ao login com "Sua sessão expirou"', () async {
    final vm = criar(
      auth: _AuthQueFalha(
        const ApiException(
          codigo: codigoTokenExpirado,
          mensagem: 'Sua sessão expirou. Entre novamente.',
          status: 401,
        ),
      ),
    );

    await vm.iniciar();

    expect(vm.destino, DestinoDaAbertura.login);
    expect(vm.aviso, AberturaViewModel.avisoSessaoExpirada);
  });

  test('servidor fora do ar: fica na abertura com o erro', () async {
    final vm = criar(auth: _AuthQueFalha(const ApiException.semConexao()));

    await vm.iniciar();

    expect(vm.destino, isNull);
    expect(vm.erro, isNotNull);
  });
}

/// AuthRepository que sempre falha em `contaAtual` com o [erro] dado.
class _AuthQueFalha implements AuthRepository {
  _AuthQueFalha(this.erro);

  final ApiException erro;

  @override
  Future<Conta?> contaAtual() async => throw erro;

  @override
  Future<RespostaAutenticacao> cadastrar(DadosCadastro dados) =>
      throw UnimplementedError();

  @override
  Future<RespostaAutenticacao> entrar(DadosLogin dados) =>
      throw UnimplementedError();
}
