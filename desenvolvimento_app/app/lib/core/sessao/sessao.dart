import 'package:flutter/foundation.dart';
import 'package:shared_models/shared_models.dart';

import 'armazenamento_token.dart';

/// Quem está logado no app.
///
/// Existe UMA instância (criada em `Dependencias`) compartilhada pelas telas.
/// É um `ChangeNotifier`: quem precisar pode escutar mudanças de login.
class Sessao extends ChangeNotifier {
  Sessao(this._armazenamento);

  final ArmazenamentoToken _armazenamento;
  Conta? _conta;

  /// Usuário + perfil (organização e localização) de quem está logado.
  Conta? get conta => _conta;
  Usuario? get usuario => _conta?.usuario;
  Perfil? get perfil => _conta?.perfil;
  bool get logado => _conta != null;

  /// Depois de login/cadastro bem-sucedido: guarda o token e a conta.
  Future<void> iniciar(RespostaAutenticacao resposta) async {
    await _armazenamento.salvar(resposta.token);
    _conta = resposta.conta;
    notifyListeners();
  }

  /// Ao abrir o app com um token salvo e válido.
  void restaurar(Conta conta) {
    _conta = conta;
    notifyListeners();
  }

  /// Sair: apaga o token e esquece a conta.
  Future<void> encerrar() async {
    await _armazenamento.apagar();
    _conta = null;
    notifyListeners();
  }
}
