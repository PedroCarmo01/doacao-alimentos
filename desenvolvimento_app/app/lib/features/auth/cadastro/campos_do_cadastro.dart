import 'package:shared_models/shared_models.dart';

/// Os textos digitados no cadastro (passos 3 e 4).
///
/// É uma classe Dart pura (sem Flutter): a tela lê os campos e entrega um
/// objeto destes ao ViewModel. Assim o ViewModel não depende de
/// `TextEditingController` e pode ser testado sem tela.
class CamposDoCadastro {
  const CamposDoCadastro({
    required this.documento,
    required this.nomeOrganizacao,
    required this.nomeResponsavel,
    required this.telefone,
    required this.email,
    required this.senha,
    this.familiasAtendidas = '',
    this.infoExtra = '',
    this.cep = '',
    this.endereco = '',
  });

  final String documento;
  final String nomeOrganizacao;
  final String nomeResponsavel;
  final String telefone;
  final String email;
  final String senha;

  /// Texto do campo (pode estar vazio): vira número em [paraCadastro].
  final String familiasAtendidas;
  final String infoExtra;
  final String cep;
  final String endereco;

  /// Junta os textos com as escolhas feitas nos botões e no mapa.
  DadosCadastro paraCadastro({
    required TipoUsuario tipo,
    required TipoEstabelecimento? estabelecimento,
    required Transporte? transporte,
    required Coordenadas coordenadas,
    required bool aceitouTermos,
  }) => DadosCadastro(
    tipo: tipo,
    tipoEstabelecimento: estabelecimento,
    nome: nomeResponsavel,
    email: email,
    senha: senha,
    nomeOrganizacao: nomeOrganizacao,
    documento: documento,
    telefone: telefone,
    endereco: endereco,
    cep: cep,
    latitude: coordenadas.latitude,
    longitude: coordenadas.longitude,
    familiasAtendidas: int.tryParse(familiasAtendidas.trim()),
    transporte: transporte,
    infoExtra: infoExtra,
    aceitouTermos: aceitouTermos,
  );
}
