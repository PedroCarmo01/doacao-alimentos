import '../erros/erro_amigavel.dart';

/// Erro vindo da API (ou da falta dela), já com mensagem em português.
///
/// O backend responde erros no formato
/// `{"erro": {"codigo": "...", "mensagem": "...", "detalhes": [...]}}`.
/// Os repositórios Fake lançam esta mesma exceção, com os mesmos códigos,
/// para que as telas funcionem igual nos dois modos.
class ApiException implements ErroAmigavel {
  const ApiException({
    required this.codigo,
    required this.mensagem,
    this.status,
    this.detalhes = const [],
  });

  const ApiException.semConexao()
      : this(
          codigo: 'SEM_CONEXAO',
          mensagem: 'Não foi possível falar com o servidor. Confira se a API '
              'está rodando e se o endereço (API_URL) está correto.',
        );

  const ApiException.tempoEsgotado()
      : this(
          codigo: 'TEMPO_ESGOTADO',
          mensagem: 'O servidor demorou demais para responder. Tente de novo.',
        );

  const ApiException.respostaInvalida()
      : this(
          codigo: 'RESPOSTA_INVALIDA',
          mensagem: 'O servidor respondeu em um formato inesperado.',
        );

  /// Código estável para decisões no código (ex.: `DOACAO_INDISPONIVEL`).
  final String codigo;

  @override
  final String mensagem;

  /// Status HTTP (`null` quando nem chegou ao servidor).
  final int? status;

  /// Mensagens por campo, quando o backend envia (erros de validação).
  final List<String> detalhes;

  /// O token expirou ou é inválido: é preciso entrar de novo.
  bool get sessaoExpirada => status == 401;

  @override
  String toString() => 'ApiException($codigo, $status): $mensagem';
}
