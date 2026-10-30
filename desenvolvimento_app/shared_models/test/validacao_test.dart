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

    test('cadastro completo e válido não tem erros', () {
      const dados = DadosCadastro(
        tipo: TipoUsuario.ong,
        nome: 'Ana Lima',
        email: 'ana@exemplo.com',
        senha: 'senha123',
        nomeOrganizacao: 'ONG Mãos Amigas',
        latitude: -23.51,
        longitude: -46.18,
      );

      expect(ValidadorUsuario.validarCadastro(dados), isEmpty);
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
