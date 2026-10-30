import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shared_models/shared_models.dart';

import '../erros/app_exception.dart';
import 'usuario_autenticado.dart';

/// Emite e valida tokens JWT.
///
/// O token guarda só o necessário (`uid` e `tipo`). Ele é ASSINADO, não
/// criptografado: qualquer pessoa consegue ler o conteúdo, mas ninguém
/// consegue alterá-lo sem conhecer o segredo. Por isso nunca coloque dados
/// sensíveis dentro do token.
class TokenService {
  TokenService({
    required String segredo,
    this.validade = const Duration(hours: 12),
  }) : _chave = SecretKey(segredo);

  final SecretKey _chave;
  final Duration validade;

  String gerar({required int usuarioId, required TipoUsuario tipo}) => JWT({
    'uid': usuarioId,
    'tipo': tipo.name,
  }).sign(_chave, expiresIn: validade);

  /// Devolve quem é o dono do token, ou lança 401.
  UsuarioAutenticado validar(String token) {
    try {
      final dados = JWT.verify(token, _chave).payload;
      if (dados is Map) {
        final id = dados['uid'];
        final tipo = TipoUsuario.values
            .where((opcao) => opcao.name == dados['tipo'])
            .firstOrNull;
        if (id is int && tipo != null) {
          return UsuarioAutenticado(id: id, tipo: tipo);
        }
      }
    } on JWTExpiredException {
      throw const NaoAutenticadoException(
        codigo: 'TOKEN_EXPIRADO',
        mensagem: 'Sua sessão expirou. Entre novamente.',
      );
    } on JWTException {
      // Assinatura inválida ou token malformado: tratado logo abaixo.
    } on FormatException {
      // Conteúdo do token não é JSON válido: tratado logo abaixo.
    }
    throw const NaoAutenticadoException(
      codigo: 'TOKEN_INVALIDO',
      mensagem: 'Sessão inválida. Entre novamente.',
    );
  }
}
