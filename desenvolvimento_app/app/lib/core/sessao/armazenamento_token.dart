import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Onde o token JWT fica guardado entre uma abertura e outra do app.
///
/// Interface + duas implementações: no aparelho usamos o armazenamento
/// seguro do sistema (Keystore no Android); nos testes e no modo Fake, a
/// memória. Quem usa (Sessao, ApiClient) não sabe qual das duas recebeu.
abstract interface class ArmazenamentoToken {
  Future<String?> ler();
  Future<void> salvar(String token);
  Future<void> apagar();
}

/// Armazenamento criptografado do sistema operacional.
class ArmazenamentoTokenSeguro implements ArmazenamentoToken {
  ArmazenamentoTokenSeguro([FlutterSecureStorage? armazenamento])
    : _armazenamento = armazenamento ?? const FlutterSecureStorage();

  static const _chave = 'token_jwt';
  final FlutterSecureStorage _armazenamento;

  @override
  Future<String?> ler() => _armazenamento.read(key: _chave);

  @override
  Future<void> salvar(String token) =>
      _armazenamento.write(key: _chave, value: token);

  @override
  Future<void> apagar() => _armazenamento.delete(key: _chave);
}

/// Guarda o token só na memória (some ao fechar o app).
class ArmazenamentoTokenMemoria implements ArmazenamentoToken {
  String? _token;

  @override
  Future<String?> ler() async => _token;

  @override
  Future<void> salvar(String token) async => _token = token;

  @override
  Future<void> apagar() async => _token = null;
}
