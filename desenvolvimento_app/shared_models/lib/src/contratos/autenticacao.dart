import '../perfil.dart';
import '../usuario.dart';
import '../util/json.dart';

/// Corpo de `POST /auth/cadastro`.
///
/// Os mesmos campos servem para doador e ONG; o [tipo] diz qual é.
class DadosCadastro {
  const DadosCadastro({
    required this.tipo,
    required this.nome,
    required this.email,
    required this.senha,
    required this.nomeOrganizacao,
    required this.latitude,
    required this.longitude,
    this.telefone,
    this.endereco,
  });

  factory DadosCadastro.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Cadastro');
    return DadosCadastro(
      tipo: j.enumerado('tipo', TipoUsuario.values),
      nome: j.texto('nome'),
      email: j.texto('email'),
      senha: j.texto('senha'),
      nomeOrganizacao: j.texto('nomeOrganizacao'),
      telefone: j.textoOpcional('telefone'),
      endereco: j.textoOpcional('endereco'),
      latitude: j.decimal('latitude'),
      longitude: j.decimal('longitude'),
    );
  }

  final TipoUsuario tipo;
  final String nome;
  final String email;
  final String senha;
  final String nomeOrganizacao;
  final String? telefone;
  final String? endereco;
  final double latitude;
  final double longitude;

  /// Cópia com textos sem espaços nas pontas, e-mail em minúsculas e campos
  /// opcionais vazios convertidos em `null`.
  DadosCadastro normalizado() => DadosCadastro(
    tipo: tipo,
    nome: nome.trim(),
    email: email.trim().toLowerCase(),
    senha: senha,
    nomeOrganizacao: nomeOrganizacao.trim(),
    telefone: _vazioParaNulo(telefone),
    endereco: _vazioParaNulo(endereco),
    latitude: latitude,
    longitude: longitude,
  );

  Map<String, dynamic> toJson() => {
    'tipo': tipo.name,
    'nome': nome,
    'email': email,
    'senha': senha,
    'nomeOrganizacao': nomeOrganizacao,
    'telefone': telefone,
    'endereco': endereco,
    'latitude': latitude,
    'longitude': longitude,
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
