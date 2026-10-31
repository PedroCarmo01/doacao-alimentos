import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/auth/usuario_repository_mysql.dart';
import 'package:summit_backend/core/config/env.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/autenticacao.dart';
import 'package:summit_backend/perfil/estatisticas_repository.dart';
import 'package:summit_backend/perfil/perfil_repository_mysql.dart';
import 'package:summit_backend/perfil/perfil_service.dart';

/// Todas as rotas de `/perfil` exigem login.
Handler middleware(Handler handler) {
  return handler
      .use(
        provider<PerfilService>((context) {
          final database = context.read<Database>();
          return PerfilService(
            perfis: PerfilRepositoryMysql(database),
            usuarios: UsuarioRepositoryMysql(database),
            estatisticas: EstatisticasRepositoryMysql(database),
            relogio: context.read<Relogio>(),
            janelaDesistencias: context
                .read<Env>()
                .regrasDaRetirada
                .janelaDesistencias,
          );
        }),
      )
      .use(exigirAutenticacao());
}
