import '../../core/mvvm/view_model_base.dart';
import '../../core/notificacoes/mostrador_de_notificacoes.dart';
import '../../core/preferencias/preferencias.dart';
import '../../data/localizacao/localizacao_service.dart';

/// ViewModel das boas-vindas (T2, só na primeira vez).
class BoasVindasViewModel extends ViewModelBase {
  BoasVindasViewModel({
    required Preferencias preferencias,
    required LocalizacaoService localizacao,
    required MostradorDeNotificacoes notificacoes,
  }) : _preferencias = preferencias,
       _localizacao = localizacao,
       _notificacoes = notificacoes;

  final Preferencias _preferencias;
  final LocalizacaoService _localizacao;
  final MostradorDeNotificacoes _notificacoes;

  /// Termina as boas-vindas. Se [pedirPermissoes], pede a localização e as
  /// notificações (Android 13+) DEPOIS de explicar o motivo (assim menos
  /// gente toca em "Não permitir").
  Future<bool> concluir({required bool pedirPermissoes}) => executar(() async {
    if (pedirPermissoes) {
      // Se a pessoa negar, tudo bem: no cadastro ela pode usar o CEP.
      await _localizacao.pedirPermissao();
      await _notificacoes.pedirPermissao();
    }
    await _preferencias.marcarBoasVindasVistas();
  });
}
