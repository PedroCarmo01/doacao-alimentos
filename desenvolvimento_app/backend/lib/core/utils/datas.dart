/// Conversões de datas entre o Dart e o MySQL.
///
/// Regra do projeto (docs/adr/ADR-010): todo `DATETIME` no banco guarda um
/// instante em UTC. A conversão para o horário local acontece só no app, na
/// hora de exibir.
abstract final class Datas {
  /// Instante → `DATETIME` do MySQL em UTC (`2026-09-15 14:30:00`).
  static String paraSql(DateTime instante) {
    final utc = instante.toUtc();
    return '${_data(utc)} ${_dois(utc.hour)}:${_dois(utc.minute)}:'
        '${_dois(utc.second)}';
  }

  /// Data de calendário → `DATE` do MySQL (`2026-09-15`).
  static String dataParaSql(DateTime data) => _data(data);

  /// `DATETIME` do MySQL (em UTC) → instante em UTC.
  static DateTime deSql(String texto) =>
      DateTime.parse('${texto.trim().replaceFirst(' ', 'T')}Z');

  /// `DATE` do MySQL → data de calendário (meia-noite UTC).
  static DateTime dataDeSql(String texto) {
    final data = DateTime.parse(texto.trim());
    return DateTime.utc(data.year, data.month, data.day);
  }

  static String _data(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-${_dois(data.month)}-'
      '${_dois(data.day)}';

  static String _dois(int numero) => numero.toString().padLeft(2, '0');
}
