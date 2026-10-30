import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';
import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/perfil/perfil_repository.dart';

/// ViewModel de "Doações perto de você" (T20): lista da mais perto para a
/// mais longe, busca ativa, raio e a etiqueta NOVA.
class HomeOngViewModel extends ViewModelBase {
  HomeOngViewModel({
    required DoacaoRepository doacoes,
    required PerfilRepository perfis,
    required Sessao sessao,
    required Relogio relogio,
  }) : _doacoes = doacoes,
       _perfis = perfis,
       _sessao = sessao,
       _relogio = relogio;

  final DoacaoRepository _doacoes;
  final PerfilRepository _perfis;
  final Sessao _sessao;
  final Relogio _relogio;

  /// Na primeira vez que a lista abre, "NOVA" = publicada há menos disso.
  static const janelaDeNovidade = Duration(hours: 1);

  List<Doacao> _lista = const [];
  bool _carregou = false;
  DateTime _agora = DateTime.utc(2000);

  /// Ids que a ONG já viu nesta sessão (o que não estiver aqui é NOVA).
  final Set<int> _vistas = {};
  final Set<int> _novas = {};

  List<Doacao> get doacoes => _lista;
  bool get carregou => _carregou;
  DateTime get agora => _agora;
  bool ehNova(Doacao doacao) => _novas.contains(doacao.id);

  Perfil? get _perfil => _sessao.perfil;
  bool get buscaAtiva => _perfil?.buscaAtiva ?? true;
  double get raioKm => _perfil?.raioKm ?? Perfil.raioPadraoKm;

  /// RN24: até quando a ONG está suspensa (ou `null` se não está).
  DateTime? get suspensaAte {
    final perfil = _perfil;
    if (perfil == null || !perfil.estaSuspensa(_relogio.agora())) return null;
    return perfil.suspensaAte;
  }

  Future<bool> carregar() => executar(_buscar);

  /// Chamada pelo relógio da tela a cada 15 s: sem "carregando" e sem
  /// mostrar erro (se a internet piscar, tenta de novo na próxima vez).
  Future<void> atualizarEmSilencio() async {
    if (ocupado || !_carregou) return;
    try {
      await _buscar();
      notificar();
    } on ApiException {
      // Silêncio de propósito: a lista antiga continua na tela.
    }
  }

  /// Desligada: a ONG continua vendo a lista, mas não recebe avisos (T20).
  Future<bool> mudarBuscaAtiva(bool ligada) => executar(() async {
    await _salvarPerfil(buscaAtiva: ligada);
  });

  /// Troca o raio (2, 5, 10 ou 20 km), salva no perfil e busca de novo.
  Future<bool> mudarRaio(double km) => executar(() async {
    await _salvarPerfil(raioKm: km);
    await _buscar();
  });

  Future<void> _salvarPerfil({bool? buscaAtiva, double? raioKm}) async {
    final conta = _sessao.conta;
    if (conta == null) return;
    final atualizada = await _perfis.atualizar(
      dadosDoPerfil(conta, buscaAtiva: buscaAtiva, raioKm: raioKm),
    );
    _sessao.restaurar(atualizada);
  }

  Future<void> _buscar() async {
    final lista = await _doacoes.listarProximas();
    _agora = _relogio.agora();
    for (final doacao in lista) {
      final primeiraVez = !_carregou;
      final recente = _agora.difference(doacao.criadoEm) < janelaDeNovidade;
      final apareceuAgora = _carregou && !_vistas.contains(doacao.id);
      if ((primeiraVez && recente) || apareceuAgora) _novas.add(doacao.id);
      _vistas.add(doacao.id);
    }
    _lista = lista;
    _carregou = true;
  }
}
