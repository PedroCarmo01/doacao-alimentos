import 'dart:async';
import 'dart:io';

import 'documento_service.dart';

/// Tarefa automática da RN03: "API fora do ar → a conta fica pendente e o
/// servidor tenta de novo depois".
///
/// A cada [intervalo], pede ao [DocumentoService] para conferir de novo os
/// CNPJs pendentes. Ligada em `main.dart`, junto com o servidor.
class ReverificacaoJob {
  ReverificacaoJob(
    this._documentos, {
    this.intervalo = const Duration(minutes: 10),
  });

  final DocumentoService _documentos;
  final Duration intervalo;
  Timer? _timer;
  bool _rodando = false;

  void iniciar() {
    _timer ??= Timer.periodic(intervalo, (_) => _rodada());
  }

  void parar() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _rodada() async {
    // Se uma rodada demorar mais que o intervalo, não começa outra junto.
    if (_rodando) return;
    _rodando = true;
    try {
      final verificados = await _documentos.reverificarPendentes();
      if (verificados > 0) {
        stdout.writeln('[RN03] $verificados perfil(is) verificado(s).');
      }
    } catch (erro) {
      // Um erro numa rodada (ex.: banco fora do ar) não pode derrubar o
      // servidor: registra e tenta de novo na próxima.
      stderr.writeln('[RN03] Falha ao reverificar CNPJs: $erro');
    } finally {
      _rodando = false;
    }
  }
}
