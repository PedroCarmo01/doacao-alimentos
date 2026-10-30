import 'geo/geo.dart';
import 'usuario.dart';
import 'util/json.dart';

/// Dados da organização: estabelecimento doador ou ONG.
///
/// Relação 1:1 com [Usuario]: o [usuarioId] também identifica o perfil
/// (no banco, é a chave primária da tabela `perfis`).
class Perfil {
  const Perfil({
    required this.usuarioId,
    required this.nomeOrganizacao,
    required this.latitude,
    required this.longitude,
    this.telefone,
    this.endereco,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Perfil');
    return Perfil(
      usuarioId: j.inteiro('usuarioId'),
      nomeOrganizacao: j.texto('nomeOrganizacao'),
      telefone: j.textoOpcional('telefone'),
      endereco: j.textoOpcional('endereco'),
      latitude: j.decimal('latitude'),
      longitude: j.decimal('longitude'),
    );
  }

  final int usuarioId;
  final String nomeOrganizacao;
  final String? telefone;
  final String? endereco;
  final double latitude;
  final double longitude;

  Coordenadas get coordenadas => Coordenadas(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'usuarioId': usuarioId,
        'nomeOrganizacao': nomeOrganizacao,
        'telefone': telefone,
        'endereco': endereco,
        'latitude': latitude,
        'longitude': longitude,
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
