import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/http/middlewares.dart';

/// Middleware GLOBAL: vale para todas as rotas da API.
///
/// `.use()` empilha de dentro para fora: o ÚLTIMO `.use` é o primeiro a
/// receber a requisição. A ordem de execução fica:
///
///   requestLogger  →  cors  →  tratarErros  →  middleware da pasta  →  rota
///
/// Arquivo de FUNDAÇÃO. Cada fatia (auth, doacoes, proximas, reservas) tem o
/// PRÓPRIO `_middleware.dart` dentro da sua pasta; não é preciso editar este.
Handler middleware(Handler handler) {
  return handler.use(tratarErros()).use(cors()).use(requestLogger());
}
