import '../regras_da_retirada.dart';
import '../reserva.dart';
import '../util/json.dart';

/// Corpo de `POST /reservas` ("Vou retirar").
class DadosReserva {
  const DadosReserva({required this.doacaoId});

  factory DadosReserva.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Reserva');
    return DadosReserva(doacaoId: j.inteiro('doacaoId'));
  }

  final int doacaoId;

  Map<String, dynamic> toJson() => {'doacaoId': doacaoId};
}

/// Corpo de `POST /reservas/{id}/confirmar`: o código que o doador digitou
/// (RN27).
class DadosConfirmacao {
  const DadosConfirmacao({required this.codigo});

  factory DadosConfirmacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Confirmação');
    return DadosConfirmacao(codigo: j.texto('codigo'));
  }

  final String codigo;

  Map<String, dynamic> toJson() => {'codigo': codigo};
}

/// Resposta de `DELETE /reservas/{id}` (a ONG desistiu): o app mostra se
/// contou como desistência e se a conta foi suspensa (RN22–RN24).
class RespostaDesistencia {
  const RespostaDesistencia({
    required this.contouDesistencia,
    required this.desistenciasRecentes,
    this.suspensaAte,
  });

  factory RespostaDesistencia.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'RespostaDesistencia');
    return RespostaDesistencia(
      contouDesistencia: j.booleano('contouDesistencia'),
      desistenciasRecentes: j.inteiro('desistenciasRecentes'),
      suspensaAte: j.instanteOpcional('suspensaAte'),
    );
  }

  /// `false` se foi dentro da tolerância (RN23).
  final bool contouDesistencia;

  /// Desistências que contam, dentro da janela da RN24 (já com esta).
  final int desistenciasRecentes;

  /// Preenchido se esta desistência suspendeu a ONG (RN24).
  final DateTime? suspensaAte;

  Map<String, dynamic> toJson() => {
    'contouDesistencia': contouDesistencia,
    'desistenciasRecentes': desistenciasRecentes,
    'suspensaAte': suspensaAte == null ? null : formatarInstante(suspensaAte!),
  };
}

/// Resposta de `GET /reservas/situacao-da-ong`: tudo o que o app precisa
/// para os avisos e para a faixa de retirada em andamento.
class SituacaoDaOng {
  const SituacaoDaOng({
    required this.desistenciasRecentes,
    required this.ativas,
    required this.regras,
    this.suspensaAte,
  });

  factory SituacaoDaOng.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'SituacaoDaOng');
    final ativas = json['ativas'];
    return SituacaoDaOng(
      desistenciasRecentes: j.inteiro('desistenciasRecentes'),
      suspensaAte: j.instanteOpcional('suspensaAte'),
      ativas: [
        if (ativas is List)
          for (final item in ativas)
            Reserva.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      regras: RegrasDaRetirada.fromJson(j.objeto('regras').mapa),
    );
  }

  /// Desistências que contam, nos últimos dias da RN24.
  final int desistenciasRecentes;
  final DateTime? suspensaAte;

  /// Retiradas em andamento (com o código).
  final List<Reserva> ativas;
  final RegrasDaRetirada regras;

  bool estaSuspensa(DateTime agora) =>
      suspensaAte != null && suspensaAte!.isAfter(agora);

  /// RN24: "Mais uma desistência e sua conta será suspensa".
  bool get proximaDesistenciaSuspende =>
      desistenciasRecentes == regras.desistenciasParaSuspender - 1;

  /// RN25: já tem o máximo de retiradas em andamento?
  bool get atingiuLimite => ativas.length >= regras.retiradasSimultaneas;

  Map<String, dynamic> toJson() => {
    'desistenciasRecentes': desistenciasRecentes,
    'suspensaAte': suspensaAte == null ? null : formatarInstante(suspensaAte!),
    'ativas': [for (final reserva in ativas) reserva.toJson()],
    'regras': regras.toJson(),
  };
}
