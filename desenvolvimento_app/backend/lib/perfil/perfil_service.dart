import 'package:shared_models/shared_models.dart';

import '../auth/usuario_repository.dart';
import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import 'perfil_repository.dart';

/// Regras de edição do perfil (`PUT /perfil`, telas T20 e T50).
class PerfilService {
  PerfilService({
    required PerfilRepository perfis,
    required UsuarioRepository usuarios,
  }) : _perfis = perfis,
       _usuarios = usuarios;

  final PerfilRepository _perfis;
  final UsuarioRepository _usuarios;

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
