import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../fake/banco_fake.dart';

/// CONTRATO dos avisos guardados no servidor (`/notificacoes`).
abstract interface class NotificacaoRepository {
  /// `GET /notificacoes?depois=` — as com id maior que [depoisDe].
  Future<List<Notificacao>> novas(int depoisDe);

  /// `POST /notificacoes/lidas` — marca como lidas até o id [ate].
  Future<void> marcarLidas(int ate);
}

class NotificacaoRepositoryApi implements NotificacaoRepository {
  NotificacaoRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<List<Notificacao>> novas(int depoisDe) async {
    final json = await _api.get(
      '/notificacoes',
      consulta: {'depois': '$depoisDe'},
    );
    return [
      for (final item in ApiClient.lista(json, 'notificacoes'))
        Notificacao.fromJson(item),
    ];
  }

  @override
  Future<void> marcarLidas(int ate) =>
      _api.post('/notificacoes/lidas', corpo: {'ate': ate});
}

class NotificacaoRepositoryFake implements NotificacaoRepository {
  NotificacaoRepositoryFake(this._banco);

  final BancoFake _banco;

  @override
  Future<List<Notificacao>> novas(int depoisDe) async {
    await _banco.simularRede();
    return _banco.notificacoes.doLogado(_banco.logadoId, depoisDe);
  }

  @override
  Future<void> marcarLidas(int ate) async {
    await _banco.simularRede();
    _banco.notificacoes.marcarLidas(_banco.logadoId, ate);
  }
}
