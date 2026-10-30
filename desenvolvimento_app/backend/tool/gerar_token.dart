import 'dart:io';

import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/config/env.dart';
import 'package:summit_backend/core/seguranca/token_service.dart';

/// Gera um token JWT de teste sem precisar fazer login.
///
/// Serve para testar rotas protegidas ANTES de o login (Pessoa 1) ficar
/// pronto. Rode o seed antes, para que o usuário exista no banco.
///
/// Uso, dentro da pasta `backend`:
///
///     dart run tool/gerar_token.dart 1 doador
///     dart run tool/gerar_token.dart 3 ong
void main(List<String> argumentos) {
  const uso = 'Uso: dart run tool/gerar_token.dart <idDoUsuario> <doador|ong>';
  if (argumentos.length != 2) {
    print(uso);
    exitCode = 64;
    return;
  }

  final id = int.tryParse(argumentos[0]);
  final tipo = TipoUsuario.values
      .where((opcao) => opcao.name == argumentos[1])
      .firstOrNull;
  if (id == null || tipo == null) {
    print(uso);
    exitCode = 64;
    return;
  }

  final env = Env.carregar();
  final token = TokenService(segredo: env.jwtSegredo, validade: env.jwtValidade)
      .gerar(usuarioId: id, tipo: tipo);

  print('Token do usuário $id (${tipo.name}), válido por '
      '${env.jwtValidade.inHours} h:\n');
  print(token);
  print('\nUse no cabeçalho:  Authorization: Bearer $token');
}
