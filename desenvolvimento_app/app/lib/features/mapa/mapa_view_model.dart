import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../data/doacoes/doacao_repository.dart';

/// ViewModel do mapa da ONG (T21): as mesmas doações da lista, em volta do
/// ponto da ONG, e qual delas foi tocada.
class MapaViewModel extends ViewModelBase {
  MapaViewModel({required DoacaoRepository doacoes, required Sessao sessao})
    : _doacoes = doacoes,
      _sessao = sessao;

  final DoacaoRepository _doacoes;
  final Sessao _sessao;

  List<Doacao> _lista = const [];
  Doacao? _selecionada;

  List<Doacao> get doacoes => _lista;

  /// A doação do marcador tocado (mostra o cartão embaixo).
  Doacao? get selecionada => _selecionada;

  /// O centro da busca é o ponto cadastrado da ONG (não o GPS de agora).
  Coordenadas get centro =>
      _sessao.perfil?.coordenadas ?? const Coordenadas(-23.5229, -46.1880);
  double get raioKm => _sessao.perfil?.raioKm ?? Perfil.raioPadraoKm;

  /// Zoom que mostra o círculo inteiro na tela do celular.
  double get zoomInicial => switch (raioKm) {
    <= 2 => 14,
    <= 5 => 13,
    <= 10 => 12,
    _ => 11,
  };

  Future<bool> carregar() => executar(() async {
    _lista = await _doacoes.listarProximas();
    // Se a doação tocada sumiu (alguém aceitou), fecha o cartão.
    final atual = _selecionada;
    if (atual != null && !_lista.any((d) => d.id == atual.id)) {
      _selecionada = null;
    }
  });

  void selecionar(Doacao? doacao) {
    _selecionada = doacao;
    notificar();
  }
}
