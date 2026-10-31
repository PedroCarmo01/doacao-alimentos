import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/seguranca/autenticacao.dart';

/// As rotas de `/comunidade` exigem login. O `ComunidadeService` vem do
/// `main.dart` (ele usa a mesma central de avisos dos outros serviços).
Handler middleware(Handler handler) => handler.use(exigirAutenticacao());
