import 'util/json.dart';

/// Ciclo de vida de uma retirada (reserva):
///
/// `ativa` → `concluida` (código confirmado), `expirada` (prazo acabou),
/// `canceladaOng` (a ONG desistiu) ou `canceladaDoador` (o doador cancelou
/// a doação, RN12).
enum StatusReserva {
  ativa('Em andamento'),
  concluida('Retirada'),
  expirada('Expirada'),
  canceladaOng('A ONG desistiu'),
  canceladaDoador('Cancelada pelo doador');

  const StatusReserva(this.rotulo);

  final String rotulo;
}

/// Uma ONG aceitou uma doação e tem um prazo para retirar.
///
/// [tituloDoacao] e [nomeOng] são campos de leitura que o backend preenche
/// para facilitar a exibição nas listas. [codigoRetirada] só vai para a
/// ONG dona da reserva (RN26).
class Reserva {
  const Reserva({
    required this.id,
    required this.doacaoId,
    required this.ongId,
    required this.status,
    required this.reservadoEm,
    required this.expiraEm,
    this.encerradaEm,
    this.codigoRetirada,
    this.motivo,
    this.contouDesistencia = false,
    this.tituloDoacao,
    this.nomeOng,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Reserva');
    return Reserva(
      id: j.inteiro('id'),
      doacaoId: j.inteiro('doacaoId'),
      ongId: j.inteiro('ongId'),
      status: j.enumerado('status', StatusReserva.values),
      reservadoEm: j.instante('reservadoEm'),
      expiraEm: j.instante('expiraEm'),
      encerradaEm: j.instanteOpcional('encerradaEm'),
      codigoRetirada: j.textoOpcional('codigoRetirada'),
      motivo: j.textoOpcional('motivo'),
      contouDesistencia: json['contouDesistencia'] == true,
      tituloDoacao: j.textoOpcional('tituloDoacao'),
      nomeOng: j.textoOpcional('nomeOng'),
    );
  }

  final int id;
  final int doacaoId;
  final int ongId;
  final StatusReserva status;
  final DateTime reservadoEm;
  final DateTime expiraEm;

  /// Quando deixou de estar ativa (retirada, expirada ou cancelada).
  final DateTime? encerradaEm;
  final String? codigoRetirada;
  final String? motivo;

  /// RN22–RN24: esta retirada contou como desistência da ONG (expirou ou
  /// ela desistiu depois da tolerância)?
  final bool contouDesistencia;
  final String? tituloDoacao;
  final String? nomeOng;

  bool get estaAtiva => status == StatusReserva.ativa;

  /// Quanto falta para expirar em [agora]. Nunca é negativo.
  Duration tempoRestante(DateTime agora) {
    final restante = expiraEm.difference(agora);
    return restante.isNegative ? Duration.zero : restante;
  }

  /// Ainda está "ativa" no banco, mas o prazo já passou
  /// (o job de expiração ainda não rodou).
  bool estaVencida(DateTime agora) => estaAtiva && !expiraEm.isAfter(agora);

  /// RN23: desistir agora ainda está dentro da [tolerancia] (toque errado)?
  bool dentroDaTolerancia(DateTime agora, Duration tolerancia) =>
      !agora.isAfter(reservadoEm.add(tolerancia));

  /// Cópia com outro status (e os dados de quando ela foi encerrada).
  Reserva copyWith({
    StatusReserva? status,
    DateTime? encerradaEm,
    String? motivo,
    bool? contouDesistencia,
  }) => Reserva(
    id: id,
    doacaoId: doacaoId,
    ongId: ongId,
    status: status ?? this.status,
    reservadoEm: reservadoEm,
    expiraEm: expiraEm,
    encerradaEm: encerradaEm ?? this.encerradaEm,
    codigoRetirada: codigoRetirada,
    motivo: motivo ?? this.motivo,
    contouDesistencia: contouDesistencia ?? this.contouDesistencia,
    tituloDoacao: tituloDoacao,
    nomeOng: nomeOng,
  );

  /// RN26: o código é só da ONG. Antes de mandar a reserva para o doador,
  /// o servidor usa esta cópia sem o código.
  Reserva semCodigo() => Reserva(
    id: id,
    doacaoId: doacaoId,
    ongId: ongId,
    status: status,
    reservadoEm: reservadoEm,
    expiraEm: expiraEm,
    encerradaEm: encerradaEm,
    motivo: motivo,
    contouDesistencia: contouDesistencia,
    tituloDoacao: tituloDoacao,
    nomeOng: nomeOng,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'doacaoId': doacaoId,
    'ongId': ongId,
    'status': status.name,
    'reservadoEm': formatarInstante(reservadoEm),
    'expiraEm': formatarInstante(expiraEm),
    'encerradaEm': encerradaEm == null ? null : formatarInstante(encerradaEm!),
    if (codigoRetirada != null) 'codigoRetirada': codigoRetirada,
    if (motivo != null) 'motivo': motivo,
    'contouDesistencia': contouDesistencia,
    if (tituloDoacao != null) 'tituloDoacao': tituloDoacao,
    if (nomeOng != null) 'nomeOng': nomeOng,
  };

  @override
  String toString() =>
      'Reserva(id: $id, doacaoId: $doacaoId, status: ${status.name})';
}
