/// Fonte do "agora".
///
/// Em vez de chamar `DateTime.now()` dentro das regras de negócio, as classes
/// recebem um [Relogio] pelo construtor. Em produção usamos [RelogioSistema];
/// nos testes, [RelogioFixo], que permite "avançar o tempo" e testar a
/// expiração de uma reserva em milissegundos.
abstract interface class Relogio {
  /// Instante atual, sempre em UTC.
  DateTime agora();
}

/// Relógio real do computador ou celular.
class RelogioSistema implements Relogio {
  const RelogioSistema();

  @override
  DateTime agora() => DateTime.now().toUtc();
}

/// Relógio controlado manualmente, para testes.
class RelogioFixo implements Relogio {
  RelogioFixo(DateTime inicio) : _instante = inicio.toUtc();

  DateTime _instante;

  @override
  DateTime agora() => _instante;

  void avancar(Duration tempo) => _instante = _instante.add(tempo);

  void definir(DateTime instante) => _instante = instante.toUtc();
}

/// Operações com datas de calendário (dia, sem horário).
abstract final class Calendario {
  /// Data de calendário (dia) de [instante] em um fuso com [fusoHorasUtc]
  /// horas de diferença do UTC. Exemplo: Brasília = -3.
  ///
  /// Às 01:30 UTC do dia 16, ainda são 22:30 do dia 15 em Brasília.
  static DateTime dataNoFuso(DateTime instante, int fusoHorasUtc) {
    final local = instante.toUtc().add(Duration(hours: fusoHorasUtc));
    return DateTime.utc(local.year, local.month, local.day);
  }

  /// Apenas o dia (ano, mês, dia) de [data], como data UTC.
  static DateTime somenteData(DateTime data) =>
      DateTime.utc(data.year, data.month, data.day);
}
