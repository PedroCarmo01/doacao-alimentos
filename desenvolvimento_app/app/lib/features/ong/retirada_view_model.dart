import 'dart:async';

import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/reservas/reserva_repository.dart';

/// ViewModel da retirada em andamento da ONG (T23): contador, código,
/// endereço e desistência (RN22–RN24, RN26).
///
/// Dois "despertadores" ([Timer]):
/// - a cada 1 s, só redesenha o contador regressivo;
/// - a cada 15 s, pergunta ao servidor se a retirada mudou (o doador
///   digitou o código, ou o prazo acabou).
class RetiradaViewModel extends ViewModelBase {
  RetiradaViewModel({
    required ReservaRepository reservas,
    required DoacaoRepository doacoes,
    required Relogio relogio,
    required this.reservaId,
  }) : _reservas = reservas,
       _doacoes = doacoes,
       _relogio = relogio;

  final ReservaRepository _reservas;
  final DoacaoRepository _doacoes;
  final Relogio _relogio;
  final int reservaId;

  static const intervaloDeConsulta = Duration(seconds: 15);

  Reserva? _reserva;
  DetalheDoacao? _detalhe;
  RegrasDaRetirada _regras = const RegrasDaRetirada();
  RespostaDesistencia? _desistencia;
  Timer? _segundos;
  Timer? _consulta;

  Reserva? get reserva => _reserva;

  /// A doação e o doador (só enquanto a retirada está em andamento).
  DetalheDoacao? get detalhe => _detalhe;

  /// O resultado, se a ONG desistiu nesta tela.
  RespostaDesistencia? get desistencia => _desistencia;

  DateTime get agora => _relogio.agora();

  Duration get restante => _reserva?.tempoRestante(agora) ?? Duration.zero;

  /// RN23: desistir agora ainda não conta?
  bool get dentroDaTolerancia =>
      _reserva?.dentroDaTolerancia(agora, _regras.tolerancia) ?? false;

  /// O que o diálogo de desistência explica (RN22–RN24).
  String get avisoDaDesistencia => dentroDaTolerancia
      ? 'Você aceitou há pouco (menos de ${_regras.tolerancia.inMinutes} '
            'min): desistir agora NÃO conta como desistência.'
      : 'A doação volta para outras ONGs, você não poderá aceitá-la de novo '
            'e isso conta como desistência. '
            '${_regras.desistenciasParaSuspender} desistências em '
            '${_regras.janelaDesistencias.inDays} dias suspendem sua conta '
            'por ${_regras.suspensao.inHours} h.';

  Future<bool> carregar() => executar(_buscar);

  /// Liga os dois despertadores. A tela chama uma vez, no `initState`.
  void iniciarContadores() {
    _segundos ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => notificar(),
    );
    _consulta ??= Timer.periodic(intervaloDeConsulta, (_) => atualizar());
  }

  /// Consulta "em silêncio" (sem o carregando na tela). Se a rede falhar,
  /// tenta de novo na próxima vez.
  Future<void> atualizar() async {
    if (ocupado || !(_reserva?.estaAtiva ?? false)) return;
    try {
      await _buscar();
      notificar();
    } catch (_) {
      // Sem internet por um instante: a próxima consulta resolve.
    }
  }

  /// A ONG desiste (com confirmação na tela).
  Future<bool> desistir() => executar(() async {
    _desistencia = await _reservas.desistir(reservaId);
    await _buscar();
  });

  Future<void> _buscar() async {
    final reserva = await _reservas.buscar(reservaId);
    _reserva = reserva;
    if (_detalhe == null) _regras = (await _reservas.situacao()).regras;
    // O detalhe da doação só existe para a ONG enquanto a retirada é dela.
    if (reserva.estaAtiva && _detalhe == null) {
      _detalhe = await _doacoes.detalhar(reserva.doacaoId);
    }
  }

  @override
  void dispose() {
    _segundos?.cancel();
    _consulta?.cancel();
    super.dispose();
  }
}
