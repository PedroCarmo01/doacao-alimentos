import 'dart:io';
import 'dart:math';

/// Os dois formatos de foto aceitos, descobertos pelos primeiros bytes do
/// arquivo (a "assinatura"). Não confiamos no nome nem no tipo que o app
/// diz que mandou: qualquer um pode renomear um arquivo para ".jpg".
enum FormatoDeFoto {
  jpg('image/jpeg'),
  png('image/png');

  const FormatoDeFoto(this.tipoMime);

  /// Valor do cabeçalho `Content-Type` ao devolver a foto.
  final String tipoMime;

  /// JPEG começa com FF D8 FF; PNG com 89 50 4E 47 ("‰PNG").
  /// Devolve `null` se não for nenhum dos dois.
  static FormatoDeFoto? dosBytes(List<int> bytes) {
    if (bytes.length < 4) return null;
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return FormatoDeFoto.jpg;
    }
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E) {
      return FormatoDeFoto.png;
    }
    return null;
  }

  /// Pela extensão do nome salvo ("abc.png" → png).
  static FormatoDeFoto? doNome(String nome) {
    for (final formato in values) {
      if (nome.endsWith('.${formato.name}')) return formato;
    }
    return null;
  }
}

/// CONTRATO: onde as fotos das doações ficam guardadas.
///
/// Hoje é uma pasta do próprio servidor ([ArmazenamentoEmPasta]). Se um dia
/// o projeto usar um serviço na nuvem, basta criar outra implementação e
/// trocar UMA linha no `main.dart` (polimorfismo).
abstract interface class ArmazenamentoDeFotos {
  /// Guarda os bytes com um nome aleatório e devolve esse nome
  /// (ex.: `3f2a9c...e1.jpg`).
  Future<String> salvar(List<int> bytes, FormatoDeFoto formato);

  /// Os bytes da foto, ou `null` se o nome não existir.
  Future<List<int>?> ler(String nome);
}

/// Guarda as fotos numa pasta (padrão: `backend/arquivos/`, fora do Git).
class ArmazenamentoEmPasta implements ArmazenamentoDeFotos {
  ArmazenamentoEmPasta(String caminho) : _pasta = Directory(caminho);

  final Directory _pasta;
  final Random _sorteio = Random.secure();

  /// Só aceita nomes no formato que NÓS geramos: 32 letras/números
  /// hexadecimais + extensão. Isso impede "../../.env" (path traversal).
  static final formatoDoNome = RegExp(r'^[0-9a-f]{32}\.(jpg|png)$');

  @override
  Future<String> salvar(List<int> bytes, FormatoDeFoto formato) async {
    await _pasta.create(recursive: true);
    final nome = '${_nomeAleatorio()}.${formato.name}';
    await File('${_pasta.path}/$nome').writeAsBytes(bytes, flush: true);
    return nome;
  }

  @override
  Future<List<int>?> ler(String nome) async {
    if (!formatoDoNome.hasMatch(nome)) return null;
    final arquivo = File('${_pasta.path}/$nome');
    if (!await arquivo.exists()) return null;
    return arquivo.readAsBytes();
  }

  /// 16 bytes aleatórios em hexadecimal = 32 caracteres. A chance de dois
  /// nomes repetirem é praticamente zero.
  String _nomeAleatorio() => [
    for (var i = 0; i < 16; i++)
      _sorteio.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
