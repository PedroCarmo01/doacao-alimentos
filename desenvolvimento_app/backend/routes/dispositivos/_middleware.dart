import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/autenticacao.dart';
import 'package:summit_backend/dispositivos/dispositivo_repository_mysql.dart';
import 'package:summit_backend/dispositivos/dispositivo_service.dart';

/// Todas as rotas de `/dispositivos` exigem login.
Handler middleware(Handler handler) {
  return handler
      .use(
        provider<DispositivoService>(
          (context) => DispositivoService(
            dispositivos: DispositivoRepositoryMysql(context.read<Database>()),
            relogio: context.read<Relogio>(),
          ),
        ),
      )
      .use(exigirAutenticacao());
}
