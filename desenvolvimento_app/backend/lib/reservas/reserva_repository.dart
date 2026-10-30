import 'package:shared_models/shared_models.dart';

/// Dados de uma retirada nova, já calculados pelo `ReservaService`.
class NovaReserva {
  const NovaReserva({
    required this.doacaoId,
    required this.ongId,
    required this.codigo,
    required this.reservadoEm,
    required this.expiraEm,
  });

  final int doacaoId;
  final int ongId;

  /// RN26: 4 dígitos, só a ONG vê.
  final String codigo;
  final DateTime reservadoEm;
  final DateTime expiraEm;
}

/// O que o servidor precisa para conferir o código (RN27). Fica só no
/// backend: o app nunca recebe as tentativas.
class ControleDoCodigo {
  const ControleDoCodigo({
    required this.codigo,
    required this.tentativas,
    this.bloqueadoAte,
  });

  final String codigo;

  /// Erros seguidos até agora.
  final int tentativas;

  /// Até quando novas tentativas estão bloqueadas (UTC).
  final DateTime? bloqueadoAte;
}

/// CONTRATO de acesso às retiradas (tabela `reservas`), aos bloqueios
/// (RN22) e à suspensão da ONG (RN24).
///
/// Os métodos que mudam o status devolvem `false`/`null` quando a retirada
/// já não estava mais ativa (outra requisição ou o job chegou antes).
abstract interface class ReservaRepository {
  /// A retirada com o título da doação, o nome da ONG e o código.
  Future<Reserva?> buscar(int reservaId);

  /// Retiradas da ONG, das mais novas para as mais antigas.
  Future<List<Reserva>> daOng(int ongId, SituacaoDaLista situacao);

  /// RN20: em UMA transação, confere (com trava) que a doação continua
  /// disponível, muda a doação para `reservada` e grava a retirada.
  /// Devolve `null` se outra ONG aceitou antes.
  Future<Reserva?> criarSeDisponivel(NovaReserva nova);

  /// RN27: retirada e doação ficam `concluida`.
  Future<bool> concluir(int reservaId, DateTime agora);

  /// RN22: a retirada termina com [status] (`expirada` ou `canceladaOng`)
  /// e a doação volta a ficar disponível. Se [contaDesistencia], a ONG
  /// também fica bloqueada para esta doação.
  Future<bool> encerrarDevolvendo(
    int reservaId, {
    required StatusReserva status,
    required DateTime agora,
    required bool contaDesistencia,
  });

  /// RN29: retiradas ativas cujo prazo já passou em [agora].
  Future<List<Reserva>> vencidas(DateTime agora);

  /// RN24: quantas desistências da ONG contam desde [desde].
  Future<int> desistenciasDesde(int ongId, DateTime desde);

  /// RN24: suspende a ONG até [ate].
  Future<void> suspender(int ongId, DateTime ate);

  Future<ControleDoCodigo?> controleDoCodigo(int reservaId);

  /// RN27: guarda os erros seguidos e o bloqueio das tentativas.
  Future<void> salvarTentativas(
    int reservaId, {
    required int tentativas,
    DateTime? bloqueadoAte,
  });
}
