import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:test/test.dart';

void main() {
  test('cada exceção informa o próprio status HTTP (polimorfismo)', () {
    // A lista é do tipo da classe-mãe; cada item responde do seu jeito.
    final excecoes = <AppException, int>{
      const ValidacaoException('dados inválidos'): 400,
      const NaoAutenticadoException(): 401,
      const SemPermissaoException(): 403,
      const NaoEncontradoException(): 404,
      const MetodoNaoPermitidoException(): 405,
      const ConflitoException('DOACAO_INDISPONIVEL', 'já reservada'): 409,
    };

    excecoes.forEach((excecao, statusEsperado) {
      expect(excecao.statusHttp, statusEsperado, reason: '$excecao');
    });
  });

  test('o JSON de erro segue o padrão do projeto', () {
    const erro = ValidacaoException(
      'Dados inválidos.',
      detalhes: ['Informe o título.'],
    );

    expect(erro.toJson(), {
      'erro': {
        'codigo': 'VALIDACAO',
        'mensagem': 'Dados inválidos.',
        'detalhes': ['Informe o título.'],
      },
    });
  });
}
