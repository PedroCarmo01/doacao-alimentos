import 'package:summit_backend/core/utils/datas.dart';
import 'package:test/test.dart';

void main() {
  group('Datas', () {
    test('paraSql converte para UTC no formato do MySQL', () {
      // 11:30 em Brasília (-03:00) são 14:30 em UTC.
      final instante = DateTime.parse('2026-09-15T11:30:00-03:00');

      expect(Datas.paraSql(instante), '2026-09-15 14:30:00');
    });

    test('deSql lê o DATETIME do banco como UTC', () {
      final instante = Datas.deSql('2026-09-15 14:30:00');

      expect(instante.isUtc, isTrue);
      expect(instante, DateTime.utc(2026, 9, 15, 14, 30));
    });

    test('ida e volta não altera o instante', () {
      final original = DateTime.utc(2026, 1, 2, 3, 4, 5);

      expect(Datas.deSql(Datas.paraSql(original)), original);
    });

    test('datas de calendário (DATE) não mudam de dia', () {
      expect(Datas.dataParaSql(DateTime.utc(2026, 9, 5)), '2026-09-05');
      expect(Datas.dataDeSql('2026-09-05'), DateTime.utc(2026, 9, 5));
    });
  });
}
