import 'dart:async';
import 'dart:io';

import '../doacoes/doacao_service.dart';
import 'reserva_service.dart';

/// Tarefa automática da RN29 (e da RN13): a cada [intervalo], expira as
/// retiradas com o prazo vencido (a doação volta para as outras ONGs), as
/// doações cujo horário de retirada acabou e avisa "faltam 10 minutos".
///
/// O MySQL não "avisa" quando um horário passa: alguém precisa perguntar de
/// tempos em tempos. Ligada UMA vez em `main.dart`.
class ExpiracaoJob {
  ExpiracaoJob({
    required ReservaService reservas,
    required DoacaoService doacoes,
    this.intervalo = const Duration(seconds: 30),
  }) : _reservas = reservas,
       _doacoes = doacoes;

  final ReservaService _reservas;
  final DoacaoService _doacoes;
  final Duration intervalo;
  Timer? _timer;
  bool _rodando = false;

  void iniciar() {
    _timer ??= Timer.periodic(intervalo, (_) => rodada());
  }

  void parar() {
    _timer?.cancel();
    _timer = null;
  }

  /// Uma rodada. Pública para os testes chamarem sem esperar o timer.
  Future<void> rodada() async {
    // Se uma rodada demorar mais que o intervalo, não começa outra junto.
    if (_rodando) return;
    _rodando = true;
    try {
      // Primeiro as retiradas (a doação volta a "disponível")...
      final expiradas = await _reservas.expirarVencidas();
      // ...depois as doações cujo horário acabou (aí viram "expirada").
      final doacoes = await _doacoes.expirarJanelasEncerradas();
      // ...e lembra as ONGs com o prazo perto do fim.
      await _reservas.avisarPrazosAcabando();
      if (expiradas.isNotEmpty || doacoes > 0) {
        stdout.writeln(
          '[RN29] ${expiradas.length} retirada(s) e $doacoes doação(ões) '
          'expiraram.',
        );
      }
    } catch (erro) {
      // Um erro numa rodada (ex.: banco fora do ar) não pode derrubar o
      // servidor: registra e tenta de novo na próxima.
      stderr.writeln('[RN29] Falha ao expirar retiradas: $erro');
    } finally {
      _rodando = false;
    }
  }
}
