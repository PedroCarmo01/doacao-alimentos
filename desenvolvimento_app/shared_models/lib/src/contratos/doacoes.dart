import '../doacao.dart';
import '../tipos_de_doacao.dart';
import '../util/json.dart';

/// Corpo de `POST /doacoes` (publicar) e de `PUT /doacoes/{id}` (editar).
///
/// Se [latitude] e [longitude] não forem enviadas, o backend usa a
/// localização cadastrada no perfil do doador. As fotos vão depois, uma por
/// vez, em `POST /doacoes/{id}/fotos`.
class DadosNovaDoacao {
  const DadosNovaDoacao({
    required this.titulo,
    required this.categoria,
    required this.quantidade,
    required this.unidade,
    required this.pesoKg,
    required this.conservacao,
    required this.validade,
    required this.janelaInicio,
    required this.janelaFim,
    required this.declaracaoAlimentosProprios,
    this.descricao,
    this.veiculo,
    this.preparadoEm,
    this.endereco,
    this.latitude,
    this.longitude,
  });

  factory DadosNovaDoacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'NovaDoacao');
    return DadosNovaDoacao(
      titulo: j.texto('titulo'),
      descricao: j.textoOpcional('descricao'),
      categoria: j.enumerado('categoria', CategoriaAlimento.values),
      quantidade: j.decimal('quantidade'),
      unidade: j.enumerado('unidade', Unidade.values),
      pesoKg: j.decimal('pesoKg'),
      conservacao: j.enumerado('conservacao', Conservacao.values),
      veiculo: j.enumeradoOpcional('veiculo', VeiculoNecessario.values),
      validade: j.data('validade'),
      preparadoEm: j.instanteOpcional('preparadoEm'),
      janelaInicio: j.instante('janelaInicio'),
      janelaFim: j.instante('janelaFim'),
      endereco: j.textoOpcional('endereco'),
      latitude: j.decimalOpcional('latitude'),
      longitude: j.decimalOpcional('longitude'),
      declaracaoAlimentosProprios: j.booleano('declaracaoAlimentosProprios'),
    );
  }

  final String titulo;
  final String? descricao;
  final CategoriaAlimento categoria;
  final double quantidade;
  final Unidade unidade;
  final double pesoKg;
  final Conservacao conservacao;
  final VeiculoNecessario? veiculo;
  final DateTime validade;

  /// Obrigatório só para refeições prontas.
  final DateTime? preparadoEm;
  final DateTime janelaInicio;
  final DateTime janelaFim;
  final String? endereco;
  final double? latitude;
  final double? longitude;

  /// "Declaro que os alimentos estão dentro da validade e próprios para
  /// consumo." (RN10)
  final bool declaracaoAlimentosProprios;

  bool get possuiLocalizacao => latitude != null && longitude != null;

  /// Para preencher o formulário de edição com a doação atual.
  factory DadosNovaDoacao.daDoacao(Doacao doacao) => DadosNovaDoacao(
    titulo: doacao.titulo,
    descricao: doacao.descricao,
    categoria: doacao.categoria,
    quantidade: doacao.quantidade,
    unidade: doacao.unidade,
    pesoKg: doacao.pesoKg,
    conservacao: doacao.conservacao,
    veiculo: doacao.veiculo,
    validade: doacao.validade,
    preparadoEm: doacao.preparadoEm,
    janelaInicio: doacao.janelaInicio,
    janelaFim: doacao.janelaFim,
    endereco: doacao.endereco,
    latitude: doacao.latitude,
    longitude: doacao.longitude,
    declaracaoAlimentosProprios: true,
  );

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'descricao': descricao,
    'categoria': categoria.name,
    'quantidade': quantidade,
    'unidade': unidade.name,
    'pesoKg': pesoKg,
    'conservacao': conservacao.name,
    'veiculo': veiculo?.name,
    'validade': formatarData(validade),
    'preparadoEm': preparadoEm == null ? null : formatarInstante(preparadoEm!),
    'janelaInicio': formatarInstante(janelaInicio),
    'janelaFim': formatarInstante(janelaFim),
    'endereco': endereco,
    'latitude': latitude,
    'longitude': longitude,
    'declaracaoAlimentosProprios': declaracaoAlimentosProprios,
  };
}

/// Resposta de `POST /doacoes`: a doação criada e quantas ONGs próximas
/// foram avisadas (RN11; o aviso de verdade começa na etapa 5).
class RespostaPublicacao {
  const RespostaPublicacao({required this.doacao, required this.ongsAvisadas});

  factory RespostaPublicacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'RespostaPublicacao');
    return RespostaPublicacao(
      doacao: Doacao.fromJson(j.objeto('doacao').mapa),
      ongsAvisadas: j.inteiro('ongsAvisadas'),
    );
  }

  final Doacao doacao;
  final int ongsAvisadas;

  Map<String, dynamic> toJson() => {
    'doacao': doacao.toJson(),
    'ongsAvisadas': ongsAvisadas,
  };
}

/// Corpo (opcional) de `DELETE /doacoes/{id}`. RN12: o motivo é obrigatório
/// quando a doação já está reservada (a ONG recebe o motivo).
class DadosCancelamento {
  const DadosCancelamento({this.motivo});

  factory DadosCancelamento.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Cancelamento');
    return DadosCancelamento(motivo: j.textoOpcional('motivo'));
  }

  final String? motivo;

  Map<String, dynamic> toJson() => {'motivo': motivo};
}
