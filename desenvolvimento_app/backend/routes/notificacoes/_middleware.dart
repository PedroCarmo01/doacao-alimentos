import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/autenticacao.dart';
import 'package:summit_backend/notificacoes/notificacao_repository_mysql.dart';
import 'package:summit_backend/notificacoes/notificacao_service.dart';

/// As rotas de `/notificacoes` exigem login.
Handler middleware(Handler handler) {
  return handler
      .use(
        provider<NotificacaoService>(
          (context) => NotificacaoService(
            NotificacaoRepositoryMysql(context.read<Database>()),
          ),
        ),
      )
      .use(exigirAutenticacao());
}
