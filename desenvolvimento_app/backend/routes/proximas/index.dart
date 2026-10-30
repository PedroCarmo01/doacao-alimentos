import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/proximidade/proximidade_service.dart';

/// `GET /proximas?raioKm=5` — doações disponíveis perto da ONG logada, da
/// mais perto para a mais longe, com `distanciaKm`. Sem `raioKm`, usa o raio
/// salvo no perfil da ONG.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    throw const MetodoNaoPermitidoException();
  }
  final doacoes = await context.read<ProximidadeService>().proximas(
    context.read<UsuarioAutenticado>(),
    raioKm: context.parametroDecimal('raioKm'),
  );
  return Response.json(
    body: {
      'doacoes': [for (final doacao in doacoes) doacao.toJson()],
    },
  );
}
