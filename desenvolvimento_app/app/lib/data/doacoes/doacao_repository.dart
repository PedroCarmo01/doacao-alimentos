import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../fake/banco_fake.dart';
import '../fotos/seletor_de_fotos.dart';

/// CONTRATO das doações (lado do doador e busca da ONG).
abstract interface class DoacaoRepository {
  /// `POST /doacoes` (doador) — RN10. Devolve a doação e quantas ONGs
  /// próximas foram avisadas.
  Future<RespostaPublicacao> publicar(DadosNovaDoacao dados);

  /// `PUT /doacoes/{id}` — só enquanto disponível (RN12).
  Future<Doacao> editar(int doacaoId, DadosNovaDoacao dados);

  /// `POST /doacoes/{id}/fotos` — uma foto por vez (até 3).
  Future<Doacao> enviarFoto(int doacaoId, FotoEscolhida foto);

  /// `GET /doacoes?situacao=` — doações do doador logado (T10).
  Future<List<Doacao>> listarMinhas(SituacaoDaLista situacao);

  /// `GET /doacoes/{id}` — doação + retirada em andamento (se houver).
  Future<DetalheDoacao> detalhar(int doacaoId);

  /// `DELETE /doacoes/{id}` — RN12: [motivo] obrigatório se reservada.
  Future<void> cancelar(int doacaoId, {String? motivo});

  /// `GET /proximas?raioKm=` — disponíveis perto da ONG logada, ordenadas
  /// pela distância (etapa 3).
  Future<List<Doacao>> listarProximas({double? raioKm});
}

class DoacaoRepositoryApi implements DoacaoRepository {
  DoacaoRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<RespostaPublicacao> publicar(DadosNovaDoacao dados) async {
    final json = await _api.post('/doacoes', corpo: dados.toJson());
    return RespostaPublicacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<Doacao> editar(int doacaoId, DadosNovaDoacao dados) async {
    final json = await _api.put('/doacoes/$doacaoId', corpo: dados.toJson());
    return Doacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<Doacao> enviarFoto(int doacaoId, FotoEscolhida foto) async {
    final json = await _api.enviarArquivo(
      '/doacoes/$doacaoId/fotos',
      campo: 'foto',
      bytes: foto.bytes,
      nomeArquivo: foto.nome,
    );
    return Doacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<List<Doacao>> listarMinhas(SituacaoDaLista situacao) async {
    final json = await _api.get(
      '/doacoes',
      consulta: {'situacao': situacao.name},
    );
    return [
      for (final item in ApiClient.lista(json, 'doacoes'))
        Doacao.fromJson(item),
    ];
  }

  @override
  Future<DetalheDoacao> detalhar(int doacaoId) async {
    final json = await _api.get('/doacoes/$doacaoId');
    return DetalheDoacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<void> cancelar(int doacaoId, {String? motivo}) => _api.delete(
    '/doacoes/$doacaoId',
    corpo: motivo == null ? null : DadosCancelamento(motivo: motivo).toJson(),
  );

  @override
  Future<List<Doacao>> listarProximas({double? raioKm}) async {
    final json = await _api.get(
      '/proximas',
      consulta: {if (raioKm != null) 'raioKm': '$raioKm'},
    );
    return [
      for (final item in ApiClient.lista(json, 'doacoes'))
        Doacao.fromJson(item),
    ];
  }
}

class DoacaoRepositoryFake implements DoacaoRepository {
  DoacaoRepositoryFake(this._banco);

  final BancoFake _banco;

  @override
  Future<RespostaPublicacao> publicar(DadosNovaDoacao dados) async {
    await _banco.simularRede();
    return _banco.publicarDoacao(dados);
  }

  @override
  Future<Doacao> editar(int doacaoId, DadosNovaDoacao dados) async {
    await _banco.simularRede();
    return _banco.editarDoacao(doacaoId, dados);
  }

  @override
  Future<Doacao> enviarFoto(int doacaoId, FotoEscolhida foto) async {
    await _banco.simularRede();
    // No modo Fake a foto não sai do celular: guardamos o caminho dela.
    return _banco.adicionarFoto(doacaoId, foto.caminho);
  }

  @override
  Future<List<Doacao>> listarMinhas(SituacaoDaLista situacao) async {
    await _banco.simularRede();
    return _banco.doacoesDoDoadorLogado(situacao);
  }

  @override
  Future<DetalheDoacao> detalhar(int doacaoId) async {
    await _banco.simularRede();
    return _banco.detalharDoacao(doacaoId);
  }

  @override
  Future<void> cancelar(int doacaoId, {String? motivo}) async {
    await _banco.simularRede();
    _banco.cancelarDoacao(doacaoId, motivo: motivo);
  }

  @override
  Future<List<Doacao>> listarProximas({double? raioKm}) async {
    await _banco.simularRede();
    return _banco.doacoesProximas(raioKm: raioKm);
  }
}
