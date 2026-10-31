import 'contratos/avisos_e_estatisticas.dart';
import 'geo/geo.dart';
import 'tipos_de_perfil.dart';
import 'usuario.dart';
import 'util/json.dart';

/// Dados da organização: estabelecimento doador ou ONG.
///
/// Relação 1:1 com [Usuario]: o [usuarioId] também identifica o perfil
/// (no banco, é a chave primária da tabela `perfis`).
///
/// Alguns campos só fazem sentido para um dos tipos:
/// - só doador: [tipoEstabelecimento];
/// - só ONG: [familiasAtendidas], [transporte], [buscaAtiva], [raioKm],
///   [suspensaAte].
class Perfil {
  const Perfil({
    required this.usuarioId,
    required this.nomeOrganizacao,
    required this.tipoDocumento,
    required this.documento,
    required this.latitude,
    required this.longitude,
    this.verificacao = Verificacao.pendente,
    this.tipoEstabelecimento,
    this.razaoSocial,
    this.telefone,
    this.endereco,
    this.cep,
    this.familiasAtendidas,
    this.transporte,
    this.buscaAtiva = true,
    this.raioKm = raioPadraoKm,
    this.suspensaAte,
    this.infoExtra,
    this.avisos = const PreferenciasDeAviso(),
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Perfil');
    return Perfil(
      usuarioId: j.inteiro('usuarioId'),
      nomeOrganizacao: j.texto('nomeOrganizacao'),
      tipoDocumento: j.enumerado('tipoDocumento', TipoDocumento.values),
      documento: j.texto('documento'),
      verificacao: j.enumerado('verificacao', Verificacao.values),
      tipoEstabelecimento: j.enumeradoOpcional(
        'tipoEstabelecimento',
        TipoEstabelecimento.values,
      ),
      razaoSocial: j.textoOpcional('razaoSocial'),
      telefone: j.textoOpcional('telefone'),
      endereco: j.textoOpcional('endereco'),
      cep: j.textoOpcional('cep'),
      latitude: j.decimal('latitude'),
      longitude: j.decimal('longitude'),
      familiasAtendidas: j.inteiroOpcional('familiasAtendidas'),
      transporte: j.enumeradoOpcional('transporte', Transporte.values),
      buscaAtiva: j.booleano('buscaAtiva'),
      raioKm: j.decimal('raioKm'),
      suspensaAte: j.instanteOpcional('suspensaAte'),
      infoExtra: j.textoOpcional('infoExtra'),
      avisos: json['avisos'] is Map
          ? PreferenciasDeAviso.fromJson(
              Map<String, dynamic>.from(json['avisos'] as Map),
            )
          : const PreferenciasDeAviso(),
    );
  }

  /// Raio de busca da ONG quando ela ainda não escolheu outro.
  static const raioPadraoKm = 10.0;

  /// Quais avisos a pessoa quer receber (T50).
  final PreferenciasDeAviso avisos;

  final int usuarioId;
  final String nomeOrganizacao;
  final TipoDocumento tipoDocumento;

  /// Só números (14 do CNPJ ou 11 do CPF).
  final String documento;
  final Verificacao verificacao;
  final TipoEstabelecimento? tipoEstabelecimento;

  /// Nome oficial na Receita Federal (vem da BrasilAPI).
  final String? razaoSocial;
  final String? telefone;
  final String? endereco;
  final String? cep;
  final double latitude;
  final double longitude;
  final int? familiasAtendidas;
  final Transporte? transporte;

  /// ONG: `true` = recebe avisos de doações novas (T20).
  final bool buscaAtiva;

  /// ONG: até quantos km ela busca doações.
  final double raioKm;

  /// ONG: até quando está suspensa por desistências (RN24), em UTC.
  final DateTime? suspensaAte;

  /// Texto livre: "nome e dias da feira", "qual tipo" ou os dias e horários
  /// em que a ONG costuma retirar.
  final String? infoExtra;

  Coordenadas get coordenadas => Coordenadas(latitude, longitude);

  bool get ehVerificada => verificacao == Verificacao.verificada;

  /// RN24: a ONG está suspensa em [agora]?
  bool estaSuspensa(DateTime agora) =>
      suspensaAte != null && suspensaAte!.isAfter(agora);

  Map<String, dynamic> toJson() => {
    'usuarioId': usuarioId,
    'nomeOrganizacao': nomeOrganizacao,
    'tipoDocumento': tipoDocumento.name,
    'documento': documento,
    'verificacao': verificacao.name,
    'tipoEstabelecimento': tipoEstabelecimento?.name,
    'razaoSocial': razaoSocial,
    'telefone': telefone,
    'endereco': endereco,
    'cep': cep,
    'latitude': latitude,
    'longitude': longitude,
    'familiasAtendidas': familiasAtendidas,
    'transporte': transporte?.name,
    'buscaAtiva': buscaAtiva,
    'raioKm': raioKm,
    'suspensaAte': suspensaAte == null ? null : formatarInstante(suspensaAte!),
    'infoExtra': infoExtra,
    'avisos': avisos.toJson(),
  };
}

/// Usuário + perfil: tudo o que o app precisa saber sobre quem está logado.
///
/// Exemplo de **composição**: uma [Conta] *tem um* [Usuario] e *tem um*
/// [Perfil].
class Conta {
  const Conta({required this.usuario, required this.perfil});

  factory Conta.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Conta');
    return Conta(
      usuario: Usuario.fromJson(j.objeto('usuario').mapa),
      perfil: Perfil.fromJson(j.objeto('perfil').mapa),
    );
  }

  final Usuario usuario;
  final Perfil perfil;

  Map<String, dynamic> toJson() => {
    'usuario': usuario.toJson(),
    'perfil': perfil.toJson(),
  };
}
