import 'doacao.dart';
import 'reserva.dart';
import 'tipos_de_perfil.dart';
import 'util/json.dart';

/// O pouco que um lado precisa saber do outro: o doador vê a ONG que vai
/// retirar (T12) e a ONG vê o doador (T22).
class ResumoOrganizacao {
  const ResumoOrganizacao({
    required this.usuarioId,
    required this.nomeOrganizacao,
    required this.verificacao,
    this.nomeResponsavel,
    this.telefone,
    this.tipoEstabelecimento,
    this.transporte,
  });

  factory ResumoOrganizacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'ResumoOrganizacao');
    return ResumoOrganizacao(
      usuarioId: j.inteiro('usuarioId'),
      nomeOrganizacao: j.texto('nomeOrganizacao'),
      verificacao: j.enumerado('verificacao', Verificacao.values),
      nomeResponsavel: j.textoOpcional('nomeResponsavel'),
      telefone: j.textoOpcional('telefone'),
      tipoEstabelecimento: j.enumeradoOpcional(
        'tipoEstabelecimento',
        TipoEstabelecimento.values,
      ),
      transporte: j.enumeradoOpcional('transporte', Transporte.values),
    );
  }

  final int usuarioId;
  final String nomeOrganizacao;
  final Verificacao verificacao;
  final String? nomeResponsavel;
  final String? telefone;
  final TipoEstabelecimento? tipoEstabelecimento;
  final Transporte? transporte;

  Map<String, dynamic> toJson() => {
    'usuarioId': usuarioId,
    'nomeOrganizacao': nomeOrganizacao,
    'verificacao': verificacao.name,
    'nomeResponsavel': nomeResponsavel,
    'telefone': telefone,
    'tipoEstabelecimento': tipoEstabelecimento?.name,
    'transporte': transporte?.name,
  };
}

/// Resposta de `GET /doacoes/{id}`: a doação, a retirada em andamento (se
/// houver) e os dados de quem está do outro lado.
class DetalheDoacao {
  const DetalheDoacao({
    required this.doacao,
    this.reserva,
    this.doador,
    this.ong,
  });

  factory DetalheDoacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'DetalheDoacao');
    final reserva = j.objetoOpcional('reserva');
    final doador = j.objetoOpcional('doador');
    final ong = j.objetoOpcional('ong');
    return DetalheDoacao(
      doacao: Doacao.fromJson(j.objeto('doacao').mapa),
      reserva: reserva == null ? null : Reserva.fromJson(reserva.mapa),
      doador: doador == null ? null : ResumoOrganizacao.fromJson(doador.mapa),
      ong: ong == null ? null : ResumoOrganizacao.fromJson(ong.mapa),
    );
  }

  final Doacao doacao;

  /// A retirada ATIVA, se houver.
  final Reserva? reserva;
  final ResumoOrganizacao? doador;

  /// A ONG da retirada ativa (só para o doador).
  final ResumoOrganizacao? ong;

  Map<String, dynamic> toJson() => {
    'doacao': doacao.toJson(),
    'reserva': reserva?.toJson(),
    'doador': doador?.toJson(),
    'ong': ong?.toJson(),
  };
}
