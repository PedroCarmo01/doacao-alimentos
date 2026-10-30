import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/reservas/reserva_repository.dart';

/// ViewModel do detalhe da doação, lado do doador (T12).
class DetalheDoacaoDoadorViewModel extends ViewModelBase {
  DetalheDoacaoDoadorViewModel({
    required DoacaoRepository doacoes,
    required ReservaRepository reservas,
    required Relogio relogio,
    required this.doacaoId,
  }) : _doacoes = doacoes,
       _reservas = reservas,
       _relogio = relogio;

  final DoacaoRepository _doacoes;
  final ReservaRepository _reservas;
  final Relogio _relogio;
  final int doacaoId;

  DetalheDoacao? _detalhe;
  bool _mudou = false;

  DetalheDoacao? get detalhe => _detalhe;
  Doacao? get doacao => _detalhe?.doacao;
  DateTime get agora => _relogio.agora();

  /// `true` se a doação foi cancelada aqui (a lista precisa recarregar).
  bool get mudou => _mudou;

  /// RN28: o prazo da retirada acabou e a ONG não veio (o servidor ainda
  /// não expirou sozinho). Mostra o "A ONG não compareceu".
  bool get podeMarcarNaoCompareceu =>
      _detalhe?.reserva?.estaVencida(agora) ?? false;

  Future<bool> carregar() => executar(_buscar);

  /// RN12: [motivo] é obrigatório se a doação já estiver reservada (o
  /// servidor confere). A ONG não é penalizada.
  Future<bool> cancelar({String? motivo}) => executar(() async {
    await _doacoes.cancelar(doacaoId, motivo: motivo);
    _mudou = true;
    await _buscar(); // não usa executar() de novo dentro de executar()
  });

  /// RN28: mesmo efeito da expiração: a doação volta para outras ONGs.
  Future<bool> marcarNaoCompareceu() => executar(() async {
    await _reservas.naoCompareceu(_detalhe!.reserva!.id);
    _mudou = true;
    await _buscar();
  });

  Future<void> _buscar() async {
    _detalhe = await _doacoes.detalhar(doacaoId);
  }
}
