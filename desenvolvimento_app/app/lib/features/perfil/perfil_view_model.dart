import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';

/// ViewModel do perfil (T50). Nesta etapa: mostrar a conta e sair.
/// Edição, estatísticas e preferências entram na etapa 7.
class PerfilViewModel extends ViewModelBase {
  PerfilViewModel({required Sessao sessao}) : _sessao = sessao;

  final Sessao _sessao;

  Conta? get conta => _sessao.conta;

  /// Apaga o token salvo e esquece a conta. Na próxima abertura, o app
  /// vai para o login (RN05: só sai quando a pessoa toca em Sair).
  Future<bool> sair() => executar(_sessao.encerrar);
}
