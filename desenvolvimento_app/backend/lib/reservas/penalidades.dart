import 'package:shared_models/shared_models.dart';

import '../auth/usuario_repository.dart';
import 'reserva_repository.dart';

/// O que acontece quando uma retirada termina SEM a ONG buscar a comida
/// (RN22–RN24): a doação volta para as outras ONGs, a desistência conta (se
/// passou da tolerância) e, com desistências demais, a ONG é suspensa.
///
/// Usada em três lugares: a ONG desistiu, o prazo acabou (job) e "A ONG não
/// compareceu" (doador). Por isso fica numa classe só dela.
class Penalidades {
  Penalidades({
    required ReservaRepository reservas,
    required UsuarioRepository usuarios,
    required RegrasDaRetirada regras,
  }) : _reservas = reservas,
       _usuarios = usuarios,
       _regras = regras;

  final ReservaRepository _reservas;
  final UsuarioRepository _usuarios;
  final RegrasDaRetirada _regras;

  /// Encerra a [reserva] e devolve a doação. `null` se ela já não estava
  /// mais ativa.
  Future<RespostaDesistencia?> encerrar(
    Reserva reserva, {
    required StatusReserva status,
    required DateTime agora,
    required bool contaDesistencia,
  }) async {
    final encerrou = await _reservas.encerrarDevolvendo(
      reserva.id,
      status: status,
      agora: agora,
      contaDesistencia: contaDesistencia,
    );
    if (!encerrou) return null;
    final total = await desistenciasRecentes(reserva.ongId, agora);
    return RespostaDesistencia(
      contouDesistencia: contaDesistencia,
      desistenciasRecentes: total,
      suspensaAte: contaDesistencia
          ? await _suspenderSePreciso(reserva.ongId, total, agora)
          : null,
    );
  }

  /// RN24: desistências que contam, dentro da janela (30 dias).
  Future<int> desistenciasRecentes(int ongId, DateTime agora) => _reservas
      .desistenciasDesde(ongId, agora.subtract(_regras.janelaDesistencias));

  /// RN24: a partir da 3ª desistência, suspende por 48 h. Se já estiver
  /// suspensa, não estende.
  Future<DateTime?> _suspenderSePreciso(
    int ongId,
    int desistencias,
    DateTime agora,
  ) async {
    if (desistencias < _regras.desistenciasParaSuspender) return null;
    final perfil = (await _usuarios.buscarConta(ongId))?.perfil;
    if (perfil == null || perfil.estaSuspensa(agora)) return null;
    final ate = agora.add(_regras.suspensao);
    await _reservas.suspender(ongId, ate);
    return ate;
  }
}
