import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

/// RN02: conferência dos dígitos verificadores de CNPJ e CPF.
///
/// Os números abaixo são exemplos clássicos usados em aulas e documentação
/// (não são de empresas ou pessoas que usam o app).
void main() {
  group('CNPJ', () {
    test('RN02: CNPJ válido, com e sem máscara', () {
      expect(ValidadorDocumento.cnpjValido('11222333000181'), isTrue);
      expect(ValidadorDocumento.cnpjValido('11.222.333/0001-81'), isTrue);
    });

    test('RN02: dígito verificador errado é recusado', () {
      expect(ValidadorDocumento.cnpjValido('11222333000182'), isFalse);
      expect(ValidadorDocumento.cnpjValido('11.222.333/0001-71'), isFalse);
    });

    test('RN02: tamanho errado e números repetidos são recusados', () {
      expect(ValidadorDocumento.cnpjValido('1122233300018'), isFalse);
      expect(ValidadorDocumento.cnpjValido(''), isFalse);
      // Fecha a conta, mas a Receita não emite números assim.
      expect(ValidadorDocumento.cnpjValido('00000000000000'), isFalse);
    });

    test('completarCnpj calcula os 2 dígitos verificadores', () {
      expect(
        ValidadorDocumento.completarCnpj('112223330001'),
        '11222333000181',
      );
    });

    test('mensagens para o formulário dizem o que corrigir', () {
      expect(ValidadorDocumento.cnpj('11.222.333/0001-81'), isNull);
      expect(ValidadorDocumento.cnpj(''), 'Informe o CNPJ.');
      expect(ValidadorDocumento.cnpj('123'), 'O CNPJ tem 14 números.');
      expect(ValidadorDocumento.cnpj('11222333000182'), startsWith('CNPJ inv'));
    });
  });

  group('CPF', () {
    test('RN02: CPF válido, com e sem máscara', () {
      expect(ValidadorDocumento.cpfValido('12345678909'), isTrue);
      expect(ValidadorDocumento.cpfValido('123.456.789-09'), isTrue);
    });

    test('RN02: CPF inválido é recusado', () {
      expect(ValidadorDocumento.cpfValido('12345678900'), isFalse);
      expect(ValidadorDocumento.cpfValido('11111111111'), isFalse);
      expect(ValidadorDocumento.cpfValido('1234567890'), isFalse);
    });

    test('completarCpf calcula os 2 dígitos verificadores', () {
      expect(ValidadorDocumento.completarCpf('123456789'), '12345678909');
    });
  });

  group('cnpjOuCpf (feirante, produtor rural, outro)', () {
    test('aceita os dois documentos', () {
      expect(ValidadorDocumento.cnpjOuCpf('123.456.789-09'), isNull);
      expect(ValidadorDocumento.cnpjOuCpf('11.222.333/0001-81'), isNull);
    });

    test('outros tamanhos pedem 14 ou 11 números', () {
      expect(
        ValidadorDocumento.cnpjOuCpf('12345'),
        'Digite os 14 números do CNPJ ou os 11 do CPF.',
      );
    });
  });

  test('formatar coloca a máscara certa', () {
    expect(ValidadorDocumento.formatar('11222333000181'), '11.222.333/0001-81');
    expect(ValidadorDocumento.formatar('12345678909'), '123.456.789-09');
    expect(ValidadorDocumento.formatar('123'), '123');
  });
}
