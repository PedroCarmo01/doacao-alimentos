import 'package:dart_frog/dart_frog.dart';

import '../erros/app_exception.dart';

/// Atalhos para ler dados da requisição com segurança.
///
/// Uma `extension` acrescenta métodos a uma classe que não é nossa (aqui, o
/// `RequestContext` do Dart Frog), sem precisar de herança. Uso nas rotas:
/// `final json = await context.lerJson();`
extension LeituraDaRequisicao on RequestContext {
  /// Lê o corpo como objeto JSON. Corpo vazio, malformado ou que não seja
  /// um objeto vira erro 400 com mensagem clara.
  Future<Map<String, dynamic>> lerJson() async {
    final corpo = await _lerCorpo();
    if (corpo is Map<String, dynamic>) return corpo;
    throw const ValidacaoException(
      'O corpo da requisição deve ser um objeto JSON, por exemplo '
      '{"campo": "valor"}.',
    );
  }

  Future<Object?> _lerCorpo() async {
    try {
      return await request.json();
    } on FormatException {
      throw const ValidacaoException(
        'O corpo da requisição não é um JSON válido.',
      );
    }
  }

  /// Parâmetro numérico opcional da URL, como `?raioKm=5`.
  double? parametroDecimal(String nome) {
    final valor = request.uri.queryParameters[nome];
    if (valor == null || valor.isEmpty) return null;
    return double.tryParse(valor.replaceAll(',', '.')) ??
        (throw ValidacaoException('O parâmetro "$nome" deve ser um número.'));
  }
}

/// Converte o trecho dinâmico da rota (o `[id]` de `routes/doacoes/[id].dart`)
/// em número. Um id que não é número é tratado como "não encontrado".
int idDaRota(String valor) =>
    int.tryParse(valor) ?? (throw const NaoEncontradoException());
