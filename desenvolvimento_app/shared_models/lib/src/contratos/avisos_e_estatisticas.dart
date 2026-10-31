import '../util/json.dart';

/// Quais avisos a pessoa quer receber (T50). Os avisos importantes da
/// retirada (aceite, prazo, código, suspensão) chegam sempre.
class PreferenciasDeAviso {
  const PreferenciasDeAviso({
    this.doacoes = true,
    this.mensagens = true,
    this.comunidade = true,
  });

  factory PreferenciasDeAviso.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'PreferenciasDeAviso');
    return PreferenciasDeAviso(
      doacoes: j.booleano('doacoes'),
      mensagens: j.booleano('mensagens'),
      comunidade: j.booleano('comunidade'),
    );
  }

  /// ONG: "doação nova perto" e "disponível de novo".
  final bool doacoes;

  /// Mensagem nova no chat.
  final bool mensagens;

  /// Alguém apoiou uma publicação minha.
  final bool comunidade;

  Map<String, dynamic> toJson() => {
    'doacoes': doacoes,
    'mensagens': mensagens,
    'comunidade': comunidade,
  };
}

/// Os números do Perfil (T50). Doador: doações e kg doados. ONG:
/// retiradas, kg recebidos, comparecimento e desistências.
class EstatisticasDoPerfil {
  const EstatisticasDoPerfil({
    required this.concluidas,
    required this.kg,
    this.comparecimento,
    this.desistenciasRecentes,
  });

  factory EstatisticasDoPerfil.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'EstatisticasDoPerfil');
    return EstatisticasDoPerfil(
      concluidas: j.inteiro('concluidas'),
      kg: j.decimal('kg'),
      comparecimento: j.decimalOpcional('comparecimento'),
      desistenciasRecentes: j.inteiroOpcional('desistenciasRecentes'),
    );
  }

  /// Doações entregues (doador) ou retiradas feitas (ONG).
  final int concluidas;

  /// Kg doados (doador) ou recebidos (ONG).
  final double kg;

  /// Só ONG: de 0 a 1, as retiradas concluídas sobre as que contaram
  /// (concluídas + desistências). `null` se ainda não aceitou nenhuma.
  final double? comparecimento;

  /// Só ONG: desistências nos últimos 30 dias (RN24).
  final int? desistenciasRecentes;

  Map<String, dynamic> toJson() => {
    'concluidas': concluidas,
    'kg': kg,
    'comparecimento': comparecimento,
    'desistenciasRecentes': desistenciasRecentes,
  };
}
