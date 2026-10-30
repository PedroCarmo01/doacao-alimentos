import 'util/json.dart';

/// Ciclo de vida de uma reserva:
///
/// `ativa` → `concluida` (retirada feita), `expirada` (prazo acabou) ou
/// `cancelada` (a ONG desistiu).
enum StatusReserva {
  ativa('Ativa'),
  concluida('Retirada'),
  expirada('Expirada'),
  cancelada('Cancelada');

  const StatusReserva(this.rotulo);

  final String rotulo;
}

/// Reserva de uma doação por uma ONG, com prazo para retirada.
///
/// [tituloDoacao] e [nomeOng] são campos de leitura que o backend preenche
/// para facilitar a exibição nas listas.
class Reserva {
  const Reserva({
    required this.id,
    required this.doacaoId,
    required this.ongId,
    required this.status,
    required this.reservadoEm,
    required this.expiraEm,
    this.retiradoEm,
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
      retiradoEm: j.instanteOpcional('retiradoEm'),
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
  final DateTime? retiradoEm;
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'doacaoId': doacaoId,
    'ongId': ongId,
    'status': status.name,
    'reservadoEm': formatarInstante(reservadoEm),
    'expiraEm': formatarInstante(expiraEm),
    'retiradoEm': retiradoEm == null ? null : formatarInstante(retiradoEm!),
    if (tituloDoacao != null) 'tituloDoacao': tituloDoacao,
    if (nomeOng != null) 'nomeOng': nomeOng,
  };

  @override
  String toString() =>
      'Reserva(id: $id, doacaoId: $doacaoId, status: ${status.name})';
}
