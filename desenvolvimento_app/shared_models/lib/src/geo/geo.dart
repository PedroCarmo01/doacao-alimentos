import 'dart:math' as math;

/// Par latitude/longitude.
///
/// É um **objeto de valor**: dois objetos com os mesmos números são iguais
/// (por isso sobrescrevemos `==` e `hashCode`).
class Coordenadas {
  const Coordenadas(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Latitude entre -90 e 90 e longitude entre -180 e 180.
  bool get valida =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  @override
  bool operator ==(Object other) =>
      other is Coordenadas &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => '($latitude, $longitude)';
}

/// Cálculos geográficos.
///
/// `abstract final class` com membros `static`: um "módulo" de funções
/// utilitárias que não pode ser instanciado nem herdado.
abstract final class Geo {
  static const raioTerraKm = 6371.0;

  /// Distância em quilômetros entre dois pontos (fórmula de Haversine).
  static double distanciaKm(Coordenadas a, Coordenadas b) {
    final dLat = _radianos(b.latitude - a.latitude);
    final dLon = _radianos(b.longitude - a.longitude);
    final senoLat = math.sin(dLat / 2);
    final senoLon = math.sin(dLon / 2);
    final h = senoLat * senoLat +
        math.cos(_radianos(a.latitude)) *
            math.cos(_radianos(b.latitude)) *
            senoLon *
            senoLon;
    return 2 * raioTerraKm * math.asin(math.min(1.0, math.sqrt(h)));
  }

  static double _radianos(double graus) => graus * math.pi / 180;
}
