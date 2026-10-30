import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../fake/banco_fake.dart';

/// CONTRATO das reservas (ONG; a confirmação de retirada também pode ser
/// feita pelo doador dono da doação).
abstract interface class ReservaRepository {
  /// `POST /reservas` — falha com `DOACAO_INDISPONIVEL` (409) se outra ONG
  /// reservou antes.
  Future<Reserva> reservar(int doacaoId);

  /// `GET /reservas` — reservas da ONG logada (ativas e histórico).
  Future<List<Reserva>> listarMinhas();

  /// `DELETE /reservas/{id}` — a ONG desiste; a doação volta a ficar
  /// disponível.
  Future<void> cancelar(int reservaId);

  /// `POST /reservas/{id}/retirada`
  Future<Reserva> confirmarRetirada(int reservaId);
}

class ReservaRepositoryApi implements ReservaRepository {
  ReservaRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<Reserva> reservar(int doacaoId) async {
    final json = await _api.post(
      '/reservas',
      corpo: DadosReserva(doacaoId: doacaoId).toJson(),
    );
    return Reserva.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<List<Reserva>> listarMinhas() async {
    final json = await _api.get('/reservas');
    return [
      for (final item in ApiClient.lista(json, 'reservas'))
        Reserva.fromJson(item),
    ];
  }

  @override
  Future<void> cancelar(int reservaId) => _api.delete('/reservas/$reservaId');

  @override
  Future<Reserva> confirmarRetirada(int reservaId) async {
    final json = await _api.post('/reservas/$reservaId/retirada');
    return Reserva.fromJson(ApiClient.objeto(json));
  }
}

class ReservaRepositoryFake implements ReservaRepository {
  ReservaRepositoryFake(this._banco);

  final BancoFake _banco;

  @override
  Future<Reserva> reservar(int doacaoId) async {
    await _banco.simularRede();
    return _banco.reservar(doacaoId);
  }

  @override
  Future<List<Reserva>> listarMinhas() async {
    await _banco.simularRede();
    return _banco.reservasDaOngLogada();
  }

  @override
  Future<void> cancelar(int reservaId) async {
    await _banco.simularRede();
    _banco.cancelarReserva(reservaId);
  }

  @override
  Future<Reserva> confirmarRetirada(int reservaId) async {
    await _banco.simularRede();
    return _banco.confirmarRetirada(reservaId);
  }
}
