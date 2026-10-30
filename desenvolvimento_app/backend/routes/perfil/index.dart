import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/perfil/perfil_service.dart';

/// `PUT /perfil` — editar dados, localização, busca ativa e raio.
/// Devolve a conta atualizada (`{usuario, perfil}`).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
    throw const MetodoNaoPermitidoException();
  }
  final dados = DadosPerfil.fromJson(await context.lerJson());
  final conta = await context.read<PerfilService>().atualizar(
    context.read<UsuarioAutenticado>(),
    dados,
  );
  return Response.json(body: conta.toJson());
}
