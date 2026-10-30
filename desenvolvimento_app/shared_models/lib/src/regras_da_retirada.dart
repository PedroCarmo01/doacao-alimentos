import 'util/json.dart';

/// Os números configuráveis das regras de aceite e retirada (RN21–RN27).
///
/// No backend, vêm do `.env`. O servidor envia estes números para o app em
/// `GET /reservas/situacao-da-ong`, e assim os avisos da tela ("Você terá
/// 60 minutos...") sempre batem com o que o servidor vai aplicar.
class RegrasDaRetirada {
  const RegrasDaRetirada({
    this.prazo = const Duration(minutes: 60),
    this.tolerancia = const Duration(minutes: 5),
    this.desistenciasParaSuspender = 3,
    this.janelaDesistencias = const Duration(days: 30),
    this.suspensao = const Duration(hours: 48),
    this.retiradasSimultaneas = 2,
  });

  factory RegrasDaRetirada.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'RegrasDaRetirada');
    return RegrasDaRetirada(
      prazo: Duration(minutes: j.inteiro('prazoMinutos')),
      tolerancia: Duration(minutes: j.inteiro('toleranciaMinutos')),
      desistenciasParaSuspender: j.inteiro('desistenciasParaSuspender'),
      janelaDesistencias: Duration(days: j.inteiro('janelaDesistenciasDias')),
      suspensao: Duration(hours: j.inteiro('suspensaoHoras')),
      retiradasSimultaneas: j.inteiro('retiradasSimultaneas'),
    );
  }

  /// RN21: tempo que a ONG tem para retirar (RESERVA_MINUTOS).
  final Duration prazo;

  /// RN23: desistir até este tempo depois de aceitar não conta.
  final Duration tolerancia;

  /// RN24: quantas desistências suspendem a ONG...
  final int desistenciasParaSuspender;

  /// ...dentro de quantos dias...
  final Duration janelaDesistencias;

  /// ...e por quanto tempo.
  final Duration suspensao;

  /// RN25: máximo de retiradas em andamento ao mesmo tempo.
  final int retiradasSimultaneas;

  /// RN27: erros seguidos do código antes de bloquear as tentativas.
  static const tentativasDoCodigo = 5;

  /// RN27: quanto tempo as tentativas ficam bloqueadas.
  static const bloqueioDoCodigo = Duration(minutes: 10);

  /// RN21: o prazo é o MENOR entre "agora + prazo" e o fim do horário de
  /// retirada que o doador ofereceu.
  DateTime prazoFinal({required DateTime agora, required DateTime janelaFim}) {
    final limite = agora.add(prazo);
    return limite.isBefore(janelaFim) ? limite : janelaFim;
  }

  Map<String, dynamic> toJson() => {
    'prazoMinutos': prazo.inMinutes,
    'toleranciaMinutos': tolerancia.inMinutes,
    'desistenciasParaSuspender': desistenciasParaSuspender,
    'janelaDesistenciasDias': janelaDesistencias.inDays,
    'suspensaoHoras': suspensao.inHours,
    'retiradasSimultaneas': retiradasSimultaneas,
  };
}
