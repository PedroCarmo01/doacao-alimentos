import 'dart:async';

import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../data/chat/chat_repository.dart';

/// ViewModel da aba Mensagens (T31). Também alimenta o número vermelho de
/// não lidas na barra inferior: por isso a casca cria UM e o compartilha.
class ConversasViewModel extends ViewModelBase {
  ConversasViewModel({required ChatRepository chat, required Relogio relogio})
    : _chat = chat,
      _relogio = relogio;

  final ChatRepository _chat;
  final Relogio _relogio;

  DateTime get agora => _relogio.agora();

  static const intervaloDeConsulta = Duration(seconds: 15);

  List<ResumoConversa> _conversas = const [];
  bool _carregou = false;
  Timer? _consulta;

  List<ResumoConversa> get conversas => _conversas;
  bool get carregou => _carregou;

  /// O número vermelho da aba Mensagens.
  int get totalNaoLidas {
    var total = 0;
    for (final conversa in _conversas) {
      total += conversa.naoLidas;
    }
    return total;
  }

  /// Primeira carga + consulta a cada 15 s (para o contador da barra).
  void iniciar() {
    _consulta ??= Timer.periodic(intervaloDeConsulta, (_) => atualizar());
    carregar();
  }

  Future<bool> carregar() => executar(() async {
    _conversas = await _chat.conversas();
    _carregou = true;
  });

  /// Consulta "em silêncio" (sem o carregando na tela).
  Future<void> atualizar() async {
    if (ocupado) return;
    try {
      _conversas = await _chat.conversas();
      _carregou = true;
      notificar();
    } catch (_) {
      // Sem internet por um instante: a próxima consulta resolve.
    }
  }

  @override
  void dispose() {
    _consulta?.cancel();
    super.dispose();
  }
}
