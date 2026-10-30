import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../fake/banco_fake.dart';

/// CONTRATO: editar o próprio perfil (`PUT /perfil`).
///
/// Na etapa 3 a ONG usa para ligar/desligar a busca ativa e trocar o raio
/// (T20); na etapa 7, a tela de perfil edita o resto.
abstract interface class PerfilRepository {
  /// Devolve a conta atualizada (para a `Sessao` guardar).
  Future<Conta> atualizar(DadosPerfil dados);
}

class PerfilRepositoryApi implements PerfilRepository {
  PerfilRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<Conta> atualizar(DadosPerfil dados) async {
    final json = await _api.put('/perfil', corpo: dados.toJson());
    return Conta.fromJson(ApiClient.objeto(json));
  }
}

class PerfilRepositoryFake implements PerfilRepository {
  PerfilRepositoryFake(this._banco);

  final BancoFake _banco;

  @override
  Future<Conta> atualizar(DadosPerfil dados) async {
    await _banco.simularRede();
    return _banco.atualizarPerfil(dados);
  }
}

/// Monta o `DadosPerfil` a partir da conta atual, trocando só a busca ativa
/// e o raio. (O `PUT /perfil` recebe o perfil inteiro.)
DadosPerfil dadosDoPerfil(Conta conta, {bool? buscaAtiva, double? raioKm}) {
  final perfil = conta.perfil;
  return DadosPerfil(
    nome: conta.usuario.nome,
    nomeOrganizacao: perfil.nomeOrganizacao,
    telefone: perfil.telefone,
    endereco: perfil.endereco,
    cep: perfil.cep,
    latitude: perfil.latitude,
    longitude: perfil.longitude,
    familiasAtendidas: perfil.familiasAtendidas,
    transporte: perfil.transporte,
    infoExtra: perfil.infoExtra,
    buscaAtiva: buscaAtiva ?? perfil.buscaAtiva,
    raioKm: raioKm ?? perfil.raioKm,
  );
}
