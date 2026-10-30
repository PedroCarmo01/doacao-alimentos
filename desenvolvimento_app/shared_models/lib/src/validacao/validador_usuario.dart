import '../contratos/autenticacao.dart';
import '../contratos/perfil.dart';
import '../geo/geo.dart';
import '../tipos_de_perfil.dart';
import '../usuario.dart';
import 'validador_documento.dart';

/// Regras de validação de cadastro, login e perfil.
///
/// As MESMAS regras rodam no app (formulários) e no backend (segurança).
/// Cada método devolve `null` se o valor é válido, ou a mensagem de erro.
/// Esse formato é exatamente o que o `validator:` do `TextFormField` espera,
/// então dá para usar direto: `validator: ValidadorUsuario.email`.
abstract final class ValidadorUsuario {
  static const tamanhoMinimoSenha = 6;

  /// O bcrypt considera no máximo 72 bytes da senha.
  static const tamanhoMaximoSenha = 72;

  /// Tamanho das colunas `endereco` e `info_extra` no banco.
  static const tamanhoMaximoTextoLivre = 255;

  /// Limite de bom senso para "quantas famílias atende".
  static const maximoFamilias = 100000;

  /// Raios que a ONG pode escolher (tela de perfil T50).
  static const raiosPermitidosKm = [2.0, 5.0, 10.0, 20.0];

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

  /// No cadastro o telefone é obrigatório: o doador e a ONG precisam
  /// conseguir se ligar no dia da retirada.
  static String? telefoneObrigatorio(String? valor) {
    if ((valor?.trim() ?? '').isEmpty) return 'Informe o telefone com DDD.';
    return telefone(valor);
  }

  /// Opcional; se informado, precisa ter 8 números.
  static String? cep(String? valor) {
    final digitos = ValidadorDocumento.somenteDigitos(valor ?? '');
    if (digitos.isEmpty || digitos.length == 8) return null;
    return 'O CEP tem 8 números.';
  }

  /// RN02: qual documento cada tipo de conta aceita.
  /// - ONG: só CNPJ.
  /// - Doador feirante, produtor rural ou "outro": CNPJ ou CPF.
  /// - Demais doadores: só CNPJ.
  static String? documento(
    String? valor, {
    required TipoUsuario tipo,
    TipoEstabelecimento? estabelecimento,
  }) {
    final digitos = ValidadorDocumento.somenteDigitos(valor ?? '');
    final pareceCpf = digitos.length == ValidadorDocumento.tamanhoCpf;
    if (tipo == TipoUsuario.ong) {
      if (pareceCpf) return 'ONG precisa se cadastrar com o CNPJ.';
      return ValidadorDocumento.cnpj(digitos);
    }
    if (estabelecimento != null && estabelecimento.aceitaCpf) {
      return ValidadorDocumento.cnpjOuCpf(digitos);
    }
    if (pareceCpf) {
      return 'Este tipo de estabelecimento precisa de CNPJ. '
          'Feirantes e produtores rurais podem usar CPF.';
    }
    return ValidadorDocumento.cnpj(digitos);
  }

  /// Opcional; se informado, entre 1 e [maximoFamilias].
  static String? familiasAtendidas(int? valor) {
    if (valor == null) return null;
    if (valor < 1 || valor > maximoFamilias) {
      return 'Informe um número de famílias entre 1 e $maximoFamilias.';
    }
    return null;
  }

  /// Endereço e "informações extras" cabem em 255 caracteres.
  static String? textoLivre(String? valor) {
    if ((valor?.length ?? 0) > tamanhoMaximoTextoLivre) {
      return 'Use no máximo $tamanhoMaximoTextoLivre caracteres.';
    }
    return null;
  }

  static String? raioKm(double valor) {
    if (raiosPermitidosKm.contains(valor)) return null;
    return 'Escolha um raio de 2, 5, 10 ou 20 km.';
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
    if (dados.tipo == TipoUsuario.doador && dados.tipoEstabelecimento == null)
      'Escolha o tipo de estabelecimento.',
    documento(
      dados.documento,
      tipo: dados.tipo,
      estabelecimento: dados.tipoEstabelecimento,
    ),
    nome(dados.nome),
    nomeOrganizacao(dados.nomeOrganizacao),
    email(dados.email),
    senha(dados.senha),
    telefoneObrigatorio(dados.telefone),
    cep(dados.cep),
    textoLivre(dados.endereco),
    textoLivre(dados.infoExtra),
    familiasAtendidas(dados.familiasAtendidas),
    coordenadas(dados.latitude, dados.longitude),
    if (!dados.aceitouTermos)
      'É preciso aceitar os Termos de Uso e a Política de Privacidade.',
  ].whereType<String>().toList();

  /// Valida a edição do perfil (`PUT /perfil`).
  static List<String> validarPerfil(DadosPerfil dados) => [
    nome(dados.nome),
    nomeOrganizacao(dados.nomeOrganizacao),
    telefoneObrigatorio(dados.telefone),
    cep(dados.cep),
    textoLivre(dados.endereco),
    textoLivre(dados.infoExtra),
    familiasAtendidas(dados.familiasAtendidas),
    raioKm(dados.raioKm),
    coordenadas(dados.latitude, dados.longitude),
  ].whereType<String>().toList();
}
