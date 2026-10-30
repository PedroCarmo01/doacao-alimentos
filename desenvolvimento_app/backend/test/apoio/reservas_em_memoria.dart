import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/reservas/reserva_repository.dart';

import 'doacoes_em_memoria.dart';
import 'em_memoria.dart';

/// [ReservaRepository] em memória. Usa as MESMAS listas do
/// [DoacoesEmMemoria] (doações, retiradas, bloqueios), como as tabelas do
/// banco são as mesmas para os dois repositórios MySQL.
class ReservasEmMemoria implements ReservaRepository {
  ReservasEmMemoria(this._doacoes, this._contas);

  final DoacoesEmMemoria _doacoes;
  final ContasEmMemoria _contas;

  /// Código e tentativas de cada retirada (colunas só do backend).
  final Map<int, ControleDoCodigo> controles = {};

  List<Reserva> get _lista => _doacoes.reservas;

  Reserva? _porId(int id) => _lista.where((r) => r.id == id).firstOrNull;

  void _trocar(Reserva nova) =>
      _lista[_lista.indexWhere((r) => r.id == nova.id)] = nova;

  void _mudarDoacao(int doacaoId, StatusDoacao status) {
    final doacao = _doacoes.doacoes.firstWhere((d) => d.id == doacaoId);
    _doacoes.doacoes[_doacoes.doacoes.indexOf(doacao)] = doacao.copyWith(
      status: status,
    );
  }

  @override
  Future<Reserva?> buscar(int reservaId) async => _porId(reservaId);

  @override
  Future<List<Reserva>> daOng(int ongId, SituacaoDaLista situacao) async {
    final querAtivas = situacao == SituacaoDaLista.ativas;
    return [
      for (final r in _lista.reversed)
        if (r.ongId == ongId && r.estaAtiva == querAtivas) r,
    ];
  }

  @override
  Future<Reserva?> criarSeDisponivel(NovaReserva nova) async {
    final doacao = await _doacoes.buscar(nova.doacaoId);
    if (doacao == null || !doacao.podeSerReservada(nova.reservadoEm)) {
      return null;
    }
    final reserva = Reserva(
      id: _lista.length + 1,
      doacaoId: nova.doacaoId,
      ongId: nova.ongId,
      status: StatusReserva.ativa,
      reservadoEm: nova.reservadoEm,
      expiraEm: nova.expiraEm,
      codigoRetirada: nova.codigo,
    );
    _lista.add(reserva);
    controles[reserva.id] = ControleDoCodigo(
      codigo: nova.codigo,
      tentativas: 0,
    );
    _mudarDoacao(nova.doacaoId, StatusDoacao.reservada);
    return reserva;
  }

  @override
  Future<bool> concluir(int reservaId, DateTime agora) async {
    final reserva = _porId(reservaId);
    if (reserva == null || !reserva.estaAtiva) return false;
    _trocar(
      reserva.copyWith(status: StatusReserva.concluida, encerradaEm: agora),
    );
    _mudarDoacao(reserva.doacaoId, StatusDoacao.concluida);
    return true;
  }

  @override
  Future<bool> encerrarDevolvendo(
    int reservaId, {
    required StatusReserva status,
    required DateTime agora,
    required bool contaDesistencia,
  }) async {
    final reserva = _porId(reservaId);
    if (reserva == null || !reserva.estaAtiva) return false;
    _trocar(
      reserva.copyWith(
        status: status,
        encerradaEm: agora,
        contouDesistencia: contaDesistencia,
      ),
    );
    _mudarDoacao(reserva.doacaoId, StatusDoacao.disponivel);
    if (contaDesistencia) {
      _doacoes.bloqueios.add('${reserva.ongId}-${reserva.doacaoId}');
    }
    return true;
  }

  @override
  Future<List<Reserva>> vencidas(DateTime agora) async => [
    for (final r in _lista)
      if (r.estaVencida(agora)) r,
  ];

  @override
  Future<int> desistenciasDesde(int ongId, DateTime desde) async => _lista
      .where(
        (r) =>
            r.ongId == ongId &&
            r.contouDesistencia &&
            !r.encerradaEm!.isBefore(desde),
      )
      .length;

  @override
  Future<void> suspender(int ongId, DateTime ate) async =>
      _contas.suspender(ongId, ate);

  @override
  Future<ControleDoCodigo?> controleDoCodigo(int reservaId) async =>
      controles[reservaId];

  @override
  Future<void> salvarTentativas(
    int reservaId, {
    required int tentativas,
    DateTime? bloqueadoAte,
  }) async {
    controles[reservaId] = ControleDoCodigo(
      codigo: controles[reservaId]!.codigo,
      tentativas: tentativas,
      bloqueadoAte: bloqueadoAte,
    );
  }
}
