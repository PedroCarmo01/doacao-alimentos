import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../fake/banco_fake.dart';
import '../fotos/seletor_de_fotos.dart';

/// CONTRATO da Comunidade (`/comunidade`, T40 e T41).
abstract interface class ComunidadeRepository {
  /// `GET /comunidade/impacto`
  Future<Impacto> impacto();

  /// `GET /comunidade/publicacoes?antesDe=` — 20 por vez (0 = as mais
  /// novas).
  Future<List<Publicacao>> feed({int antesDe = 0});

  /// `POST /comunidade/publicacoes` (RN40)
  Future<Publicacao> publicar(DadosPublicacao dados);

  /// `POST /comunidade/publicacoes/{id}/fotos`
  Future<Publicacao> enviarFoto(int publicacaoId, FotoEscolhida foto);

  /// `POST` ou `DELETE /comunidade/publicacoes/{id}/apoio` (RN41)
  Future<Publicacao> apoiar(int publicacaoId, {required bool apoiar});

  /// `POST /comunidade/publicacoes/{id}/denuncia` (RN42)
  Future<void> denunciar(int publicacaoId, MotivoDenuncia motivo);
}

class ComunidadeRepositoryApi implements ComunidadeRepository {
  ComunidadeRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<Impacto> impacto() async =>
      Impacto.fromJson(ApiClient.objeto(await _api.get('/comunidade/impacto')));

  @override
  Future<List<Publicacao>> feed({int antesDe = 0}) async {
    final json = await _api.get(
      '/comunidade/publicacoes',
      consulta: {'antesDe': '$antesDe'},
    );
    return [
      for (final item in ApiClient.lista(json, 'publicacoes'))
        Publicacao.fromJson(item),
    ];
  }

  @override
  Future<Publicacao> publicar(DadosPublicacao dados) async {
    final json = await _api.post(
      '/comunidade/publicacoes',
      corpo: dados.toJson(),
    );
    return Publicacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<Publicacao> enviarFoto(int publicacaoId, FotoEscolhida foto) async {
    final json = await _api.enviarArquivo(
      '/comunidade/publicacoes/$publicacaoId/fotos',
      campo: 'foto',
      bytes: foto.bytes,
      nomeArquivo: foto.nome,
    );
    return Publicacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<Publicacao> apoiar(int publicacaoId, {required bool apoiar}) async {
    final caminho = '/comunidade/publicacoes/$publicacaoId/apoio';
    final json = apoiar ? await _api.post(caminho) : await _api.delete(caminho);
    return Publicacao.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<void> denunciar(int publicacaoId, MotivoDenuncia motivo) => _api.post(
    '/comunidade/publicacoes/$publicacaoId/denuncia',
    corpo: {'motivo': motivo.name},
  );
}

class ComunidadeRepositoryFake implements ComunidadeRepository {
  ComunidadeRepositoryFake(this._banco);

  final BancoFake _banco;

  @override
  Future<Impacto> impacto() async {
    await _banco.simularRede();
    return _banco.comunidade.impacto();
  }

  @override
  Future<List<Publicacao>> feed({int antesDe = 0}) async {
    await _banco.simularRede();
    return _banco.comunidade.feed(_banco.contaLogada(), antesDe);
  }

  @override
  Future<Publicacao> publicar(DadosPublicacao dados) async {
    await _banco.simularRede();
    return _banco.comunidade.publicar(_banco.contaLogada(), dados);
  }

  @override
  Future<Publicacao> enviarFoto(int publicacaoId, FotoEscolhida foto) async {
    await _banco.simularRede();
    // No modo Fake a foto não sai do celular: guardamos o caminho dela.
    return _banco.comunidade.adicionarFoto(
      _banco.contaLogada(),
      publicacaoId,
      foto.caminho,
    );
  }

  @override
  Future<Publicacao> apoiar(int publicacaoId, {required bool apoiar}) async {
    await _banco.simularRede();
    return _banco.comunidade.apoiar(
      _banco.contaLogada(),
      publicacaoId,
      apoiar: apoiar,
    );
  }

  @override
  Future<void> denunciar(int publicacaoId, MotivoDenuncia motivo) async {
    await _banco.simularRede();
    _banco.comunidade.denunciar(_banco.contaLogada(), publicacaoId);
  }
}
