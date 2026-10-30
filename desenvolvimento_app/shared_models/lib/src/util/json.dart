/// Ferramentas internas para ler e escrever JSON com mensagens claras.
///
/// Este arquivo NÃO é exportado pelo pacote: apenas os modelos daqui o usam.
library;

/// Lê campos de um mapa JSON, conferindo presença e tipo de cada um.
///
/// Quando um campo obrigatório falta ou vem com o tipo errado, lança
/// [FormatException] com uma mensagem em português. O backend transforma essa
/// exceção em resposta HTTP 400 (requisição inválida).
class LeitorJson {
  LeitorJson(this._json, {this.contexto = 'JSON'});

  final Map<String, dynamic> _json;

  /// Nome usado nas mensagens de erro (ex.: "Doacao").
  final String contexto;

  /// O mapa original, útil para repassar a outro `fromJson`.
  Map<String, dynamic> get mapa => _json;

  Never _erro(String chave, String problema) =>
      throw FormatException('$contexto: o campo "$chave" $problema.');

  String texto(String chave) {
    final valor = _json[chave];
    if (valor is String) return valor;
    _erro(chave, 'é obrigatório e deve ser um texto');
  }

  String? textoOpcional(String chave) {
    final valor = _json[chave];
    if (valor == null || valor is String) return valor as String?;
    _erro(chave, 'deve ser um texto');
  }

  int inteiro(String chave) {
    final valor = _json[chave];
    if (valor is int) return valor;
    if (valor is double && valor == valor.truncateToDouble()) {
      return valor.toInt();
    }
    _erro(chave, 'é obrigatório e deve ser um número inteiro');
  }

  int? inteiroOpcional(String chave) =>
      _json[chave] == null ? null : inteiro(chave);

  double decimal(String chave) {
    final valor = _json[chave];
    if (valor is num) return valor.toDouble();
    _erro(chave, 'é obrigatório e deve ser um número');
  }

  double? decimalOpcional(String chave) {
    final valor = _json[chave];
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    _erro(chave, 'deve ser um número');
  }

  bool booleano(String chave) {
    final valor = _json[chave];
    if (valor is bool) return valor;
    _erro(chave, 'é obrigatório e deve ser verdadeiro ou falso');
  }

  /// Instante (data + hora) em ISO-8601. Sempre devolvido em UTC.
  DateTime instante(String chave) {
    final valor = _json[chave];
    if (valor is String) {
      final data = DateTime.tryParse(valor);
      if (data != null) return data.toUtc();
    }
    _erro(chave, 'deve ser uma data/hora ISO-8601 (ex.: 2026-09-15T14:30:00Z)');
  }

  DateTime? instanteOpcional(String chave) =>
      _json[chave] == null ? null : instante(chave);

  /// Data de calendário (AAAA-MM-DD), sem horário.
  DateTime data(String chave) {
    final valor = _json[chave];
    if (valor is String) {
      final data = DateTime.tryParse(valor);
      if (data != null) return DateTime.utc(data.year, data.month, data.day);
    }
    _erro(chave, 'deve ser uma data no formato AAAA-MM-DD');
  }

  /// Converte o texto no valor do enum com o mesmo `name`.
  T enumerado<T extends Enum>(String chave, List<T> valores) {
    final valor = _json[chave];
    for (final opcao in valores) {
      if (opcao.name == valor) return opcao;
    }
    final aceitos = valores.map((opcao) => opcao.name).join(', ');
    _erro(chave, 'deve ser um destes valores: $aceitos');
  }

  T? enumeradoOpcional<T extends Enum>(String chave, List<T> valores) =>
      _json[chave] == null ? null : enumerado(chave, valores);

  LeitorJson objeto(String chave) {
    final valor = _json[chave];
    if (valor is Map) {
      return LeitorJson(
        Map<String, dynamic>.from(valor),
        contexto: '$contexto.$chave',
      );
    }
    _erro(chave, 'é obrigatório e deve ser um objeto');
  }

  LeitorJson? objetoOpcional(String chave) =>
      _json[chave] == null ? null : objeto(chave);
}

/// Formata uma data de calendário como AAAA-MM-DD.
String formatarData(DateTime data) {
  String dois(int numero) => numero.toString().padLeft(2, '0');
  final ano = data.year.toString().padLeft(4, '0');
  return '$ano-${dois(data.month)}-${dois(data.day)}';
}

/// Formata um instante em ISO-8601 UTC (termina com "Z").
String formatarInstante(DateTime instante) =>
    instante.toUtc().toIso8601String();
