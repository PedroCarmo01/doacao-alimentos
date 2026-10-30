/// Validação do código de retirada (RN26–RN27), usada pelo app (para
/// avisar antes de enviar) e pelo servidor.
abstract final class ValidadorReserva {
  static final _quatroDigitos = RegExp(r'^\d{4}$');

  /// `null` se o código tem exatamente 4 números.
  static String? codigo(String? valor) {
    if (valor == null || !_quatroDigitos.hasMatch(valor.trim())) {
      return 'Digite os 4 números do código.';
    }
    return null;
  }
}
