import 'package:bcrypt/bcrypt.dart';

/// Gera e confere hashes de senha com bcrypt.
///
/// - bcrypt é LENTO de propósito, o que atrasa quem tenta adivinhar senhas.
/// - Ele usa um "sal" aleatório: a mesma senha gera hashes diferentes a cada
///   vez, então dois usuários com a mesma senha têm hashes diferentes.
/// - A senha original NUNCA é guardada nem pode ser recuperada do hash.
///
/// Nos testes, troque por uma implementação rápida: em Dart toda classe é
/// também uma interface, então `class SenhaServiceFake implements
/// SenhaService` funciona.
class SenhaService {
  const SenhaService();

  String gerarHash(String senha) => BCrypt.hashpw(senha, BCrypt.gensalt());

  bool confere(String senha, String hash) {
    try {
      return BCrypt.checkpw(senha, hash);
    } catch (_) {
      // Hash corrompido ou em formato inesperado: trata como senha errada.
      return false;
    }
  }
}
