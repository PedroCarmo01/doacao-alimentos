import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/auth/usuario_repository_mysql.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/autenticacao.dart';
import 'package:summit_backend/proximidade/proximidade_repository_mysql.dart';
import 'package:summit_backend/proximidade/proximidade_service.dart';

/// Todas as rotas de `/proximas` exigem login.
Handler middleware(Handler handler) {
  return handler
      .use(
        provider<ProximidadeService>((context) {
          final database = context.read<Database>();
          return ProximidadeService(
            proximidade: ProximidadeRepositoryMysql(database),
            usuarios: UsuarioRepositoryMysql(database),
            relogio: context.read<Relogio>(),
          );
        }),
      )
      .use(exigirAutenticacao());
}
