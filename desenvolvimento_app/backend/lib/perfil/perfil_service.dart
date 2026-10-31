import 'package:shared_models/shared_models.dart';

import '../auth/usuario_repository.dart';
import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import 'estatisticas_repository.dart';
import 'perfil_repository.dart';

/// O perfil da conta logada (telas T20 e T50): editar, avisos e
/// estatísticas.
class PerfilService {
  PerfilService({
    required PerfilRepository perfis,
    required UsuarioRepository usuarios,
    required EstatisticasRepository estatisticas,
    required Relogio relogio,
    Duration janelaDesistencias = const Duration(days: 30),
  }) : _perfis = perfis,
       _usuarios = usuarios,
       _estatisticas = estatisticas,
       _relogio = relogio,
       _janela = janelaDesistencias;

  final PerfilRepository _perfis;
  final UsuarioRepository _usuarios;
  final EstatisticasRepository _estatisticas;
  final Relogio _relogio;
  final Duration _janela;

  /// Valida, grava e devolve a conta atualizada.
  Future<Conta> atualizar(
    UsuarioAutenticado usuario,
    DadosPerfil recebidos,
  ) async {
    var dados = recebidos.normalizado();
    final erros = ValidadorUsuario.validarPerfil(dados);
    if (erros.isNotEmpty) {
      throw ValidacaoException(erros.first, detalhes: erros);
    }
    if (usuario.ehDoador) dados = _semCamposDeOng(dados);
    await _perfis.atualizar(usuario.id, dados);

    final conta = await _usuarios.buscarConta(usuario.id);
    if (conta == null) throw const NaoEncontradoException();
    return conta;
  }

  /// `PUT /perfil/avisos` — T50: quais avisos receber.
  Future<Conta> atualizarAvisos(
    UsuarioAutenticado usuario,
    PreferenciasDeAviso avisos,
  ) async {
    await _perfis.atualizarAvisos(usuario.id, avisos);
    return (await _usuarios.buscarConta(usuario.id)) ??
        (throw const NaoEncontradoException());
  }

  /// `GET /perfil/estatisticas` — T50.
  Future<EstatisticasDoPerfil> estatisticas(UsuarioAutenticado usuario) =>
      usuario.ehOng
      ? _estatisticas.daOng(
          usuario.id,
          desistenciasDesde: _relogio.agora().subtract(_janela),
        )
      : _estatisticas.doDoador(usuario.id);

  /// RN01: doador não tem famílias atendidas, transporte nem busca ativa.
  /// Se o app mandar esses campos, eles voltam ao padrão.
  static DadosPerfil _semCamposDeOng(DadosPerfil dados) => DadosPerfil(
    nome: dados.nome,
    nomeOrganizacao: dados.nomeOrganizacao,
    telefone: dados.telefone,
    endereco: dados.endereco,
    cep: dados.cep,
    latitude: dados.latitude,
    longitude: dados.longitude,
    infoExtra: dados.infoExtra,
  );
}
