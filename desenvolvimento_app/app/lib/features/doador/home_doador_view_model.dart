import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../data/doacoes/doacao_repository.dart';

/// ViewModel de "Minhas doações" (T10): abas Ativas e Histórico e o resumo
/// do impacto ("12 doações • 85 kg salvos").
class HomeDoadorViewModel extends ViewModelBase {
  HomeDoadorViewModel({
    required DoacaoRepository doacoes,
    required Sessao sessao,
    required Relogio relogio,
  }) : _doacoes = doacoes,
       _sessao = sessao,
       _relogio = relogio;

  final DoacaoRepository _doacoes;
  final Sessao _sessao;
  final Relogio _relogio;

  List<Doacao> _ativas = const [];
  List<Doacao> _historico = const [];
  bool _carregou = false;
  DateTime _agora = DateTime.utc(2000);

  List<Doacao> get ativas => _ativas;
  List<Doacao> get historico => _historico;

  /// `true` depois do primeiro carregamento que deu certo.
  bool get carregou => _carregou;

  /// O "agora" de quando a lista chegou (os cartões calculam o tempo que
  /// falta a partir dele).
  DateTime get agora => _agora;

  String get nomeOrganizacao => _sessao.perfil?.nomeOrganizacao ?? '';

  List<Doacao> get _concluidas => [
    for (final d in _historico)
      if (d.status == StatusDoacao.concluida) d,
  ];

  /// Doações que chegaram às ONGs.
  int get totalConcluidas => _concluidas.length;

  /// Peso das doações concluídas: o que deixou de ir para o lixo.
  double get kgSalvos {
    var total = 0.0;
    for (final doacao in _concluidas) {
      total += doacao.pesoKg;
    }
    return total;
  }

  /// Busca as duas abas de uma vez (são listas pequenas).
  Future<bool> carregar() => executar(() async {
    final ativas = await _doacoes.listarMinhas(SituacaoDaLista.ativas);
    final historico = await _doacoes.listarMinhas(SituacaoDaLista.historico);
    _ativas = ativas;
    _historico = historico;
    _agora = _relogio.agora();
    _carregou = true;
  });
}
