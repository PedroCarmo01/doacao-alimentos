import '../util/json.dart';

/// Dados de um CNPJ na Receita Federal, consultados na BrasilAPI (RN03).
///
/// Resposta de `GET /documentos/{numero}`: o app usa para preencher o nome
/// da organização no cadastro. O servidor usa as mesmas regras ([ativa] e
/// [semFinsLucrativos]) para aceitar ou recusar o cadastro.
class InfoCnpj {
  const InfoCnpj({
    required this.cnpj,
    required this.razaoSocial,
    required this.situacao,
    this.nomeFantasia,
    this.naturezaJuridica,
    this.codigoNaturezaJuridica,
  });

  factory InfoCnpj.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'InfoCnpj');
    return InfoCnpj(
      cnpj: j.texto('cnpj'),
      razaoSocial: j.texto('razaoSocial'),
      nomeFantasia: j.textoOpcional('nomeFantasia'),
      situacao: j.texto('situacao'),
      naturezaJuridica: j.textoOpcional('naturezaJuridica'),
      codigoNaturezaJuridica: j.inteiroOpcional('codigoNaturezaJuridica'),
    );
  }

  /// Situação que a Receita usa para empresas em funcionamento.
  static const situacaoAtiva = 'ATIVA';

  /// Códigos de natureza jurídica que começam com 3 são do grupo
  /// "Entidades sem Fins Lucrativos" (associação, fundação, organização
  /// religiosa...). Os que começam com 2 são empresas.
  static const grupoSemFinsLucrativos = '3';

  /// Só números.
  final String cnpj;
  final String razaoSocial;
  final String? nomeFantasia;

  /// Ex.: "ATIVA", "BAIXADA", "INAPTA".
  final String situacao;

  /// Ex.: "Associação Privada".
  final String? naturezaJuridica;

  /// Ex.: 3999 (associação privada), 2062 (sociedade limitada).
  final int? codigoNaturezaJuridica;

  /// RN03: só CNPJ ATIVO pode se cadastrar.
  bool get ativa => situacao.trim().toUpperCase() == situacaoAtiva;

  /// RN03: ONG precisa ser entidade sem fins lucrativos.
  bool get semFinsLucrativos {
    final codigo = codigoNaturezaJuridica;
    if (codigo == null) return false;
    return codigo.toString().startsWith(grupoSemFinsLucrativos);
  }

  /// Nome para preencher o formulário: o fantasia, se houver; senão a razão
  /// social.
  String get nomeSugerido {
    final fantasia = nomeFantasia?.trim() ?? '';
    return fantasia.isEmpty ? razaoSocial : fantasia;
  }

  Map<String, dynamic> toJson() => {
    'cnpj': cnpj,
    'razaoSocial': razaoSocial,
    'nomeFantasia': nomeFantasia,
    'situacao': situacao,
    'naturezaJuridica': naturezaJuridica,
    'codigoNaturezaJuridica': codigoNaturezaJuridica,
    'ativa': ativa,
    'semFinsLucrativos': semFinsLucrativos,
  };
}
