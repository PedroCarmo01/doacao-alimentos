import 'geo/geo.dart';
import 'tipos_de_doacao.dart';
import 'util/json.dart';

/// Excedente de alimento anunciado por um doador.
///
/// Os campos [nomeDoador], [distanciaKm], [nomeOng] e [prazoRetirada] são
/// "de leitura": o backend os preenche em algumas consultas (lista da ONG,
/// minhas doações) para a tela não precisar pedir mais nada.
class Doacao {
  const Doacao({
    required this.id,
    required this.doadorId,
    required this.titulo,
    required this.categoria,
    required this.quantidade,
    required this.unidade,
    required this.pesoKg,
    required this.conservacao,
    required this.validade,
    required this.janelaInicio,
    required this.janelaFim,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.criadoEm,
    this.descricao,
    this.veiculo,
    this.preparadoEm,
    this.endereco,
    this.motivoCancelamento,
    this.fotos = const [],
    this.nomeDoador,
    this.distanciaKm,
    this.nomeOng,
    this.prazoRetirada,
  });

  factory Doacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Doacao');
    final fotos = json['fotos'];
    return Doacao(
      id: j.inteiro('id'),
      doadorId: j.inteiro('doadorId'),
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
      latitude: j.decimal('latitude'),
      longitude: j.decimal('longitude'),
      status: j.enumerado('status', StatusDoacao.values),
      motivoCancelamento: j.textoOpcional('motivoCancelamento'),
      criadoEm: j.instante('criadoEm'),
      fotos: fotos is List ? [for (final foto in fotos) '$foto'] : const [],
      nomeDoador: j.textoOpcional('nomeDoador'),
      distanciaKm: j.decimalOpcional('distanciaKm'),
      nomeOng: j.textoOpcional('nomeOng'),
      prazoRetirada: j.instanteOpcional('prazoRetirada'),
    );
  }

  final int id;
  final int doadorId;
  final String titulo;
  final String? descricao;
  final CategoriaAlimento categoria;

  /// Número da quantidade (ex.: 5) — a unidade fica em [unidade].
  final double quantidade;
  final Unidade unidade;

  /// Peso aproximado: soma no painel de impacto ("85 kg salvos").
  final double pesoKg;
  final Conservacao conservacao;
  final VeiculoNecessario? veiculo;

  /// Data de validade (somente o dia).
  final DateTime validade;

  /// Refeições prontas: quando foram preparadas.
  final DateTime? preparadoEm;

  /// Período em que a ONG pode retirar (instantes em UTC).
  final DateTime janelaInicio;
  final DateTime janelaFim;

  final String? endereco;
  final double latitude;
  final double longitude;
  final StatusDoacao status;

  /// RN12: motivo informado ao cancelar uma doação reservada.
  final String? motivoCancelamento;
  final DateTime criadoEm;

  /// Nomes dos arquivos das fotos, na ordem (até 3).
  final List<String> fotos;

  final String? nomeDoador;
  final double? distanciaKm;

  /// Nome da ONG que vai retirar (quando reservada).
  final String? nomeOng;

  /// Até quando a ONG tem para retirar (quando reservada).
  final DateTime? prazoRetirada;

  /// No máximo 3 fotos por doação.
  static const maximoDeFotos = 3;

  Coordenadas get coordenadas => Coordenadas(latitude, longitude);

  bool get estaDisponivel => status == StatusDoacao.disponivel;

  /// "5 caixas", "2,5 kg", "24 unidades".
  String get quantidadeTexto {
    final inteiro = quantidade == quantidade.truncateToDouble();
    final numero = inteiro
        ? quantidade.toStringAsFixed(0)
        : quantidade.toString().replaceAll('.', ',');
    return '$numero ${unidade.rotulo}';
  }

  /// RN12: o doador edita só enquanto ninguém aceitou.
  bool get podeSerEditada => estaDisponivel;

  /// RN12: pode cancelar enquanto disponível ou reservada (reservada pede
  /// motivo e avisa a ONG).
  bool get podeSerCancelada => status.ativa;

  /// Cancelar agora exige motivo? (RN12)
  bool get cancelamentoExigeMotivo => status == StatusDoacao.reservada;

  /// A janela de retirada já terminou em [agora]?
  bool janelaEncerrada(DateTime agora) => !janelaFim.isAfter(agora);

  /// Regra de negócio: uma ONG só aceita o que está disponível e com a
  /// janela de retirada ainda aberta.
  bool podeSerReservada(DateTime agora) =>
      estaDisponivel && !janelaEncerrada(agora);

  Map<String, dynamic> toJson() => {
    'id': id,
    'doadorId': doadorId,
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
    'status': status.name,
    'motivoCancelamento': motivoCancelamento,
    'criadoEm': formatarInstante(criadoEm),
    'fotos': fotos,
    if (nomeDoador != null) 'nomeDoador': nomeDoador,
    if (distanciaKm != null) 'distanciaKm': distanciaKm,
    if (nomeOng != null) 'nomeOng': nomeOng,
    if (prazoRetirada != null)
      'prazoRetirada': formatarInstante(prazoRetirada!),
  };

  /// Cópia com outro status, fotos ou campos de leitura.
  Doacao copyWith({
    StatusDoacao? status,
    String? motivoCancelamento,
    List<String>? fotos,
    String? nomeDoador,
    double? distanciaKm,
  }) => Doacao(
    id: id,
    doadorId: doadorId,
    titulo: titulo,
    descricao: descricao,
    categoria: categoria,
    quantidade: quantidade,
    unidade: unidade,
    pesoKg: pesoKg,
    conservacao: conservacao,
    veiculo: veiculo,
    validade: validade,
    preparadoEm: preparadoEm,
    janelaInicio: janelaInicio,
    janelaFim: janelaFim,
    endereco: endereco,
    latitude: latitude,
    longitude: longitude,
    status: status ?? this.status,
    motivoCancelamento: motivoCancelamento ?? this.motivoCancelamento,
    criadoEm: criadoEm,
    fotos: fotos ?? this.fotos,
    nomeDoador: nomeDoador ?? this.nomeDoador,
    distanciaKm: distanciaKm ?? this.distanciaKm,
    nomeOng: nomeOng,
    prazoRetirada: prazoRetirada,
  );

  @override
  String toString() =>
      'Doacao(id: $id, titulo: $titulo, status: ${status.name})';
}
