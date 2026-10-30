import 'dart:math' as math;

import 'package:shared_models/shared_models.dart';

/// Retângulo de latitude/longitude que contém o círculo de busca da ONG.
///
/// Por que um retângulo, se a busca é num círculo? Porque o banco filtra
/// retângulos muito rápido (com o índice `idx_doacoes_localizacao`). Depois,
/// no Dart, a distância exata tira as doações dos "cantos" do retângulo.
///
/// Objeto de VALOR imutável: criado uma vez, nunca alterado.
class AreaDeBusca {
  const AreaDeBusca({
    required this.latitudeMin,
    required this.latitudeMax,
    required this.longitudeMin,
    required this.longitudeMax,
  });

  /// Construtor nomeado ("factory"): esconde a matemática de quem usa.
  factory AreaDeBusca.aoRedor(Coordenadas centro, double raioKm) {
    // Um grau de latitude tem sempre ~111 km. Um grau de longitude encolhe
    // quanto mais longe do Equador (por isso o cosseno).
    const kmPorGrauLatitude = 111.32;
    final deltaLatitude = raioKm / kmPorGrauLatitude;
    final cosseno = math.cos(centro.latitude * math.pi / 180).abs();
    // Perto dos polos o cosseno tende a zero; o max evita divisão por zero.
    final deltaLongitude =
        raioKm / (kmPorGrauLatitude * math.max(cosseno, 0.01));
    return AreaDeBusca(
      latitudeMin: centro.latitude - deltaLatitude,
      latitudeMax: centro.latitude + deltaLatitude,
      longitudeMin: centro.longitude - deltaLongitude,
      longitudeMax: centro.longitude + deltaLongitude,
    );
  }

  final double latitudeMin;
  final double latitudeMax;
  final double longitudeMin;
  final double longitudeMax;

  bool contem(Coordenadas ponto) =>
      ponto.latitude >= latitudeMin &&
      ponto.latitude <= latitudeMax &&
      ponto.longitude >= longitudeMin &&
      ponto.longitude <= longitudeMax;
}
