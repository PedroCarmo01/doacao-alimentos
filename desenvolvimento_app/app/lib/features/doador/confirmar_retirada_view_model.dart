import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../data/reservas/reserva_repository.dart';

/// ViewModel da T13: o doador digita o código que aparece no celular da
/// ONG (RN27).
class ConfirmarRetiradaViewModel extends ViewModelBase {
  ConfirmarRetiradaViewModel({
    required ReservaRepository reservas,
    required this.reservaId,
  }) : _reservas = reservas;

  final ReservaRepository _reservas;
  final int reservaId;

  bool _confirmada = false;

  /// `true` depois que o código certo foi aceito.
  bool get confirmada => _confirmada;

  /// Confere o formato aqui (resposta na hora) e o código no servidor
  /// (só ele sabe o código certo).
  Future<bool> confirmar(String codigo) async {
    final erro = ValidadorReserva.codigo(codigo);
    if (erro != null) {
      definirErro(erro);
      return false;
    }
    return executar(() async {
      await _reservas.confirmar(reservaId, codigo.trim());
      _confirmada = true;
    });
  }
}
