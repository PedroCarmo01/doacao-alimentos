import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/documentos/consulta_cnpj.dart';
import 'package:summit_backend/documentos/documento_service.dart';
import 'package:summit_backend/perfil/perfil_repository_mysql.dart';

/// Monta o DocumentoService. As rotas desta pasta são PÚBLICAS: o app
/// consulta o CNPJ durante o cadastro, antes de a pessoa ter conta.
Handler middleware(Handler handler) {
  return handler.use(
    provider<DocumentoService>(
      (context) => DocumentoService(
        consulta: context.read<ConsultaCnpj>(),
        perfis: PerfilRepositoryMysql(context.read<Database>()),
      ),
    ),
  );
}
