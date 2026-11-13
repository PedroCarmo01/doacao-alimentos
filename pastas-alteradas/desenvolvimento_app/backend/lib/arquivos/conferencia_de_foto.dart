import '../core/erros/app_exception.dart';
import 'armazenamento_de_fotos.dart';

/// Confere uma foto recebida antes de salvar: não vazia, até 2 MB e JPEG
/// ou PNG de verdade (pelos primeiros bytes, não pelo nome do arquivo).
///
/// Usada pelas fotos das doações e das publicações da Comunidade.
abstract final class ConferenciaDeFoto {
  /// O app já envia a foto reduzida (1280 px, qualidade 75), que fica
  /// bem abaixo disso. O limite protege o servidor de arquivos enormes.
  static const tamanhoMaximoBytes = 2 * 1024 * 1024;

  /// Devolve o formato ou lança [ValidacaoException] com o motivo.
  static FormatoDeFoto conferir(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const ValidacaoException('Escolha uma foto para enviar.');
    }
    if (bytes.length > tamanhoMaximoBytes) {
      throw const ValidacaoException(
        'A foto passou de 2 MB. Tire outra ou escolha uma menor.',
      );
    }
    return FormatoDeFoto.dosBytes(bytes) ??
        (throw const ValidacaoException('Envie uma foto em JPEG ou PNG.'));
  }
}
