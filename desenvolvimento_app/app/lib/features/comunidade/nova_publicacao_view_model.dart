import 'package:shared_models/shared_models.dart';

import '../../core/erros/erro_amigavel.dart';
import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../data/comunidade/comunidade_repository.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/fotos/seletor_de_fotos.dart';
import '../../data/reservas/reserva_repository.dart';
import '../../shared/widgets/secao_fotos.dart';

/// Uma doação concluída que pode ser ligada à publicação (T41).
class OpcaoDeDoacao {
  const OpcaoDeDoacao(this.doacaoId, this.titulo);

  final int doacaoId;
  final String titulo;
}

/// ViewModel da nova publicação (T41): texto, até 3 fotos, a doação
/// concluída ligada (opcional), famílias e refeições (RN40).
class NovaPublicacaoViewModel extends ViewModelBase implements EscolhaDeFotos {
  NovaPublicacaoViewModel({
    required ComunidadeRepository comunidade,
    required DoacaoRepository doacoes,
    required ReservaRepository reservas,
    required SeletorDeFotos seletor,
    required Sessao sessao,
    int? doacaoInicial,
  }) : _comunidade = comunidade,
       _doacoes = doacoes,
       _reservas = reservas,
       _seletor = seletor,
       _sessao = sessao,
       _doacaoId = doacaoInicial;

  final ComunidadeRepository _comunidade;
  final DoacaoRepository _doacoes;
  final ReservaRepository _reservas;
  final SeletorDeFotos _seletor;
  final Sessao _sessao;

  final List<FotoEscolhida> _fotosNovas = [];
  List<OpcaoDeDoacao> _opcoes = const [];
  int? _doacaoId;
  int _fotosQueFalharam = 0;

  /// As doações concluídas de que a pessoa participou.
  List<OpcaoDeDoacao> get opcoes => _opcoes;

  /// A escolhida (`null` = não ligar a nenhuma).
  int? get doacaoId => _doacaoId;

  /// Quantas fotos não foram enviadas (a publicação saiu mesmo assim).
  int get fotosQueFalharam => _fotosQueFalharam;

  // --------------------------------------------- EscolhaDeFotos (SecaoFotos)

  @override
  List<String> get fotosSalvas => const []; // publicação nova: nenhuma ainda

  @override
  List<FotoEscolhida> get fotosNovas => List.unmodifiable(_fotosNovas);

  @override
  bool get podeAdicionarFoto => _fotosNovas.length < Publicacao.maximoDeFotos;

  @override
  Future<bool> adicionarFoto({required bool daCamera}) => executar(() async {
    final foto = daCamera
        ? await _seletor.tirarFoto()
        : await _seletor.escolherDaGaleria();
    if (foto != null && podeAdicionarFoto) _fotosNovas.add(foto);
  });

  @override
  void removerFotoNova(FotoEscolhida foto) {
    _fotosNovas.remove(foto);
    notificar();
  }

  // ------------------------------------------------------------------ ações

  void escolherDoacao(int? doacaoId) {
    _doacaoId = doacaoId;
    notificar();
  }

  /// O doador lista as doações dele que foram entregues; a ONG, as que ela
  /// retirou. Se falhar, a pessoa publica sem ligar (não é obrigatório).
  Future<void> carregarOpcoes() async {
    try {
      if (_sessao.usuario?.ehOng ?? false) {
        final retiradas = await _reservas.listarMinhas(
          SituacaoDaLista.historico,
        );
        _opcoes = [
          for (final r in retiradas)
            if (r.status == StatusReserva.concluida)
              OpcaoDeDoacao(r.doacaoId, r.tituloDoacao ?? 'Doação'),
        ];
      } else {
        final doacoes = await _doacoes.listarMinhas(SituacaoDaLista.historico);
        _opcoes = [
          for (final d in doacoes)
            if (d.status == StatusDoacao.concluida)
              OpcaoDeDoacao(d.id, d.titulo),
        ];
      }
      // A doação que veio da tela anterior precisa estar na lista.
      if (_opcoes.every((o) => o.doacaoId != _doacaoId)) _doacaoId = null;
      notificar();
    } catch (_) {
      // Sem a lista, a pessoa ainda pode publicar sem ligar.
    }
  }

  /// RN40: valida, publica e envia as fotos (uma por vez).
  Future<bool> publicar({
    required String texto,
    required String familias,
    required String refeicoes,
  }) => executar(() async {
    final dados = DadosPublicacao(
      texto: texto.trim(),
      doacaoId: _doacaoId,
      familiasAjudadas: _numero(familias),
      refeicoes: _numero(refeicoes),
    );
    final erros = dados.validar();
    if (erros.isNotEmpty) throw ErroDeRegra(erros.first);
    final publicacao = await _comunidade.publicar(dados);
    _fotosQueFalharam = 0;
    for (final foto in _fotosNovas) {
      try {
        await _comunidade.enviarFoto(publicacao.id, foto);
      } catch (_) {
        _fotosQueFalharam++;
      }
    }
  });

  /// Campo vazio = não informado. Texto que não é número vira -1, que a
  /// validação recusa com uma mensagem clara.
  static int? _numero(String texto) {
    final limpo = texto.trim();
    if (limpo.isEmpty) return null;
    return int.tryParse(limpo) ?? -1;
  }
}
