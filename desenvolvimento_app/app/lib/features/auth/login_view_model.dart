import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../data/auth/auth_repository.dart';

/// ViewModel do login (T3).
class LoginViewModel extends ViewModelBase {
  LoginViewModel({required AuthRepository auth, required Sessao sessao})
    : _auth = auth,
      _sessao = sessao;

  final AuthRepository _auth;
  final Sessao _sessao;

  /// RN05: depois de entrar, o token fica salvo no armazenamento seguro e o
  /// app abre direto no início nas próximas vezes (sem caixa "manter
  /// conectado": é sempre).
  Future<bool> entrar({required String email, required String senha}) =>
      executar(() async {
        final resposta = await _auth.entrar(
          DadosLogin(email: email, senha: senha),
        );
        await _sessao.iniciar(resposta);
      });
}
