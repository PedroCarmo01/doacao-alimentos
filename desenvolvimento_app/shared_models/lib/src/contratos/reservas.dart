import '../util/json.dart';

/// Corpo de `POST /reservas`.
class DadosReserva {
  const DadosReserva({required this.doacaoId});

  factory DadosReserva.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Reserva');
    return DadosReserva(doacaoId: j.inteiro('doacaoId'));
  }

  final int doacaoId;

  Map<String, dynamic> toJson() => {'doacaoId': doacaoId};
}
