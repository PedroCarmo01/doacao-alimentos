import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../erros/app_exception.dart';
import 'token_service.dart';
import 'usuario_autenticado.dart';

/// Lê o cabeçalho `Authorization: Bearer <token>` e devolve o usuário.
/// Lança 401 se o cabeçalho faltar ou o token for inválido.
///
/// Use direto na rota quando só ALGUMAS rotas da pasta exigem login
/// (exemplo: `routes/auth/me.dart`).
UsuarioAutenticado autenticar(RequestContext context) {
  final cabecalho = context.request.headers[HttpHeaders.authorizationHeader];
  if (cabecalho == null || !cabecalho.startsWith('Bearer ')) {
    throw const NaoAutenticadoException();
  }
  final token = cabecalho.substring('Bearer '.length).trim();
  return context.read<TokenService>().validar(token);
}

/// Middleware para pastas em que TODAS as rotas exigem login
/// (`routes/doacoes`, `routes/proximas`, `routes/reservas`).
///
/// Depois dele, a rota obtém o usuário com
/// `context.read<UsuarioAutenticado>()`. "Seguro por padrão": nenhuma rota
/// nova da pasta fica aberta por esquecimento.
Middleware exigirAutenticacao() {
  return (handler) {
    return (context) {
      final usuario = autenticar(context);
      return handler(context.provide<UsuarioAutenticado>(() => usuario));
    };
  };
}
