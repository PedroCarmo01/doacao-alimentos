import 'package:shared_models/shared_models.dart';

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

  /// Lista de conversas: `14:30` se for de hoje; senão, `16/09`.
  static String horaOuDia(DateTime instante, {required DateTime agora}) {
    final local = instante.toLocal();
    final hoje = agora.toLocal();
    final mesmoDia =
        local.year == hoje.year &&
        local.month == hoje.month &&
        local.day == hoje.day;
    return mesmoDia
        ? hora(instante)
        : '${_dois(local.day)}/${_dois(local.month)}';
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

  /// `30 unidades • 6 kg`. Se a unidade já é kg, só `4 kg` (sem repetir).
  static String quantidadeEPeso(Doacao doacao) => doacao.unidade == Unidade.kg
      ? doacao.quantidadeTexto
      : '${doacao.quantidadeTexto} • ${peso(doacao.pesoKg)}';

  /// `6 kg` ou `4,8 kg`
  static String peso(double kg) {
    // Arredonda ANTES de decidir se é inteiro: 4,96 é "5 kg", não "5,0 kg".
    final arredondado = (kg * 10).round() / 10;
    final inteiro = arredondado == arredondado.truncateToDouble();
    final numero = inteiro
        ? arredondado.toStringAsFixed(0)
        : arredondado.toStringAsFixed(1).replaceAll('.', ',');
    return '$numero kg';
  }

  /// `850 m` ou `2,4 km`
  static String distancia(double km) {
    // Decide pelos metros JÁ arredondados: 999,6 m aparecia como "1000 m".
    final metros = (km * 1000).round();
    if (metros < 1000) return '$metros m';
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}
