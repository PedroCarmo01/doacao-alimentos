import '../perfil.dart';
import '../tipos_de_perfil.dart';
import '../usuario.dart';
import '../util/json.dart';
import '../validacao/validador_documento.dart';

/// Corpo de `POST /auth/cadastro` (tela T4, cadastro em etapas).
///
/// Os mesmos campos servem para doador e ONG; o [tipo] diz qual é (RN01).
class DadosCadastro {
  const DadosCadastro({
    required this.tipo,
    required this.nome,
    required this.email,
    required this.senha,
    required this.nomeOrganizacao,
    required this.documento,
    required this.latitude,
    required this.longitude,
    required this.aceitouTermos,
    this.tipoEstabelecimento,
    this.telefone,
    this.endereco,
    this.cep,
    this.familiasAtendidas,
    this.transporte,
    this.infoExtra,
  });

  factory DadosCadastro.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Cadastro');
    return DadosCadastro(
      tipo: j.enumerado('tipo', TipoUsuario.values),
      nome: j.texto('nome'),
      email: j.texto('email'),
      senha: j.texto('senha'),
      nomeOrganizacao: j.texto('nomeOrganizacao'),
      documento: j.texto('documento'),
      tipoEstabelecimento: j.enumeradoOpcional(
        'tipoEstabelecimento',
        TipoEstabelecimento.values,
      ),
      telefone: j.textoOpcional('telefone'),
      endereco: j.textoOpcional('endereco'),
      cep: j.textoOpcional('cep'),
      latitude: j.decimal('latitude'),
      longitude: j.decimal('longitude'),
      familiasAtendidas: j.inteiroOpcional('familiasAtendidas'),
      transporte: j.enumeradoOpcional('transporte', Transporte.values),
      infoExtra: j.textoOpcional('infoExtra'),
      aceitouTermos: j.booleano('aceitouTermos'),
    );
  }

  final TipoUsuario tipo;

  /// Nome do responsável pela conta.
  final String nome;
  final String email;
  final String senha;
  final String nomeOrganizacao;

  /// CNPJ ou CPF, com ou sem máscara.
  final String documento;

  /// Só para doador.
  final TipoEstabelecimento? tipoEstabelecimento;
  final String? telefone;
  final String? endereco;
  final String? cep;
  final double latitude;
  final double longitude;

  /// Só para ONG.
  final int? familiasAtendidas;

  /// Só para ONG.
  final Transporte? transporte;
  final String? infoExtra;

  /// Caixa "Li e aceito os Termos de Uso" (etapa 5 do cadastro).
  final bool aceitouTermos;

  /// CNPJ ou CPF, descoberto pelo tamanho do [documento].
  TipoDocumento get tipoDocumento =>
      TipoDocumento.doNumero(ValidadorDocumento.somenteDigitos(documento));

  /// Cópia "limpa": textos sem espaços nas pontas, e-mail em minúsculas,
  /// documento e CEP só com números e campos opcionais vazios como `null`.
  ///
  /// Também descarta os campos que não são do tipo da conta (RN01): uma
  /// ONG não tem tipo de estabelecimento e um doador não tem transporte.
  DadosCadastro normalizado() {
    final ehOng = tipo == TipoUsuario.ong;
    return DadosCadastro(
      tipo: tipo,
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
      senha: senha,
      nomeOrganizacao: nomeOrganizacao.trim(),
      documento: ValidadorDocumento.somenteDigitos(documento),
      tipoEstabelecimento: ehOng ? null : tipoEstabelecimento,
      telefone: _vazioParaNulo(telefone),
      endereco: _vazioParaNulo(endereco),
      cep: _vazioParaNulo(ValidadorDocumento.somenteDigitos(cep ?? '')),
      latitude: latitude,
      longitude: longitude,
      familiasAtendidas: ehOng ? familiasAtendidas : null,
      transporte: ehOng ? transporte : null,
      infoExtra: _vazioParaNulo(infoExtra),
      aceitouTermos: aceitouTermos,
    );
  }

  Map<String, dynamic> toJson() => {
    'tipo': tipo.name,
    'nome': nome,
    'email': email,
    'senha': senha,
    'nomeOrganizacao': nomeOrganizacao,
    'documento': documento,
    'tipoEstabelecimento': tipoEstabelecimento?.name,
    'telefone': telefone,
    'endereco': endereco,
    'cep': cep,
    'latitude': latitude,
    'longitude': longitude,
    'familiasAtendidas': familiasAtendidas,
    'transporte': transporte?.name,
    'infoExtra': infoExtra,
    'aceitouTermos': aceitouTermos,
  };

  static String? _vazioParaNulo(String? texto) {
    final limpo = texto?.trim();
    return (limpo == null || limpo.isEmpty) ? null : limpo;
  }
}

/// Corpo de `POST /auth/login`.
class DadosLogin {
  const DadosLogin({required this.email, required this.senha});

  factory DadosLogin.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Login');
    return DadosLogin(email: j.texto('email'), senha: j.texto('senha'));
  }

  final String email;
  final String senha;

  Map<String, dynamic> toJson() => {'email': email, 'senha': senha};
}

/// Resposta de cadastro e de login: o token JWT e a conta do usuário.
///
/// O JSON é "plano": `{ "token": ..., "usuario": {...}, "perfil": {...} }`.
class RespostaAutenticacao {
  const RespostaAutenticacao({required this.token, required this.conta});

  factory RespostaAutenticacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'RespostaAutenticacao');
    return RespostaAutenticacao(
      token: j.texto('token'),
      conta: Conta.fromJson(json),
    );
  }

  final String token;
  final Conta conta;

  Map<String, dynamic> toJson() => {'token': token, ...conta.toJson()};
}
