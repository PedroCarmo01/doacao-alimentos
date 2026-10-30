import 'package:shared_models/shared_models.dart';

import '../erros/app_exception.dart';

/// Quem fez a requisição, segundo o token JWT.
///
/// As rotas obtêm este objeto com `context.read<UsuarioAutenticado>()` e o
/// repassam aos Services, que decidem o que a pessoa pode fazer.
class UsuarioAutenticado {
  const UsuarioAutenticado({required this.id, required this.tipo});

  /// O mesmo id de `usuarios.id` (e de `perfis.usuario_id`).
  final int id;
  final TipoUsuario tipo;

  bool get ehDoador => tipo == TipoUsuario.doador;
  bool get ehOng => tipo == TipoUsuario.ong;

  /// Autorização por PAPEL: lança 403 se o tipo não for o [esperado].
  void exigirTipo(TipoUsuario esperado) {
    if (tipo != esperado) {
      throw SemPermissaoException(
        'Esta ação está disponível apenas para o perfil ${esperado.rotulo}.',
      );
    }
  }

  @override
  String toString() => 'UsuarioAutenticado(id: $id, tipo: ${tipo.name})';
}
