import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../config/env.dart';
import '../erros/app_exception.dart';

/// Converte qualquer exceção em uma resposta JSON padronizada:
/// `{"erro": {"codigo": "...", "mensagem": "..."}}`.
///
/// - [AppException]: usa o status da própria exceção (polimorfismo).
/// - `FormatException`: vem do `fromJson` dos contratos → 400.
/// - Qualquer outra coisa é um BUG: registra no terminal e responde 500 sem
///   expor detalhes internos ao cliente.
Middleware tratarErros() {
  return (handler) {
    return (context) async {
      try {
        return await handler(context);
      } on AppException catch (erro) {
        return Response.json(statusCode: erro.statusHttp, body: erro.toJson());
      } on FormatException catch (erro) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: ValidacaoException(erro.message).toJson(),
        );
      } catch (erro, pilha) {
        final requisicao = context.request;
        stderr.writeln(
          '[ERRO 500] ${requisicao.method.name.toUpperCase()} '
          '${requisicao.uri.path}\n$erro\n$pilha',
        );
        return Response.json(
          statusCode: HttpStatus.internalServerError,
          body: const {
            'erro': {
              'codigo': 'ERRO_INTERNO',
              'mensagem': 'Erro inesperado no servidor. Tente novamente.',
            },
          },
        );
      }
    };
  };
}

/// Libera o acesso a partir de navegadores (CORS).
///
/// Só é necessário quando o app roda no Chrome (`flutter run -d chrome`);
/// no Android ele não faz diferença. A origem vem do `.env` (`CORS_ORIGEM`).
Middleware cors() {
  return (handler) {
    return (context) async {
      final cabecalhos = {
        'Access-Control-Allow-Origin': context.read<Env>().corsOrigem,
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
      };
      if (context.request.method == HttpMethod.options) {
        return Response(statusCode: HttpStatus.noContent, headers: cabecalhos);
      }
      final resposta = await handler(context);
      return resposta.copyWith(headers: {...resposta.headers, ...cabecalhos});
    };
  };
}
