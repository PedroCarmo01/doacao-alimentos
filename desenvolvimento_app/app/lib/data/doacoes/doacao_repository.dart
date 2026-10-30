import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../fake/banco_fake.dart';

/// CONTRATO das doações (lado do doador e busca da ONG).
abstract interface class DoacaoRepository {
  /// `POST /doacoes` (doador)
  Future<Doacao> criar(DadosNovaDoacao dados);

  /// `GET /doacoes` — doações do doador logado (todos os status).
  Future<List<Doacao>> listarMinhas();

  /// `GET /doacoes/{id}` — doação + reserva ativa (se houver).
  Future<DetalheDoacao> detalhar(int doacaoId);

  /// `DELETE /doacoes/{id}` — só enquanto estiver disponível.
  Future<void> cancelar(int doacaoId);

  /// `GET /proximas?raioKm=` — disponíveis perto da ONG logada, ordenadas
  /// pela distância.
  Future<List<Doacao>> listarProximas({double? raioKm});
}

class DoacaoRepositoryApi implements DoacaoRepository {
  DoacaoRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<Doacao> criar(DadosNovaDoacao dados) async {
    final json = await _api.post('/doacoes', corpo: dados.toJson());
    return Doacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<List<Doacao>> listarMinhas() async {
    final json = await _api.get('/doacoes');
    return [
      for (final item in ApiClient.lista(json, 'doacoes')) Doacao.fromJson(item),
    ];
  }

  @override
  Future<DetalheDoacao> detalhar(int doacaoId) async {
    final json = await _api.get('/doacoes/$doacaoId');
    return DetalheDoacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<void> cancelar(int doacaoId) => _api.delete('/doacoes/$doacaoId');

  @override
  Future<List<Doacao>> listarProximas({double? raioKm}) async {
    final json = await _api.get(
      '/proximas',
      consulta: {if (raioKm != null) 'raioKm': '$raioKm'},
    );
    return [
      for (final item in ApiClient.lista(json, 'doacoes')) Doacao.fromJson(item),
    ];
  }
}

class DoacaoRepositoryFake implements DoacaoRepository {
  DoacaoRepositoryFake(this._banco);

  final BancoFake _banco;

  @override
  Future<Doacao> criar(DadosNovaDoacao dados) async {
    await _banco.simularRede();
    return _banco.criarDoacao(dados);
  }

  @override
  Future<List<Doacao>> listarMinhas() async {
    await _banco.simularRede();
    return _banco.doacoesDoDoadorLogado();
  }

  @override
  Future<DetalheDoacao> detalhar(int doacaoId) async {
    await _banco.simularRede();
    return _banco.detalharDoacao(doacaoId);
  }

  @override
  Future<void> cancelar(int doacaoId) async {
    await _banco.simularRede();
    _banco.cancelarDoacao(doacaoId);
  }

  @override
  Future<List<Doacao>> listarProximas({double? raioKm}) async {
    await _banco.simularRede();
    return _banco.doacoesProximas(raioKm: raioKm);
  }
}
