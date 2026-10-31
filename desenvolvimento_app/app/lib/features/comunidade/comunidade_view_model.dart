import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../data/comunidade/comunidade_repository.dart';

/// ViewModel da Comunidade (T40): painel de impacto, feed em páginas,
/// apoiar (RN41) e denunciar (RN42).
class ComunidadeViewModel extends ViewModelBase {
  ComunidadeViewModel({
    required ComunidadeRepository comunidade,
    required Sessao sessao,
  }) : _comunidade = comunidade,
       _sessao = sessao;

  final ComunidadeRepository _comunidade;
  final Sessao _sessao;

  /// Publicações por página (igual ao servidor).
  static const porPagina = 20;

  Impacto? _impacto;
  final List<Publicacao> _publicacoes = [];
  bool _carregou = false;
  bool _temMais = false;
  bool _carregandoMais = false;

  Impacto? get impacto => _impacto;
  List<Publicacao> get publicacoes => List.unmodifiable(_publicacoes);
  bool get carregou => _carregou;

  /// Ainda há publicações mais antigas para buscar?
  bool get temMais => _temMais;
  bool get carregandoMais => _carregandoMais;

  /// A publicação é minha? (não dá para denunciar a própria)
  bool ehMinha(Publicacao publicacao) =>
      publicacao.autorId == _sessao.usuario?.id;

  /// Primeira página + painel (também ao puxar para atualizar).
  Future<bool> carregar() => executar(() async {
    _impacto = await _comunidade.impacto();
    final pagina = await _comunidade.feed();
    _publicacoes
      ..clear()
      ..addAll(pagina);
    _temMais = pagina.length == porPagina;
    _carregou = true;
  });

  /// As próximas 20, mais antigas que a última da tela.
  Future<void> carregarMais() async {
    if (_carregandoMais || !_temMais || _publicacoes.isEmpty) return;
    _carregandoMais = true;
    notificar();
    try {
      final pagina = await _comunidade.feed(antesDe: _publicacoes.last.id);
      _publicacoes.addAll(pagina);
      _temMais = pagina.length == porPagina;
    } catch (_) {
      definirErro('Não foi possível carregar mais publicações.');
    } finally {
      _carregandoMais = false;
      notificar();
    }
  }

  /// RN41: apoiar ou desfazer. A tela muda NA HORA (o coração enche) e,
  /// se o servidor recusar, volta ao que era.
  Future<void> alternarApoio(Publicacao publicacao) async {
    final apoiar = !publicacao.apoiadaPorMim;
    _trocar(publicacao.comApoio(apoiada: apoiar));
    try {
      _trocar(await _comunidade.apoiar(publicacao.id, apoiar: apoiar));
    } catch (_) {
      _trocar(publicacao);
      definirErro('Não foi possível registrar o apoio. Tente de novo.');
    }
  }

  /// RN42: denuncia e tira a publicação da tela de quem denunciou.
  Future<bool> denunciar(Publicacao publicacao, MotivoDenuncia motivo) =>
      executar(() async {
        await _comunidade.denunciar(publicacao.id, motivo);
        _publicacoes.removeWhere((p) => p.id == publicacao.id);
      });

  void _trocar(Publicacao nova) {
    final i = _publicacoes.indexWhere((p) => p.id == nova.id);
    if (i < 0) return;
    _publicacoes[i] = nova;
    notificar();
  }
}
