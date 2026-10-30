import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../fake/banco_fake.dart';

/// CONTRATO das retiradas (reservas). A ONG aceita, acompanha e desiste; o
/// doador confirma com o código ou marca "A ONG não compareceu".
abstract interface class ReservaRepository {
  /// `POST /reservas` — "Vou retirar". Erros: `DOACAO_INDISPONIVEL`,
  /// `ONG_SUSPENSA`, `ONG_BLOQUEADA_NESTA_DOACAO`, `LIMITE_DE_RETIRADAS`.
  Future<Reserva> aceitar(int doacaoId);

  /// `GET /reservas?situacao=` — retiradas da ONG logada.
  Future<List<Reserva>> listarMinhas(SituacaoDaLista situacao);

  /// `GET /reservas/{id}` — uma retirada da ONG logada (com o código).
  Future<Reserva> buscar(int reservaId);

  /// `GET /reservas/situacao-da-ong` — desistências, suspensão, retiradas
  /// em andamento e os números das regras.
  Future<SituacaoDaOng> situacao();

  /// `DELETE /reservas/{id}` — a ONG desiste (RN22–RN24).
  Future<RespostaDesistencia> desistir(int reservaId);

  /// `POST /reservas/{id}/confirmar` — o doador digita o código (RN27).
  Future<Reserva> confirmar(int reservaId, String codigo);

  /// `POST /reservas/{id}/nao-compareceu` — RN28 (doador, depois do prazo).
  Future<void> naoCompareceu(int reservaId);
}

class ReservaRepositoryApi implements ReservaRepository {
  ReservaRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<Reserva> aceitar(int doacaoId) async {
    final json = await _api.post(
      '/reservas',
      corpo: DadosReserva(doacaoId: doacaoId).toJson(),
    );
    return Reserva.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<List<Reserva>> listarMinhas(SituacaoDaLista situacao) async {
    final json = await _api.get(
      '/reservas',
      consulta: {'situacao': situacao.name},
    );
    return [
      for (final item in ApiClient.lista(json, 'reservas'))
        Reserva.fromJson(item),
    ];
  }

  @override
  Future<Reserva> buscar(int reservaId) async {
    final json = await _api.get('/reservas/$reservaId');
    return Reserva.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<SituacaoDaOng> situacao() async {
    final json = await _api.get('/reservas/situacao-da-ong');
    return SituacaoDaOng.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<RespostaDesistencia> desistir(int reservaId) async {
    final json = await _api.delete('/reservas/$reservaId');
    return RespostaDesistencia.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<Reserva> confirmar(int reservaId, String codigo) async {
    final json = await _api.post(
      '/reservas/$reservaId/confirmar',
      corpo: DadosConfirmacao(codigo: codigo).toJson(),
    );
    return Reserva.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<void> naoCompareceu(int reservaId) =>
      _api.post('/reservas/$reservaId/nao-compareceu');
}

class ReservaRepositoryFake implements ReservaRepository {
  ReservaRepositoryFake(this._banco);

  final BancoFake _banco;

  @override
  Future<Reserva> aceitar(int doacaoId) async {
    await _banco.simularRede();
    return _banco.retiradas.aceitar(_banco.ongLogada(), doacaoId);
  }

  @override
  Future<List<Reserva>> listarMinhas(SituacaoDaLista situacao) async {
    await _banco.simularRede();
    return _banco.retiradas.daOng(_banco.ongLogada(), situacao);
  }

  @override
  Future<Reserva> buscar(int reservaId) async {
    await _banco.simularRede();
    return _banco.retiradas.daOngPorId(_banco.ongLogada(), reservaId);
  }

  @override
  Future<SituacaoDaOng> situacao() async {
    await _banco.simularRede();
    return _banco.retiradas.situacao(_banco.ongLogada());
  }

  @override
  Future<RespostaDesistencia> desistir(int reservaId) async {
    await _banco.simularRede();
    return _banco.retiradas.desistir(_banco.ongLogada(), reservaId);
  }

  @override
  Future<Reserva> confirmar(int reservaId, String codigo) async {
    await _banco.simularRede();
    return _banco.retiradas.confirmar(_banco.doadorLogado(), reservaId, codigo);
  }

  @override
  Future<void> naoCompareceu(int reservaId) async {
    await _banco.simularRede();
    _banco.retiradas.naoCompareceu(_banco.doadorLogado(), reservaId);
  }
}
