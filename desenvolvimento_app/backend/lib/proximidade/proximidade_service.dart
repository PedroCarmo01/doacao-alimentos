import 'package:shared_models/shared_models.dart';

import '../auth/usuario_repository.dart';
import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import 'area_de_busca.dart';
import 'proximidade_repository.dart';

/// `GET /proximas` — doações perto da ONG (T20 e T21), da mais perto para a
/// mais longe.
class ProximidadeService {
  ProximidadeService({
    required ProximidadeRepository proximidade,
    required UsuarioRepository usuarios,
    required Relogio relogio,
  }) : _proximidade = proximidade,
       _usuarios = usuarios,
       _relogio = relogio;

  /// Limites de bom senso para o raio pedido na URL.
  static const raioMinimoKm = 0.5;
  static const raioMaximoKm = 50.0;

  final ProximidadeRepository _proximidade;
  final UsuarioRepository _usuarios;
  final Relogio _relogio;

  /// Sem [raioKm], usa o raio salvo no perfil da ONG (T20/T50).
  Future<List<Doacao>> proximas(
    UsuarioAutenticado usuario, {
    double? raioKm,
  }) async {
    usuario.exigirTipo(TipoUsuario.ong);
    final perfil = (await _usuarios.buscarConta(usuario.id))?.perfil;
    if (perfil == null) {
      throw const NaoAutenticadoException(
        codigo: 'TOKEN_INVALIDO',
        mensagem: 'Sessão inválida. Entre novamente.',
      );
    }
    final raio = (raioKm ?? perfil.raioKm)
        .clamp(raioMinimoKm, raioMaximoKm)
        .toDouble();
    final centro = perfil.coordenadas;
    final agora = _relogio.agora();

    // Passo 1: filtro "grosso" no banco (retângulo + regras de status).
    final candidatas = await _proximidade.disponiveisNaArea(
      AreaDeBusca.aoRedor(centro, raio),
      ongId: usuario.id,
      agora: agora,
    );

    // Passo 2: distância exata (Haversine), tira os "cantos" do retângulo
    // e ordena da mais perto para a mais longe.
    final resultado = <Doacao>[];
    for (final doacao in candidatas) {
      if (!doacao.podeSerReservada(agora)) continue;
      final km = Geo.distanciaKm(centro, doacao.coordenadas);
      if (km <= raio) resultado.add(doacao.copyWith(distanciaKm: km));
    }
    resultado.sort((a, b) => a.distanciaKm!.compareTo(b.distanciaKm!));
    return resultado;
  }
}
