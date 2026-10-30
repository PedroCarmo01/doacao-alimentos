import '../tipos_de_perfil.dart';
import '../util/json.dart';
import '../validacao/validador_documento.dart';

/// Corpo de `PUT /perfil`: editar dados, localização, busca ativa e raio.
///
/// O app envia o perfil INTEIRO (com o que mudou e o que não mudou). Assim o
/// servidor não precisa adivinhar se um campo vazio quer dizer "apagar" ou
/// "não mexer". Documento, tipo e e-mail não mudam por aqui.
class DadosPerfil {
  const DadosPerfil({
    required this.nome,
    required this.nomeOrganizacao,
    required this.latitude,
    required this.longitude,
    this.telefone,
    this.endereco,
    this.cep,
    this.familiasAtendidas,
    this.transporte,
    this.infoExtra,
    this.buscaAtiva = true,
    this.raioKm = 10,
  });

  factory DadosPerfil.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Perfil');
    return DadosPerfil(
      nome: j.texto('nome'),
      nomeOrganizacao: j.texto('nomeOrganizacao'),
      telefone: j.textoOpcional('telefone'),
      endereco: j.textoOpcional('endereco'),
      cep: j.textoOpcional('cep'),
      latitude: j.decimal('latitude'),
      longitude: j.decimal('longitude'),
      familiasAtendidas: j.inteiroOpcional('familiasAtendidas'),
      transporte: j.enumeradoOpcional('transporte', Transporte.values),
      infoExtra: j.textoOpcional('infoExtra'),
      buscaAtiva: j.booleano('buscaAtiva'),
      raioKm: j.decimal('raioKm'),
    );
  }

  /// Nome do responsável.
  final String nome;
  final String nomeOrganizacao;
  final String? telefone;
  final String? endereco;
  final String? cep;
  final double latitude;
  final double longitude;
  final int? familiasAtendidas;
  final Transporte? transporte;
  final String? infoExtra;
  final bool buscaAtiva;
  final double raioKm;

  /// Mesma limpeza do cadastro: sem espaços nas pontas, CEP só com números
  /// e textos vazios como `null`.
  DadosPerfil normalizado() => DadosPerfil(
    nome: nome.trim(),
    nomeOrganizacao: nomeOrganizacao.trim(),
    telefone: _vazioParaNulo(telefone),
    endereco: _vazioParaNulo(endereco),
    cep: _vazioParaNulo(ValidadorDocumento.somenteDigitos(cep ?? '')),
    latitude: latitude,
    longitude: longitude,
    familiasAtendidas: familiasAtendidas,
    transporte: transporte,
    infoExtra: _vazioParaNulo(infoExtra),
    buscaAtiva: buscaAtiva,
    raioKm: raioKm,
  );

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'nomeOrganizacao': nomeOrganizacao,
    'telefone': telefone,
    'endereco': endereco,
    'cep': cep,
    'latitude': latitude,
    'longitude': longitude,
    'familiasAtendidas': familiasAtendidas,
    'transporte': transporte?.name,
    'infoExtra': infoExtra,
    'buscaAtiva': buscaAtiva,
    'raioKm': raioKm,
  };

  static String? _vazioParaNulo(String? texto) {
    final limpo = texto?.trim();
    return (limpo == null || limpo.isEmpty) ? null : limpo;
  }
}

/// Corpo de `POST /dispositivos`: o identificador do celular para o push
/// real (Firebase) que entra numa etapa futura. A rota já existe para que
/// a troca seja só "mudar uma linha".
class DadosDispositivo {
  const DadosDispositivo({required this.token, this.plataforma = 'android'});

  factory DadosDispositivo.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Dispositivo');
    return DadosDispositivo(
      token: j.texto('token'),
      plataforma: j.textoOpcional('plataforma') ?? 'android',
    );
  }

  /// Plataformas aceitas por enquanto (o app é só Android).
  static const plataformasAceitas = {'android'};

  /// Tamanho máximo da coluna `dispositivos.token`.
  static const tamanhoMaximoToken = 255;

  final String token;
  final String plataforma;

  Map<String, dynamic> toJson() => {'token': token, 'plataforma': plataforma};
}
