import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/token_service.dart';
import 'package:test/test.dart';

void main() {
  const segredo = 'segredo-de-teste-com-mais-de-32-caracteres!';

  group('TokenService', () {
    test('o token gerado é validado e devolve o mesmo usuário', () {
      final servico = TokenService(segredo: segredo);

      final token = servico.gerar(usuarioId: 7, tipo: TipoUsuario.ong);
      final usuario = servico.validar(token);

      expect(usuario.id, 7);
      expect(usuario.ehOng, isTrue);
    });

    test('RN05: o login vale 30 dias por padrão', () {
      final servico = TokenService(segredo: segredo);

      final token = servico.gerar(usuarioId: 7, tipo: TipoUsuario.ong);
      final dados = JWT.decode(token).payload as Map;
      final validadeEmSegundos = (dados['exp'] as int) - (dados['iat'] as int);

      expect(Duration(seconds: validadeEmSegundos), const Duration(days: 30));
    });

    test('token assinado com outro segredo é recusado', () {
      final outro = TokenService(
        segredo: 'outro-segredo-tambem-com-32-caracteres!!',
      );
      final token = outro.gerar(usuarioId: 1, tipo: TipoUsuario.doador);

      expect(
        () => TokenService(segredo: segredo).validar(token),
        throwsA(
          isA<NaoAutenticadoException>().having(
            (erro) => erro.codigo,
            'codigo',
            'TOKEN_INVALIDO',
          ),
        ),
      );
    });

    test('token expirado gera 401 TOKEN_EXPIRADO', () {
      final servico = TokenService(
        segredo: segredo,
        validade: const Duration(seconds: -10),
      );
      final token = servico.gerar(usuarioId: 1, tipo: TipoUsuario.doador);

      expect(
        () => servico.validar(token),
        throwsA(
          isA<NaoAutenticadoException>().having(
            (erro) => erro.codigo,
            'codigo',
            'TOKEN_EXPIRADO',
          ),
        ),
      );
    });

    test('texto que não é um JWT é recusado', () {
      expect(
        () => TokenService(segredo: segredo).validar('isto-nao-e-um-token'),
        throwsA(isA<NaoAutenticadoException>()),
      );
    });
  });
}
