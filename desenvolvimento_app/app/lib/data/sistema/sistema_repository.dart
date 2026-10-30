import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';

/// Situação do servidor, mostrada na tela inicial (prova do Sprint 0).
class StatusSistema {
  const StatusSistema({
    required this.apiOnline,
    required this.bancoOnline,
    this.modoDemonstracao = false,
  });

  final bool apiOnline;
  final bool bancoOnline;
  final bool modoDemonstracao;

  bool get tudoCerto => modoDemonstracao || (apiOnline && bancoOnline);

  String get descricao {
    if (modoDemonstracao) return 'Modo demonstração (dados fictícios)';
    if (!apiOnline) return 'Servidor fora do ar';
    if (!bancoOnline) return 'Servidor no ar, mas sem banco de dados';
    return 'Servidor online';
  }
}

/// CONTRATO: verificar se a API e o banco respondem (`GET /`).
abstract interface class SistemaRepository {
  /// Nunca lança exceção: problemas viram um [StatusSistema] negativo.
  Future<StatusSistema> verificar();
}

class SistemaRepositoryApi implements SistemaRepository {
  SistemaRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<StatusSistema> verificar() async {
    try {
      final json = ApiClient.objeto(await _api.get('/'));
      return StatusSistema(
        apiOnline: true,
        bancoOnline: json['banco'] == 'conectado',
      );
    } on ApiException catch (e) {
      // Com status: o servidor respondeu (ex.: 503 sem banco).
      // Sem status: nem chegou ao servidor.
      return StatusSistema(apiOnline: e.status != null, bancoOnline: false);
    }
  }
}

class SistemaRepositoryFake implements SistemaRepository {
  const SistemaRepositoryFake();

  @override
  Future<StatusSistema> verificar() async => const StatusSistema(
        apiOnline: true,
        bancoOnline: true,
        modoDemonstracao: true,
      );
}
