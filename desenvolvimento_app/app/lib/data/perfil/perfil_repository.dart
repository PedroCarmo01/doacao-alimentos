import 'package:shared_models/shared_models.dart';

import '../../core/api/api_client.dart';
import '../fake/banco_fake.dart';

/// CONTRATO: o próprio perfil (`/perfil`).
///
/// Na etapa 3 a ONG usa para ligar/desligar a busca ativa e trocar o raio
/// (T20); na etapa 7, a tela de Perfil (T50) edita o resto, os avisos e
/// mostra as estatísticas.
abstract interface class PerfilRepository {
  /// `PUT /perfil` — devolve a conta atualizada (para a `Sessao` guardar).
  Future<Conta> atualizar(DadosPerfil dados);

  /// `PUT /perfil/avisos`
  Future<Conta> atualizarAvisos(PreferenciasDeAviso avisos);

  /// `GET /perfil/estatisticas`
  Future<EstatisticasDoPerfil> estatisticas();
}

class PerfilRepositoryApi implements PerfilRepository {
  PerfilRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<Conta> atualizar(DadosPerfil dados) async {
    final json = await _api.put('/perfil', corpo: dados.toJson());
    return Conta.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<Conta> atualizarAvisos(PreferenciasDeAviso avisos) async {
    final json = await _api.put('/perfil/avisos', corpo: avisos.toJson());
    return Conta.fromJson(ApiClient.objeto(json));
  }

  @override
  Future<EstatisticasDoPerfil> estatisticas() async =>
      EstatisticasDoPerfil.fromJson(
        ApiClient.objeto(await _api.get('/perfil/estatisticas')),
      );
}

class PerfilRepositoryFake implements PerfilRepository {
  PerfilRepositoryFake(this._banco);

  final BancoFake _banco;

  @override
  Future<Conta> atualizar(DadosPerfil dados) async {
    await _banco.simularRede();
    return _banco.atualizarPerfil(dados);
  }

  @override
  Future<Conta> atualizarAvisos(PreferenciasDeAviso avisos) async {
    await _banco.simularRede();
    return _banco.atualizarAvisos(avisos);
  }

  @override
  Future<EstatisticasDoPerfil> estatisticas() async {
    await _banco.simularRede();
    return _banco.estatisticas();
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
