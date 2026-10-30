import '../../core/mvvm/view_model_base.dart';
import '../../core/preferencias/preferencias.dart';
import '../../data/localizacao/localizacao_service.dart';

/// ViewModel das boas-vindas (T2, só na primeira vez).
class BoasVindasViewModel extends ViewModelBase {
  BoasVindasViewModel({
    required Preferencias preferencias,
    required LocalizacaoService localizacao,
  }) : _preferencias = preferencias,
       _localizacao = localizacao;

  final Preferencias _preferencias;
  final LocalizacaoService _localizacao;

  /// Termina as boas-vindas. Se [pedirPermissoes], pede a localização ao
  /// Android DEPOIS de explicar o motivo (assim menos gente toca em
  /// "Não permitir").
  ///
  /// A permissão de NOTIFICAÇÕES (Android 13+) é pedida aqui na etapa 5,
  /// quando o app passar a mostrar notificações.
  Future<bool> concluir({required bool pedirPermissoes}) => executar(() async {
    if (pedirPermissoes) {
      // Se a pessoa negar, tudo bem: no cadastro ela pode usar o CEP.
      await _localizacao.pedirPermissao();
    }
    await _preferencias.marcarBoasVindasVistas();
  });
}
