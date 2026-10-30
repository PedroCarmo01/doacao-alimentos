import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../data/reservas/reserva_repository.dart';

/// ViewModel de "Minhas retiradas" (ONG): as em andamento, o histórico e
/// a contagem de desistências (RN24).
class MinhasReservasViewModel extends ViewModelBase {
  MinhasReservasViewModel({
    required ReservaRepository reservas,
    required Relogio relogio,
  }) : _reservas = reservas,
       _relogio = relogio;

  final ReservaRepository _reservas;
  final Relogio _relogio;

  SituacaoDaOng? _situacao;
  List<Reserva> _historico = const [];

  DateTime get agora => _relogio.agora();

  /// Em andamento (com o código), vindas da situação da ONG.
  List<Reserva> get ativas => _situacao?.ativas ?? const [];
  List<Reserva> get historico => _historico;
  SituacaoDaOng? get situacao => _situacao;

  Future<bool> carregar() => executar(() async {
    _situacao = await _reservas.situacao();
    _historico = await _reservas.listarMinhas(SituacaoDaLista.historico);
  });
}
