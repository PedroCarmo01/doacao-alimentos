import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/reservas/confirmacao_service.dart';

/// `POST /reservas/{id}/confirmar` `{codigo}` — o doador confirma a
/// retirada com o código da ONG (RN27).
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    throw const MetodoNaoPermitidoException();
  }
  final dados = DadosConfirmacao.fromJson(await context.lerJson());
  final reserva = await context.read<ConfirmacaoService>().confirmar(
    context.read<UsuarioAutenticado>(),
    idDaRota(id),
    dados.codigo,
  );
  return Response.json(body: reserva.toJson());
}
