import 'util/json.dart';

/// Tipo de conta. Cada usuário é **ou** doador **ou** ONG.
///
/// É um *enum aprimorado*: cada valor carrega um texto para exibir na tela.
enum TipoUsuario {
  doador('Doador'),
  ong('ONG');

  const TipoUsuario(this.rotulo);

  /// Texto amigável para a interface.
  final String rotulo;
}

/// Quem acessa o sistema (dados de identidade).
///
/// É imutável: todos os campos são `final`. Para "alterar", crie outra
/// instância com [copyWith]. Isso evita que uma tela mude dados que outra
/// tela está exibindo.
class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
  });

  /// Cria um [Usuario] a partir do JSON da API.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Usuario');
    return Usuario(
      id: j.inteiro('id'),
      nome: j.texto('nome'),
      email: j.texto('email'),
      tipo: j.enumerado('tipo', TipoUsuario.values),
    );
  }

  final int id;
  final String nome;
  final String email;
  final TipoUsuario tipo;

  bool get ehDoador => tipo == TipoUsuario.doador;
  bool get ehOng => tipo == TipoUsuario.ong;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'email': email,
    'tipo': tipo.name,
  };

  Usuario copyWith({String? nome, String? email}) => Usuario(
    id: id,
    nome: nome ?? this.nome,
    email: email ?? this.email,
    tipo: tipo,
  );

  @override
  String toString() => 'Usuario(id: $id, email: $email, tipo: ${tipo.name})';
}
