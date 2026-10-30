import 'doacao.dart';
import 'reserva.dart';
import 'util/json.dart';

/// Resposta de `GET /doacoes/{id}`: a doação e, se existir, a reserva ativa.
///
/// O doador usa a reserva para saber qual ONG vem buscar e até quando.
class DetalheDoacao {
  const DetalheDoacao({required this.doacao, this.reserva});

  factory DetalheDoacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'DetalheDoacao');
    final reserva = j.objetoOpcional('reserva');
    return DetalheDoacao(
      doacao: Doacao.fromJson(j.objeto('doacao').mapa),
      reserva: reserva == null ? null : Reserva.fromJson(reserva.mapa),
    );
  }

  final Doacao doacao;
  final Reserva? reserva;

  Map<String, dynamic> toJson() => {
    'doacao': doacao.toJson(),
    'reserva': reserva?.toJson(),
  };
}
