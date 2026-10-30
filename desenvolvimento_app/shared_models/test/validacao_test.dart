import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('ValidadorUsuario', () {
    test('e-mail', () {
      expect(ValidadorUsuario.email('ana@exemplo.com'), isNull);
      expect(ValidadorUsuario.email(''), isNotNull);
      expect(ValidadorUsuario.email('ana@exemplo'), isNotNull);
    });

    test('senha precisa de pelo menos 6 caracteres', () {
      expect(ValidadorUsuario.senha('12345'), isNotNull);
      expect(ValidadorUsuario.senha('123456'), isNull);
    });

    test('telefone é opcional, mas precisa de DDD quando informado', () {
      expect(ValidadorUsuario.telefone(null), isNull);
      expect(ValidadorUsuario.telefone('(11) 99999-0000'), isNull);
      expect(ValidadorUsuario.telefone('9999-0000'), isNotNull);
    });

    // CNPJ e CPF fictícios, com os dígitos verificadores corretos.
    final cnpj = ValidadorDocumento.completarCnpj('112223330001');
    final cpf = ValidadorDocumento.completarCpf('123456789');

    DadosCadastro cadastro({
      TipoUsuario tipo = TipoUsuario.ong,
      TipoEstabelecimento? estabelecimento,
      String? documento,
      String? telefone = '(11) 99999-0000',
      bool aceitouTermos = true,
    }) => DadosCadastro(
      tipo: tipo,
      tipoEstabelecimento: estabelecimento,
      nome: 'Ana Lima',
      email: 'ana@exemplo.com',
      senha: 'senha123',
      nomeOrganizacao: 'ONG Mãos Amigas',
      documento: documento ?? cnpj,
      telefone: telefone,
      latitude: -23.51,
      longitude: -46.18,
      aceitouTermos: aceitouTermos,
    );

    test('cadastro completo e válido não tem erros', () {
      expect(ValidadorUsuario.validarCadastro(cadastro()), isEmpty);
    });

    test('RN02: ONG precisa de CNPJ (CPF é recusado)', () {
      final erros = ValidadorUsuario.validarCadastro(cadastro(documento: cpf));

      expect(erros, contains('ONG precisa se cadastrar com o CNPJ.'));
    });

    test('RN02: feirante e produtor rural podem usar CPF', () {
      for (final tipo in [
        TipoEstabelecimento.feira,
        TipoEstabelecimento.produtorRural,
        TipoEstabelecimento.outro,
      ]) {
        final dados = cadastro(
          tipo: TipoUsuario.doador,
          estabelecimento: tipo,
          documento: cpf,
        );
        expect(
          ValidadorUsuario.validarCadastro(dados),
          isEmpty,
          reason: '$tipo',
        );
      }
    });

    test('RN02: supermercado com CPF é recusado', () {
      final erros = ValidadorUsuario.validarCadastro(
        cadastro(
          tipo: TipoUsuario.doador,
          estabelecimento: TipoEstabelecimento.supermercado,
          documento: cpf,
        ),
      );

      expect(erros.single, startsWith('Este tipo de estabelecimento precisa'));
    });

    test('RN02: CNPJ com dígito errado é recusado', () {
      final errado = '${cnpj.substring(0, 13)}0' == cnpj
          ? '${cnpj.substring(0, 13)}1'
          : '${cnpj.substring(0, 13)}0';

      expect(
        ValidadorUsuario.validarCadastro(cadastro(documento: errado)),
        contains(startsWith('CNPJ inválido')),
      );
    });

    test('doador precisa escolher o tipo de estabelecimento', () {
      final erros = ValidadorUsuario.validarCadastro(
        cadastro(tipo: TipoUsuario.doador),
      );

      expect(erros, contains('Escolha o tipo de estabelecimento.'));
    });

    test('telefone e aceite dos termos são obrigatórios no cadastro', () {
      final erros = ValidadorUsuario.validarCadastro(
        cadastro(telefone: null, aceitouTermos: false),
      );

      expect(erros, hasLength(2));
    });

    test('normalizado() limpa a máscara e descarta campos do outro tipo', () {
      final dados = DadosCadastro(
        tipo: TipoUsuario.ong,
        tipoEstabelecimento: TipoEstabelecimento.padaria,
        nome: ' Ana ',
        email: ' Ana@Exemplo.com ',
        senha: 'senha123',
        nomeOrganizacao: 'ONG',
        documento: ValidadorDocumento.formatar(cnpj),
        cep: '08780-000',
        latitude: 0,
        longitude: 0,
        aceitouTermos: true,
      ).normalizado();

      expect(dados.documento, cnpj);
      expect(dados.cep, '08780000');
      expect(dados.email, 'ana@exemplo.com');
      expect(dados.tipoEstabelecimento, isNull); // RN01: ONG não tem
      expect(dados.tipoDocumento, TipoDocumento.cnpj);
    });

    test('raio da ONG só aceita as opções da tela', () {
      expect(ValidadorUsuario.raioKm(10), isNull);
      expect(ValidadorUsuario.raioKm(7), isNotNull);
    });
  });

  group('ValidadorDoacao', () {
    // Datas fixas: o teste dá sempre o mesmo resultado, em qualquer dia.
    final agora = DateTime.utc(2026, 9, 15, 12);
    final hoje = DateTime.utc(2026, 9, 15);

    DadosNovaDoacao doacao({
      CategoriaAlimento categoria = CategoriaAlimento.padaria,
      DateTime? validade,
      DateTime? inicio,
      DateTime? fim,
      DateTime? preparadoEm,
      double quantidade = 30,
      double pesoKg = 6,
      bool declaracao = true,
    }) => DadosNovaDoacao(
      titulo: 'Pães do dia',
      categoria: categoria,
      quantidade: quantidade,
      unidade: Unidade.unidades,
      pesoKg: pesoKg,
      conservacao: Conservacao.ambiente,
      validade: validade ?? DateTime.utc(2026, 9, 16),
      preparadoEm: preparadoEm,
      janelaInicio: inicio ?? DateTime.utc(2026, 9, 15, 13),
      janelaFim: fim ?? DateTime.utc(2026, 9, 15, 18),
      declaracaoAlimentosProprios: declaracao,
    );

    List<String> validar(DadosNovaDoacao dados) =>
        ValidadorDoacao.validar(dados, agora: agora, hoje: hoje);

    test('doação válida não tem erros', () {
      expect(validar(doacao()), isEmpty);
    });

    test('RN10: validade de ontem é recusada', () {
      expect(
        validar(doacao(validade: DateTime.utc(2026, 9, 14))),
        contains('Não é permitido doar alimentos vencidos.'),
      );
    });

    test('RN10: validade igual a hoje é aceita', () {
      expect(ValidadorDoacao.validade(hoje, hoje: hoje), isNull);
    });

    test('RN10: fim da retirada precisa ser depois do início', () {
      final erros = validar(
        doacao(
          inicio: DateTime.utc(2026, 9, 15, 18),
          fim: DateTime.utc(2026, 9, 15, 13),
        ),
      );

      expect(erros, contains('O fim da retirada deve ser depois do início.'));
    });

    test('RN10: fim da retirada no passado é recusado', () {
      final erros = validar(
        doacao(
          inicio: DateTime.utc(2026, 9, 15, 8),
          fim: DateTime.utc(2026, 9, 15, 11),
        ),
      );

      expect(erros, isNotEmpty);
    });

    test('RN10: declaração de alimentos próprios é obrigatória', () {
      expect(validar(doacao(declaracao: false)), hasLength(1));
    });

    test('quantidade e peso precisam ser maiores que zero', () {
      expect(validar(doacao(quantidade: 0, pesoKg: 0)), hasLength(2));
    });

    test('lerNumero aceita vírgula ou ponto', () {
      expect(ValidadorDoacao.lerNumero('2,5'), 2.5);
      expect(ValidadorDoacao.lerNumero('2.5'), 2.5);
      expect(ValidadorDoacao.lerNumero('abc'), isNull);
    });

    group('refeições prontas', () {
      test('pedem o horário de preparo', () {
        expect(
          validar(doacao(categoria: CategoriaAlimento.refeicoesProntas)),
          contains('Informe o horário de preparo.'),
        );
      });

      test('retirada até 4 h depois do preparo é aceita', () {
        final dados = doacao(
          categoria: CategoriaAlimento.refeicoesProntas,
          preparadoEm: DateTime.utc(2026, 9, 15, 11),
          fim: DateTime.utc(2026, 9, 15, 15),
        );

        expect(validar(dados), isEmpty);
      });

      test('retirada mais de 4 h depois do preparo é recusada', () {
        final dados = doacao(
          categoria: CategoriaAlimento.refeicoesProntas,
          preparadoEm: DateTime.utc(2026, 9, 15, 11),
          fim: DateTime.utc(2026, 9, 15, 16),
        );

        expect(validar(dados).single, startsWith('Refeições prontas devem'));
      });
    });

    test('RN12: cancelar doação reservada exige motivo', () {
      expect(ValidadorDoacao.motivoCancelamento(''), isNotNull);
      expect(ValidadorDoacao.motivoCancelamento('Estragou'), isNull);
    });
  });

  group('ValidadorReserva', () {
    test('RN27: o código tem exatamente 4 números', () {
      expect(ValidadorReserva.codigo('4821'), isNull);
      expect(ValidadorReserva.codigo('482'), isNotNull);
      expect(ValidadorReserva.codigo('48a1'), isNotNull);
      expect(ValidadorReserva.codigo(null), isNotNull);
    });
  });
}
