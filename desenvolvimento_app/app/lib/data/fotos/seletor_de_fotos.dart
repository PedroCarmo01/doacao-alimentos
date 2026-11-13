import 'package:image_picker/image_picker.dart';

/// Uma foto escolhida no celular, pronta para enviar.
class FotoEscolhida {
  const FotoEscolhida({
    required this.bytes,
    required this.caminho,
    required this.nome,
  });

  final List<int> bytes;

  /// Onde o arquivo está no celular (usado para mostrar a prévia).
  final String caminho;
  final String nome;
}

/// CONTRATO: tirar uma foto ou escolher uma da galeria (T11).
abstract interface class SeletorDeFotos {
  /// `null` se a pessoa desistiu.
  Future<FotoEscolhida?> tirarFoto();

  /// `null` se a pessoa desistiu.
  Future<FotoEscolhida?> escolherDaGaleria();
}

/// Câmera e galeria do celular (pacote image_picker).
///
/// O próprio image_picker REDUZ a foto antes de entregar: no máximo 1280 px
/// de largura e qualidade 75 (03-DADOS-E-API.md). Assim cada foto fica com
/// poucas centenas de KB e o envio é rápido até no 4G.
class SeletorDeFotosDoAparelho implements SeletorDeFotos {
  SeletorDeFotosDoAparelho([ImagePicker? seletor])
    : _seletor = seletor ?? ImagePicker();

  static const larguraMaxima = 1280.0;
  static const qualidade = 75;

  final ImagePicker _seletor;

  @override
  Future<FotoEscolhida?> tirarFoto() => _escolher(ImageSource.camera);

  @override
  Future<FotoEscolhida?> escolherDaGaleria() => _escolher(ImageSource.gallery);

  Future<FotoEscolhida?> _escolher(ImageSource origem) async {
    final arquivo = await _seletor.pickImage(
      source: origem,
      maxWidth: larguraMaxima,
      maxHeight: larguraMaxima,
      imageQuality: qualidade,
    );
    if (arquivo == null) return null;
    return FotoEscolhida(
      bytes: await arquivo.readAsBytes(),
      caminho: arquivo.path,
      nome: arquivo.name,
    );
  }
}

/// Para testes: sempre devolve a mesma "foto" (os bytes iniciais de um
/// JPEG), sem abrir câmera nem galeria.
class SeletorDeFotosFake implements SeletorDeFotos {
  const SeletorDeFotosFake();

  static const foto = FotoEscolhida(
    bytes: [0xFF, 0xD8, 0xFF, 0xE0, 0, 1, 2, 3],
    caminho: 'assets/exemplos/paes.jpg',
    nome: 'foto.jpg',
  );

  @override
  Future<FotoEscolhida?> tirarFoto() async => foto;

  @override
  Future<FotoEscolhida?> escolherDaGaleria() async => foto;
}
