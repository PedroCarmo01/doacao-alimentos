import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';
import '../../core/erros/erro_amigavel.dart';
import '../../core/mvvm/view_model_base.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/fotos/seletor_de_fotos.dart';
import '../../shared/widgets/secao_fotos.dart';

/// Os textos digitados no formulário da doação (classe Dart pura).
class CamposDaDoacao {
  const CamposDaDoacao({
    required this.titulo,
    required this.quantidade,
    required this.pesoKg,
    this.descricao = '',
    this.endereco = '',
  });

  final String titulo;
  final String quantidade;
  final String pesoKg;
  final String descricao;
  final String endereco;
}

/// ViewModel da nova doação e da edição (T11) — RN10.
///
/// Guarda as ESCOLHAS (categoria, unidade, horários, fotos...). Os textos
/// chegam em [salvar] como [CamposDaDoacao].
class NovaDoacaoViewModel extends ViewModelBase implements EscolhaDeFotos {
  NovaDoacaoViewModel({
    required DoacaoRepository doacoes,
    required SeletorDeFotos seletor,
    required Relogio relogio,
    this.doacaoId,
  }) : _doacoes = doacoes,
       _seletor = seletor,
       _relogio = relogio {
    final agora = _relogio.agora();
    _validade = Calendario.somenteData(agora.toLocal());
    _inicio = agora;
    _fim = agora.add(janelaPadrao);
  }

  final DoacaoRepository _doacoes;
  final SeletorDeFotos _seletor;
  final Relogio _relogio;

  /// `null` = nova doação; preenchido = editar esta doação.
  final int? doacaoId;

  /// T11: o horário de retirada começa "de agora até daqui a 4 h".
  static const janelaPadrao = Duration(hours: 4);

  CategoriaAlimento _categoria = CategoriaAlimento.hortifruti;
  Unidade _unidade = Unidade.kg;
  Conservacao _conservacao = Conservacao.ambiente;
  VeiculoNecessario? _veiculo;
  late DateTime _validade;
  late DateTime _inicio;
  late DateTime _fim;
  DateTime? _preparadoEm;
  bool _declaracao = false;
  final List<String> _fotosSalvas = [];
  final List<FotoEscolhida> _fotosNovas = [];
  Doacao? _original;
  Doacao? _resultado;
  int _ongsAvisadas = 0;
  int _fotosQueFalharam = 0;

  bool get editando => doacaoId != null;
  CategoriaAlimento get categoria => _categoria;
  Unidade get unidade => _unidade;
  Conservacao get conservacao => _conservacao;
  VeiculoNecessario? get veiculo => _veiculo;
  DateTime get validade => _validade;
  DateTime get inicio => _inicio;
  DateTime get fim => _fim;
  DateTime? get preparadoEm => _preparadoEm;
  bool get declaracao => _declaracao;
  bool get ehRefeicaoPronta => _categoria == CategoriaAlimento.refeicoesProntas;

  /// Fotos já enviadas (edição) e as novas, para a prévia.
  @override
  List<String> get fotosSalvas => List.unmodifiable(_fotosSalvas);
  @override
  List<FotoEscolhida> get fotosNovas => List.unmodifiable(_fotosNovas);
  @override
  bool get podeAdicionarFoto =>
      _fotosSalvas.length + _fotosNovas.length < Doacao.maximoDeFotos;

  /// Na edição: a doação como estava (a tela preenche os textos com ela).
  Doacao? get original => _original;

  /// Depois de salvar: a doação publicada/editada.
  Doacao? get resultado => _resultado;
  int get ongsAvisadas => _ongsAvisadas;
  int get fotosQueFalharam => _fotosQueFalharam;

  // --------------------------------------------------------------- escolhas

  void escolherCategoria(CategoriaAlimento categoria) {
    _categoria = categoria;
    // Refeição pronta: sugere "preparado agora" (a pessoa pode mudar).
    if (ehRefeicaoPronta) _preparadoEm ??= _relogio.agora();
    notificar();
  }

  void escolherUnidade(Unidade unidade) => _mudar(() => _unidade = unidade);
  void escolherConservacao(Conservacao valor) =>
      _mudar(() => _conservacao = valor);
  void escolherVeiculo(VeiculoNecessario? valor) =>
      _mudar(() => _veiculo = valor);
  void escolherValidade(DateTime dia) => _mudar(() => _validade = dia);
  void escolherPreparo(DateTime instante) =>
      _mudar(() => _preparadoEm = instante);
  void marcarDeclaracao(bool marcada) => _mudar(() => _declaracao = marcada);

  /// Mudar o início leva o fim junto (mantém a duração), para o fim nunca
  /// ficar antes do início sem querer.
  void escolherInicio(DateTime instante) => _mudar(() {
    final duracao = _fim.difference(_inicio);
    _inicio = instante;
    _fim = instante.add(duracao.isNegative ? janelaPadrao : duracao);
  });

  void escolherFim(DateTime instante) => _mudar(() => _fim = instante);

  @override
  void removerFotoNova(FotoEscolhida foto) =>
      _mudar(() => _fotosNovas.remove(foto));

  void _mudar(void Function() mudanca) {
    mudanca();
    notificar();
  }

  /// Câmera ou galeria. A foto só é enviada ao salvar.
  @override
  Future<bool> adicionarFoto({required bool daCamera}) => executar(() async {
    if (!podeAdicionarFoto) {
      throw const ErroDeRegra('Cada doação pode ter no máximo 3 fotos.');
    }
    final foto = daCamera
        ? await _seletor.tirarFoto()
        : await _seletor.escolherDaGaleria();
    if (foto != null) _fotosNovas.add(foto);
  });

  // ---------------------------------------------------------------- edição

  /// Edição: busca a doação e preenche as escolhas com o que ela tem.
  Future<bool> carregarParaEditar() => executar(() async {
    final doacao = (await _doacoes.detalhar(doacaoId!)).doacao;
    _original = doacao;
    _categoria = doacao.categoria;
    _unidade = doacao.unidade;
    _conservacao = doacao.conservacao;
    _veiculo = doacao.veiculo;
    _validade = doacao.validade;
    _inicio = doacao.janelaInicio;
    _fim = doacao.janelaFim;
    _preparadoEm = doacao.preparadoEm;
    _declaracao = true;
    _fotosSalvas
      ..clear()
      ..addAll(doacao.fotos);
  });

  // ---------------------------------------------------------------- salvar

  /// Confere as regras (RN10), publica ou edita e envia as fotos novas, uma
  /// por vez. Se uma foto falhar, a doação continua salva e
  /// [fotosQueFalharam] diz quantas não foram.
  Future<bool> salvar(CamposDaDoacao campos) => executar(() async {
    final dados = _montar(campos);
    final agora = _relogio.agora();
    final erros = ValidadorDoacao.validar(
      dados,
      agora: agora,
      hoje: Calendario.somenteData(agora.toLocal()),
    );
    if (erros.isNotEmpty) throw ErroDeRegra(erros.first);

    var doacao = editando
        ? await _doacoes.editar(doacaoId!, dados)
        : await _publicar(dados);
    _fotosQueFalharam = 0;
    for (final foto in List.of(_fotosNovas)) {
      try {
        doacao = await _doacoes.enviarFoto(doacao.id, foto);
        _fotosNovas.remove(foto);
      } on ApiException {
        _fotosQueFalharam++;
      }
    }
    _resultado = doacao;
  });

  Future<Doacao> _publicar(DadosNovaDoacao dados) async {
    final resposta = await _doacoes.publicar(dados);
    _ongsAvisadas = resposta.ongsAvisadas;
    return resposta.doacao;
  }

  DadosNovaDoacao _montar(CamposDaDoacao campos) => DadosNovaDoacao(
    titulo: campos.titulo.trim(),
    descricao: campos.descricao.trim().isEmpty ? null : campos.descricao,
    categoria: _categoria,
    quantidade: ValidadorDoacao.lerNumero(campos.quantidade) ?? 0,
    unidade: _unidade,
    pesoKg: ValidadorDoacao.lerNumero(campos.pesoKg) ?? 0,
    conservacao: _conservacao,
    veiculo: _veiculo,
    validade: _validade,
    preparadoEm: ehRefeicaoPronta ? _preparadoEm : null,
    janelaInicio: _inicio,
    janelaFim: _fim,
    // Endereço vazio: o servidor usa o do perfil.
    endereco: campos.endereco.trim().isEmpty ? null : campos.endereco.trim(),
    declaracaoAlimentosProprios: _declaracao,
  );
}
