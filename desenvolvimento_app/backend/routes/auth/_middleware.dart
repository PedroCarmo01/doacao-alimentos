import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/auth/auth_service.dart';
import 'package:summit_backend/auth/usuario_repository_mysql.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/senha_service.dart';
import 'package:summit_backend/core/seguranca/token_service.dart';
import 'package:summit_backend/documentos/consulta_cnpj.dart';
import 'package:summit_backend/documentos/documento_service.dart';
import 'package:summit_backend/perfil/perfil_repository_mysql.dart';

/// Monta o AuthService com as dependências criadas em main.dart.
///
/// Nem todas as rotas de `/auth` exigem login (cadastro e login, claro,
/// não). Por isso aqui NÃO usamos `exigirAutenticacao()`: a rota `me.dart`
/// chama `autenticar(context)` sozinha.
Handler middleware(Handler handler) {
  return handler.use(
    provider<AuthService>((context) {
      final database = context.read<Database>();
      return AuthService(
        usuarios: UsuarioRepositoryMysql(database),
        documentos: DocumentoService(
          consulta: context.read<ConsultaCnpj>(),
          perfis: PerfilRepositoryMysql(database),
        ),
        senhas: context.read<SenhaService>(),
        tokens: context.read<TokenService>(),
        relogio: context.read<Relogio>(),
      );
    }),
  );
}
