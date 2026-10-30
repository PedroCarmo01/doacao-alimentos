import 'geo/geo.dart';
import 'util/json.dart';

/// Categoria do alimento doado.
enum CategoriaAlimento {
  hortifruti('Hortifrúti'),
  padaria('Padaria'),
  laticinios('Laticínios'),
  mercearia('Mercearia'),
  refeicoesProntas('Refeições prontas'),
  outros('Outros');

  const CategoriaAlimento(this.rotulo);

  final String rotulo;
}

/// Ciclo de vida de uma doação:
///
/// `disponivel` → `reservada` → `concluida` (ou `cancelada` pelo doador).
/// Quando uma reserva expira, a doação volta de `reservada` para `disponivel`.
enum StatusDoacao {
  disponivel('Disponível'),
  reservada('Reservada'),
  concluida('Concluída'),
  cancelada('Cancelada');

  const StatusDoacao(this.rotulo);

  final String rotulo;
}

/// Excedente de alimento anunciado por um doador.
///
/// Os campos [nomeDoador] e [distanciaKm] são "de leitura": o backend os
/// preenche em algumas consultas (ex.: lista de doações próximas da ONG).
class Doacao {
  const Doacao({
    required this.id,
    required this.doadorId,
    required this.titulo,
    required this.categoria,
    required this.quantidade,
    required this.validade,
    required this.janelaInicio,
    required this.janelaFim,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.criadoEm,
    this.descricao,
    this.endereco,
    this.nomeDoador,
    this.distanciaKm,
  });

  factory Doacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Doacao');
    return Doacao(
      id: j.inteiro('id'),
      doadorId: j.inteiro('doadorId'),
      titulo: j.texto('titulo'),
      descricao: j.textoOpcional('descricao'),
      categoria: j.enumerado('categoria', CategoriaAlimento.values),
      quantidade: j.texto('quantidade'),
      validade: j.data('validade'),
      janelaInicio: j.instante('janelaInicio'),
      janelaFim: j.instante('janelaFim'),
      endereco: j.textoOpcional('endereco'),
      latitude: j.decimal('latitude'),
      longitude: j.decimal('longitude'),
      status: j.enumerado('status', StatusDoacao.values),
      criadoEm: j.instante('criadoEm'),
      nomeDoador: j.textoOpcional('nomeDoador'),
      distanciaKm: j.decimalOpcional('distanciaKm'),
    );
  }

  final int id;
  final int doadorId;
  final String titulo;
  final String? descricao;
  final CategoriaAlimento categoria;

  /// Texto livre, por exemplo "5 caixas" ou "30 pães".
  final String quantidade;

  /// Data de validade (somente o dia).
  final DateTime validade;

  /// Período em que a ONG pode retirar (instantes em UTC).
  final DateTime janelaInicio;
  final DateTime janelaFim;

  final String? endereco;
  final double latitude;
  final double longitude;
  final StatusDoacao status;
  final DateTime criadoEm;
  final String? nomeDoador;
  final double? distanciaKm;

  Coordenadas get coordenadas => Coordenadas(latitude, longitude);

  bool get estaDisponivel => status == StatusDoacao.disponivel;

  /// O doador só pode cancelar enquanto ninguém reservou.
  bool get podeSerCancelada => estaDisponivel;

  /// A janela de retirada já terminou em [agora]?
  bool janelaEncerrada(DateTime agora) => !janelaFim.isAfter(agora);

  /// Regra de negócio: uma ONG só reserva o que está disponível e com a
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
    'validade': formatarData(validade),
    'janelaInicio': formatarInstante(janelaInicio),
    'janelaFim': formatarInstante(janelaFim),
    'endereco': endereco,
    'latitude': latitude,
    'longitude': longitude,
    'status': status.name,
    'criadoEm': formatarInstante(criadoEm),
    if (nomeDoador != null) 'nomeDoador': nomeDoador,
    if (distanciaKm != null) 'distanciaKm': distanciaKm,
  };

  Doacao copyWith({
    StatusDoacao? status,
    String? nomeDoador,
    double? distanciaKm,
  }) {
    return Doacao(
      id: id,
      doadorId: doadorId,
      titulo: titulo,
      descricao: descricao,
      categoria: categoria,
      quantidade: quantidade,
      validade: validade,
      janelaInicio: janelaInicio,
      janelaFim: janelaFim,
      endereco: endereco,
      latitude: latitude,
      longitude: longitude,
      status: status ?? this.status,
      criadoEm: criadoEm,
      nomeDoador: nomeDoador ?? this.nomeDoador,
      distanciaKm: distanciaKm ?? this.distanciaKm,
    );
  }

  @override
  String toString() =>
      'Doacao(id: $id, titulo: $titulo, status: ${status.name})';
}
