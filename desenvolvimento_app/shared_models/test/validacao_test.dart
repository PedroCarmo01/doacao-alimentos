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
      DateTime? validade,
      DateTime? inicio,
      DateTime? fim,
      bool declaracao = true,
    }) => DadosNovaDoacao(
      titulo: 'Pães do dia',
      categoria: CategoriaAlimento.padaria,
      quantidade: '30 unidades',
      validade: validade ?? DateTime.utc(2026, 9, 16),
      janelaInicio: inicio ?? DateTime.utc(2026, 9, 15, 13),
      janelaFim: fim ?? DateTime.utc(2026, 9, 15, 18),
      declaracaoAlimentosProprios: declaracao,
    );

    test('doação válida não tem erros', () {
      expect(
        ValidadorDoacao.validar(doacao(), agora: agora, hoje: hoje),
        isEmpty,
      );
    });

    test('não aceita alimento vencido', () {
      final erros = ValidadorDoacao.validar(
        doacao(validade: DateTime.utc(2026, 9, 14)),
        agora: agora,
        hoje: hoje,
      );

      expect(erros, contains('Não é permitido doar alimentos vencidos.'));
    });

    test('validade igual a hoje é aceita', () {
      expect(ValidadorDoacao.validade(hoje, hoje: hoje), isNull);
    });

    test('fim da janela precisa ser depois do início', () {
      final erros = ValidadorDoacao.validar(
        doacao(
          inicio: DateTime.utc(2026, 9, 15, 18),
          fim: DateTime.utc(2026, 9, 15, 13),
        ),
        agora: agora,
        hoje: hoje,
      );

      expect(erros, isNotEmpty);
    });

    test('declaração de alimentos próprios é obrigatória', () {
      final erros = ValidadorDoacao.validar(
        doacao(declaracao: false),
        agora: agora,
        hoje: hoje,
      );

      expect(erros, hasLength(1));
    });
  });
}
