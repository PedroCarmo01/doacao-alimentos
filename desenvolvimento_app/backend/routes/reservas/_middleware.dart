import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/seguranca/autenticacao.dart';

/// Todas as rotas de `/reservas` exigem login. Os serviços (`ReservaService`
/// e `ConfirmacaoService`) vêm do `main.dart`, porque o job de expiração
/// usa os mesmos.
Handler middleware(Handler handler) => handler.use(exigirAutenticacao());
