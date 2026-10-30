import 'package:geolocator/geolocator.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/erros/erro_amigavel.dart';

/// Problema ao obter a localização (GPS desligado, permissão negada...).
class LocalizacaoException implements ErroAmigavel {
  const LocalizacaoException(this.mensagem);

  @override
  final String mensagem;

  @override
  String toString() => mensagem;
}

/// CONTRATO: "onde estou agora?".
abstract interface class LocalizacaoService {
  /// Lança [LocalizacaoException] com mensagem amigável se não conseguir.
  Future<Coordenadas> obterAtual();

  /// Pede a permissão de localização ao Android (tela de boas-vindas T2).
  /// Devolve `true` se a pessoa permitiu. Nunca lança exceção.
  Future<bool> pedirPermissao();
}

/// GPS real do aparelho (pacote geolocator).
///
/// No Android exige as permissões de localização no AndroidManifest.xml
/// (trilha/10). No emulador, defina a posição em "Extended controls >
/// Location"; senão ele informa a Califórnia.
class LocalizacaoServiceGps implements LocalizacaoService {
  const LocalizacaoServiceGps();

  @override
  Future<Coordenadas> obterAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocalizacaoException(
        'Ative a localização (GPS) do aparelho e tente de novo.',
      );
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      throw const LocalizacaoException('Permissão de localização negada.');
    }
    if (permissao == LocationPermission.deniedForever) {
      throw const LocalizacaoException(
        'A permissão de localização foi bloqueada. Libere nas configurações '
        'do aparelho ou digite a latitude e a longitude.',
      );
    }
    final posicao = await Geolocator.getCurrentPosition();
    return Coordenadas(posicao.latitude, posicao.longitude);
  }

  @override
  Future<bool> pedirPermissao() async {
    try {
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      return permissao == LocationPermission.always ||
          permissao == LocationPermission.whileInUse;
    } catch (_) {
      // Ex.: o aparelho não tem GPS. A pessoa ainda pode usar o CEP.
      return false;
    }
  }
}

/// Posição fixa no centro de Mogi das Cruzes (mesma região do seed).
class LocalizacaoServiceFake implements LocalizacaoService {
  const LocalizacaoServiceFake();

  @override
  Future<Coordenadas> obterAtual() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const Coordenadas(-23.5235, -46.1870);
  }

  @override
  Future<bool> pedirPermissao() async => true;
}
