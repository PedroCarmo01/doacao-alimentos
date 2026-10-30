import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('Geo', () {
    test('mesmo ponto tem distância zero', () {
      const ponto = Coordenadas(-23.5229, -46.1880);
      expect(Geo.distanciaKm(ponto, ponto), 0);
    });

    test('1 grau de longitude no Equador mede cerca de 111,19 km', () {
      final distancia = Geo.distanciaKm(
        const Coordenadas(0, 0),
        const Coordenadas(0, 1),
      );
      expect(distancia, closeTo(111.19, 0.01));
    });

    test('coordenadas fora da faixa são inválidas', () {
      expect(const Coordenadas(91, 0).valida, isFalse);
      expect(const Coordenadas(-23.5, -46.6).valida, isTrue);
    });
  });

  group('Relogio e Calendario', () {
    test('RelogioFixo permite avançar o tempo', () {
      final relogio = RelogioFixo(DateTime.utc(2026, 9, 15, 10));

      relogio.avancar(const Duration(minutes: 30));

      expect(relogio.agora(), DateTime.utc(2026, 9, 15, 10, 30));
    });

    test('dataNoFuso: 01:30 UTC do dia 16 ainda é dia 15 em Brasília', () {
      final dia = Calendario.dataNoFuso(DateTime.utc(2026, 9, 16, 1, 30), -3);
      expect(dia, DateTime.utc(2026, 9, 15));
    });
  });
}
