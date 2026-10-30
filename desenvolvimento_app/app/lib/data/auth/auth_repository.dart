import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/sessao/armazenamento_token.dart';
import '../fake/banco_fake.dart';

/// CONTRATO de autenticação: O QUE o app precisa, sem dizer COMO.
///
/// Duas implementações (polimorfismo):
/// - [AuthRepositoryApi]: conversa com o backend (`/auth/...`).
/// - [AuthRepositoryFake]: dados em memória (modo `USAR_FAKE=true`).
///
/// ViewModels recebem o tipo [AuthRepository]; não sabem qual das duas é.
abstract interface class AuthRepository {
  /// `POST /auth/cadastro`
  Future<RespostaAutenticacao> cadastrar(DadosCadastro dados);

  /// `POST /auth/login`
  Future<RespostaAutenticacao> entrar(DadosLogin dados);

  /// `GET /auth/me`. Devolve `null` se não houver token salvo ou se ele não
  /// for mais válido.
  Future<Conta?> contaAtual();
}

class AuthRepositoryApi implements AuthRepository {
  AuthRepositoryApi(this._api, this._armazenamento);

  final ApiClient _api;
  final ArmazenamentoToken _armazenamento;

  @override
  Future<RespostaAutenticacao> cadastrar(DadosCadastro dados) async {
    final json = await _api.post('/auth/cadastro', corpo: dados.toJson());
    return RespostaAutenticacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<RespostaAutenticacao> entrar(DadosLogin dados) async {
    final json = await _api.post('/auth/login', corpo: dados.toJson());
    return RespostaAutenticacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<Conta?> contaAtual() async {
    if (await _armazenamento.ler() == null) return null;
    try {
      final json = await _api.get('/auth/me');
      return Conta.fromJson(ApiClient.objeto(json));
    } on ApiException catch (e) {
      // 401: token expirado/inválido. 404: rota ainda não implementada.
      if (e.status == 401 || e.status == 404) {
        await _armazenamento.apagar();
        return null;
      }
      rethrow;
    }
  }
}

class AuthRepositoryFake implements AuthRepository {
  AuthRepositoryFake(this._banco, this._armazenamento);

  final BancoFake _banco;
  final ArmazenamentoToken _armazenamento;

  @override
  Future<RespostaAutenticacao> cadastrar(DadosCadastro dados) async {
    await _banco.simularRede();
    final conta = _banco.cadastrar(dados);
    return RespostaAutenticacao(
      token: _banco.tokenPara(conta),
      conta: conta,
    );
  }

  @override
  Future<RespostaAutenticacao> entrar(DadosLogin dados) async {
    await _banco.simularRede();
    final conta = _banco.autenticar(dados.email, dados.senha);
    return RespostaAutenticacao(
      token: _banco.tokenPara(conta),
      conta: conta,
    );
  }

  @override
  Future<Conta?> contaAtual() async {
    await _banco.simularRede();
    return _banco.contaDoToken(await _armazenamento.ler());
  }
}
