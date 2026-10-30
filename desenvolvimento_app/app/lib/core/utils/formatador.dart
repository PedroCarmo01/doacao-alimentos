/// Formatação de datas, durações e distâncias para exibir na tela.
///
/// As datas chegam da API em UTC; aqui são convertidas para o horário do
/// aparelho com `toLocal()` (docs/adr/ADR-010).
abstract final class Formatador {
  static String _dois(int numero) => numero.toString().padLeft(2, '0');

  /// `16/09/2026`
  static String data(DateTime data) {
    final local = data.isUtc && (data.hour != 0 || data.minute != 0)
        ? data.toLocal()
        : data;
    return '${_dois(local.day)}/${_dois(local.month)}/${local.year}';
  }

  /// `14:30` no horário do aparelho.
  static String hora(DateTime instante) {
    final local = instante.toLocal();
    return '${_dois(local.hour)}:${_dois(local.minute)}';
  }

  /// `16/09 14:30` no horário do aparelho.
  static String diaHora(DateTime instante) {
    final local = instante.toLocal();
    return '${_dois(local.day)}/${_dois(local.month)} ${hora(local)}';
  }

  /// `01:59:30`
  static String duracao(Duration duracao) =>
      '${_dois(duracao.inHours)}:${_dois(duracao.inMinutes % 60)}:'
      '${_dois(duracao.inSeconds % 60)}';

  /// Contador regressivo: `58:41` ou, com 1 hora ou mais, `1:02:05`.
  static String contador(Duration duracao) {
    final minutosESegundos =
        '${_dois(duracao.inMinutes % 60)}:${_dois(duracao.inSeconds % 60)}';
    if (duracao.inHours == 0) return minutosESegundos;
    return '${duracao.inHours}:$minutosESegundos';
  }

  /// `42 min` ou `1 h 05 min` (prazos de retirada).
  static String duracaoCurta(Duration duracao) {
    final minutos = duracao.inMinutes % 60;
    if (duracao.inHours == 0) return '${duracao.inMinutes} min';
    return '${duracao.inHours} h ${_dois(minutos)} min';
  }

  /// `6 kg` ou `4,8 kg`
  static String peso(double kg) {
    final inteiro = kg == kg.truncateToDouble();
    final numero = inteiro
        ? kg.toStringAsFixed(0)
        : kg.toStringAsFixed(1).replaceAll('.', ',');
    return '$numero kg';
  }

  /// `850 m` ou `2,4 km`
  static String distancia(double km) => km < 1
      ? '${(km * 1000).round()} m'
      : '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}
