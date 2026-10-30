import '../doacao.dart';
import '../util/json.dart';

/// Corpo de `POST /doacoes`.
///
/// Se [latitude] e [longitude] não forem enviadas, o backend usa a
/// localização cadastrada no perfil do doador.
class DadosNovaDoacao {
  const DadosNovaDoacao({
    required this.titulo,
    required this.categoria,
    required this.quantidade,
    required this.validade,
    required this.janelaInicio,
    required this.janelaFim,
    required this.declaracaoAlimentosProprios,
    this.descricao,
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
      quantidade: j.texto('quantidade'),
      validade: j.data('validade'),
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
  final String quantidade;
  final DateTime validade;
  final DateTime janelaInicio;
  final DateTime janelaFim;
  final String? endereco;
  final double? latitude;
  final double? longitude;

  /// O doador declara que os alimentos estão próprios para consumo
  /// (exigência do escopo aprovado: não se aceitam produtos vencidos ou
  /// impróprios).
  final bool declaracaoAlimentosProprios;

  bool get possuiLocalizacao => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descricao': descricao,
        'categoria': categoria.name,
        'quantidade': quantidade,
        'validade': formatarData(validade),
        'janelaInicio': formatarInstante(janelaInicio),
        'janelaFim': formatarInstante(janelaFim),
        'endereco': endereco,
        'latitude': latitude,
        'longitude': longitude,
        'declaracaoAlimentosProprios': declaracaoAlimentosProprios,
      };
}
