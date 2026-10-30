import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/arquivos/armazenamento_de_fotos.dart';
import 'package:summit_backend/auth/usuario_repository_mysql.dart';
import 'package:summit_backend/core/config/env.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/autenticacao.dart';
import 'package:summit_backend/doacoes/doacao_repository_mysql.dart';
import 'package:summit_backend/doacoes/doacao_service.dart';
import 'package:summit_backend/doacoes/foto_doacao_service.dart';

/// Todas as rotas de `/doacoes` exigem login. Monta os dois serviços.
Handler middleware(Handler handler) {
  return handler
      .use(
        provider<DoacaoService>((context) {
          final database = context.read<Database>();
          return DoacaoService(
            doacoes: DoacaoRepositoryMysql(database),
            usuarios: UsuarioRepositoryMysql(database),
            relogio: context.read<Relogio>(),
            fusoHorarioUtc: context.read<Env>().fusoHorarioUtc,
          );
        }),
      )
      .use(
        provider<FotoDoacaoService>(
          (context) => FotoDoacaoService(
            doacoes: DoacaoRepositoryMysql(context.read<Database>()),
            armazenamento: context.read<ArmazenamentoDeFotos>(),
          ),
        ),
      )
      .use(exigirAutenticacao());
}
