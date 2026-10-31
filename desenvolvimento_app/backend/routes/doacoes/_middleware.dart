import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/arquivos/armazenamento_de_fotos.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/autenticacao.dart';
import 'package:summit_backend/doacoes/doacao_repository_mysql.dart';
import 'package:summit_backend/doacoes/foto_doacao_service.dart';

/// Todas as rotas de `/doacoes` exigem login. O `DoacaoService` vem do
/// `main.dart` (o job de expiração usa o mesmo); aqui monta o das fotos.
Handler middleware(Handler handler) {
  return handler
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
