import '../contratos/autenticacao.dart';
import '../geo/geo.dart';

/// Regras de validação de cadastro e login.
///
/// As MESMAS regras rodam no app (formulários) e no backend (segurança).
/// Cada método devolve `null` se o valor é válido, ou a mensagem de erro.
/// Esse formato é exatamente o que o `validator:` do `TextFormField` espera,
/// então dá para usar direto: `validator: ValidadorUsuario.email`.
abstract final class ValidadorUsuario {
  static const tamanhoMinimoSenha = 6;

  /// O bcrypt considera no máximo 72 bytes da senha.
  static const tamanhoMaximoSenha = 72;

  static final _formatoEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? nome(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o nome.';
    if (texto.length < 3) return 'O nome deve ter pelo menos 3 letras.';
    if (texto.length > 120) return 'O nome deve ter no máximo 120 caracteres.';
    return null;
  }

  static String? nomeOrganizacao(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o nome da organização.';
    if (texto.length < 3) return 'O nome deve ter pelo menos 3 letras.';
    if (texto.length > 160) return 'O nome deve ter no máximo 160 caracteres.';
    return null;
  }

  static String? email(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o e-mail.';
    if (texto.length > 160 || !_formatoEmail.hasMatch(texto)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  static String? senha(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'Informe a senha.';
    if (texto.length < tamanhoMinimoSenha) {
      return 'A senha deve ter pelo menos $tamanhoMinimoSenha caracteres.';
    }
    if (texto.length > tamanhoMaximoSenha) {
      return 'A senha deve ter no máximo $tamanhoMaximoSenha caracteres.';
    }
    return null;
  }

  /// Opcional; se informado, precisa ter DDD (10 a 13 dígitos).
  static String? telefone(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return null;
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.length < 10 || digitos.length > 13) {
      return 'Informe o telefone com DDD.';
    }
    return null;
  }

  static String? coordenadas(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return 'Informe a localização.';
    }
    if (!Coordenadas(latitude, longitude).valida) {
      return 'Localização inválida.';
    }
    return null;
  }

  /// Valida um cadastro inteiro. Lista vazia significa "tudo certo".
  static List<String> validarCadastro(DadosCadastro dados) => [
    nome(dados.nome),
    nomeOrganizacao(dados.nomeOrganizacao),
    email(dados.email),
    senha(dados.senha),
    telefone(dados.telefone),
    coordenadas(dados.latitude, dados.longitude),
  ].whereType<String>().toList();
}
