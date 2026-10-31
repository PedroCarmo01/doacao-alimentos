import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../fake/banco_fake.dart';

/// CONTRATO do chat de cada retirada (`/conversas`).
abstract interface class ChatRepository {
  /// `GET /conversas` — a aba Mensagens (T31).
  Future<List<ResumoConversa>> conversas();

  /// `GET /conversas/{reservaId}/mensagens?depois=` — as novas.
  Future<RespostaMensagens> mensagens(int reservaId, {int depoisDe = 0});

  /// `POST /conversas/{reservaId}/mensagens`
  Future<Mensagem> enviar(int reservaId, String texto);

  /// `POST /conversas/{reservaId}/lidas`
  Future<void> marcarLidas(int reservaId);
}

class ChatRepositoryApi implements ChatRepository {
  ChatRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<List<ResumoConversa>> conversas() async {
    final json = await _api.get('/conversas');
    return [
      for (final item in ApiClient.lista(json, 'conversas'))
        ResumoConversa.fromJson(item),
    ];
  }

  @override
  Future<RespostaMensagens> mensagens(int reservaId, {int depoisDe = 0}) async {
    final json = await _api.get(
      '/conversas/$reservaId/mensagens',
      consulta: {'depois': '$depoisDe'},
    );
    return RespostaMensagens.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<Mensagem> enviar(int reservaId, String texto) async {
    final json = await _api.post(
      '/conversas/$reservaId/mensagens',
      corpo: {'texto': texto},
    );
    return Mensagem.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<void> marcarLidas(int reservaId) =>
      _api.post('/conversas/$reservaId/lidas');
}

class ChatRepositoryFake implements ChatRepository {
  ChatRepositoryFake(this._banco);

  final BancoFake _banco;

  @override
  Future<List<ResumoConversa>> conversas() async {
    await _banco.simularRede();
    return _banco.chat.conversasDe(_banco.contaLogada());
  }

  @override
  Future<RespostaMensagens> mensagens(int reservaId, {int depoisDe = 0}) async {
    await _banco.simularRede();
    return _banco.chat.mensagens(_banco.contaLogada(), reservaId, depoisDe);
  }

  @override
  Future<Mensagem> enviar(int reservaId, String texto) async {
    await _banco.simularRede();
    return _banco.chat.enviar(_banco.contaLogada(), reservaId, texto);
  }

  @override
  Future<void> marcarLidas(int reservaId) async {
    await _banco.simularRede();
    _banco.chat.marcarLidas(_banco.contaLogada(), reservaId);
  }
}
