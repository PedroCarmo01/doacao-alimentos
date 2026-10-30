/// Erro de negócio que vira uma resposta HTTP com mensagem para o usuário.
///
/// POLIMORFISMO na prática: cada subclasse informa o próprio [statusHttp].
/// O middleware `tratarErros()` não precisa de `if` ou `switch` para cada
/// tipo; ele só pergunta à exceção qual é o status.
///
/// É `abstract class` (e não `sealed`) para que cada fatia possa criar as
/// próprias exceções em arquivos próprios, se precisar.
abstract class AppException implements Exception {
  const AppException(this.codigo, this.mensagem);

  /// Código estável para o app tomar decisões (ex.: `DOACAO_INDISPONIVEL`).
  final String codigo;

  /// Texto em português que pode ser mostrado ao usuário.
  final String mensagem;

  int get statusHttp;

  Map<String, Object?> toJson() => {
        'erro': {'codigo': codigo, 'mensagem': mensagem},
      };

  @override
  String toString() => '$runtimeType($codigo): $mensagem';
}

/// 400 — os dados enviados são inválidos.
class ValidacaoException extends AppException {
  const ValidacaoException(String mensagem, {this.detalhes = const []})
      : super('VALIDACAO', mensagem);

  /// Uma mensagem por problema encontrado (útil para formulários).
  final List<String> detalhes;

  @override
  int get statusHttp => 400;

  @override
  Map<String, Object?> toJson() => {
        'erro': {
          'codigo': codigo,
          'mensagem': mensagem,
          if (detalhes.isNotEmpty) 'detalhes': detalhes,
        },
      };
}

/// 401 — não está logado, ou o token é inválido/expirou.
class NaoAutenticadoException extends AppException {
  const NaoAutenticadoException({
    String codigo = 'NAO_AUTENTICADO',
    String mensagem = 'Faça login para continuar.',
  }) : super(codigo, mensagem);

  @override
  int get statusHttp => 401;
}

/// 403 — está logado, mas o perfil não pode fazer esta ação.
class SemPermissaoException extends AppException {
  const SemPermissaoException([
    String mensagem = 'Você não tem permissão para esta ação.',
  ]) : super('SEM_PERMISSAO', mensagem);

  @override
  int get statusHttp => 403;
}

/// 404 — o recurso não existe (ou o usuário não pode saber que existe).
class NaoEncontradoException extends AppException {
  const NaoEncontradoException([String mensagem = 'Recurso não encontrado.'])
      : super('NAO_ENCONTRADO', mensagem);

  @override
  int get statusHttp => 404;
}

/// 405 — a rota existe, mas não aceita esse método HTTP.
class MetodoNaoPermitidoException extends AppException {
  const MetodoNaoPermitidoException()
      : super('METODO_NAO_PERMITIDO', 'Método HTTP não aceito nesta rota.');

  @override
  int get statusHttp => 405;
}

/// 409 — a ação conflita com o estado atual (ex.: doação já reservada).
class ConflitoException extends AppException {
  const ConflitoException(super.codigo, super.mensagem);

  @override
  int get statusHttp => 409;
}
