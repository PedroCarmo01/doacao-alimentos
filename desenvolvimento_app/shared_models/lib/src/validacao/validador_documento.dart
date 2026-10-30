/// Confere CNPJ e CPF pelos dígitos verificadores (RN02).
///
/// Usado no formulário de cadastro (app), no servidor e para gerar os
/// documentos FICTÍCIOS dos dados de exemplo (seed e BancoFake).
library;

/// Regras de CNPJ e CPF.
///
/// Os dois últimos dígitos de um CNPJ ou CPF são calculados a partir dos
/// outros (uma conta matemática). Se a pessoa digitar um número errado ou
/// inventar um documento, a conta não fecha. Isso pega erro de digitação,
/// mas NÃO diz se a empresa existe: para isso o servidor consulta a
/// BrasilAPI (RN03).
abstract final class ValidadorDocumento {
  static const tamanhoCnpj = 14;
  static const tamanhoCpf = 11;

  /// Pesos da conta do CNPJ, para o 1º e o 2º dígito verificador.
  static const _pesosCnpj1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  static const _pesosCnpj2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  /// Tira pontos, barras, traços e espaços: "11.222.333/0001-81" vira
  /// "11222333000181". É assim que o documento é gravado no banco.
  static String somenteDigitos(String texto) =>
      texto.replaceAll(RegExp(r'\D'), '');

  /// `true` se [texto] (com ou sem máscara) é um CNPJ com dígitos corretos.
  static bool cnpjValido(String texto) {
    final numero = somenteDigitos(texto);
    if (numero.length != tamanhoCnpj || _todosIguais(numero)) return false;
    return completarCnpj(numero.substring(0, 12)) == numero;
  }

  /// `true` se [texto] (com ou sem máscara) é um CPF com dígitos corretos.
  static bool cpfValido(String texto) {
    final numero = somenteDigitos(texto);
    if (numero.length != tamanhoCpf || _todosIguais(numero)) return false;
    return completarCpf(numero.substring(0, 9)) == numero;
  }

  /// Recebe os 12 primeiros dígitos e devolve o CNPJ completo (14 dígitos),
  /// calculando os 2 verificadores. Serve para criar CNPJs fictícios válidos.
  static String completarCnpj(String dozeDigitos) {
    final primeiro = _digitoVerificador(dozeDigitos, _pesosCnpj1);
    final comPrimeiro = '$dozeDigitos$primeiro';
    final segundo = _digitoVerificador(comPrimeiro, _pesosCnpj2);
    return '$comPrimeiro$segundo';
  }

  /// Recebe os 9 primeiros dígitos e devolve o CPF completo (11 dígitos).
  static String completarCpf(String noveDigitos) {
    // No CPF os pesos começam em 10 (1º dígito) e 11 (2º dígito) e
    // diminuem até 2.
    final primeiro = _digitoVerificador(noveDigitos, _pesosDecrescentes(10));
    final comPrimeiro = '$noveDigitos$primeiro';
    final segundo = _digitoVerificador(comPrimeiro, _pesosDecrescentes(11));
    return '$comPrimeiro$segundo';
  }

  /// Mensagem de erro para um campo de CNPJ, ou `null` se estiver certo.
  static String? cnpj(String? valor) {
    final numero = somenteDigitos(valor ?? '');
    if (numero.isEmpty) return 'Informe o CNPJ.';
    if (numero.length != tamanhoCnpj) return 'O CNPJ tem 14 números.';
    if (!cnpjValido(numero)) {
      return 'CNPJ inválido. Confira se digitou todos os números certos.';
    }
    return null;
  }

  /// Aceita CNPJ **ou** CPF (tipos de doador que podem ser pessoa física).
  static String? cnpjOuCpf(String? valor) {
    final numero = somenteDigitos(valor ?? '');
    if (numero.isEmpty) return 'Informe o CNPJ ou o CPF.';
    if (numero.length == tamanhoCpf) {
      return cpfValido(numero)
          ? null
          : 'CPF inválido. Confira se digitou todos os números certos.';
    }
    if (numero.length == tamanhoCnpj) return cnpj(numero);
    return 'Digite os 14 números do CNPJ ou os 11 do CPF.';
  }

  /// "11222333000181" → "11.222.333/0001-81"; "12345678909" → "123.456.789-09".
  /// Outros tamanhos voltam sem mudança.
  static String formatar(String texto) {
    final n = somenteDigitos(texto);
    if (n.length == tamanhoCnpj) {
      return '${n.substring(0, 2)}.${n.substring(2, 5)}.${n.substring(5, 8)}/'
          '${n.substring(8, 12)}-${n.substring(12)}';
    }
    if (n.length == tamanhoCpf) {
      return '${n.substring(0, 3)}.${n.substring(3, 6)}.${n.substring(6, 9)}-'
          '${n.substring(9)}';
    }
    return texto;
  }

  /// A conta do dígito verificador (igual para CNPJ e CPF, só mudam os
  /// pesos): multiplica cada dígito pelo seu peso, soma tudo e pega o resto
  /// da divisão por 11. Resto menor que 2 → dígito 0; senão, 11 - resto.
  static int _digitoVerificador(String digitos, List<int> pesos) {
    var soma = 0;
    for (var i = 0; i < pesos.length; i++) {
      soma += int.parse(digitos[i]) * pesos[i];
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  /// [inicio], [inicio] - 1, ..., 2. Ex.: 10 → [10, 9, 8, 7, 6, 5, 4, 3, 2].
  static List<int> _pesosDecrescentes(int inicio) => [
    for (var peso = inicio; peso >= 2; peso--) peso,
  ];

  /// "00000000000000" e "11111111111" fecham a conta, mas não são
  /// documentos de verdade. A Receita não emite números assim.
  static bool _todosIguais(String numero) =>
      numero.split('').every((digito) => digito == numero[0]);
}
