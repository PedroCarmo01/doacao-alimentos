import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../data/doacoes/doacao_repository.dart';

/// ViewModel do detalhe da doação, lado da ONG (T22). O aceite ("Vou
/// retirar") entra na etapa 4.
class DetalheDoacaoOngViewModel extends ViewModelBase {
  DetalheDoacaoOngViewModel({
    required DoacaoRepository doacoes,
    required Sessao sessao,
    required Relogio relogio,
    required this.doacaoId,
  }) : _doacoes = doacoes,
       _sessao = sessao,
       _relogio = relogio;

  final DoacaoRepository _doacoes;
  final Sessao _sessao;
  final Relogio _relogio;
  final int doacaoId;

  DetalheDoacao? _detalhe;

  DetalheDoacao? get detalhe => _detalhe;

  /// Distância do ponto da ONG até a doação.
  double? get distanciaKm {
    final perfil = _sessao.perfil;
    final doacao = _detalhe?.doacao;
    if (perfil == null || doacao == null) return null;
    return Geo.distanciaKm(perfil.coordenadas, doacao.coordenadas);
  }

  /// RN24: suspensa vê, mas não aceita (o botão fica desativado).
  bool get suspensa => _sessao.perfil?.estaSuspensa(_relogio.agora()) ?? false;

  Future<bool> carregar() => executar(() async {
    _detalhe = await _doacoes.detalhar(doacaoId);
  });
}
