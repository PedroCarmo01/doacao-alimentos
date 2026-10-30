import 'package:shared_models/shared_models.dart';

import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import 'dispositivo_repository.dart';

/// `POST /dispositivos`. Prepara o push real (Firebase), que entra numa
/// etapa futura: hoje o app ainda não chama esta rota.
class DispositivoService {
  DispositivoService({
    required DispositivoRepository dispositivos,
    required Relogio relogio,
  }) : _dispositivos = dispositivos,
       _relogio = relogio;

  final DispositivoRepository _dispositivos;
  final Relogio _relogio;

  Future<void> registrar(
    UsuarioAutenticado usuario,
    DadosDispositivo dados,
  ) async {
    final token = dados.token.trim();
    if (token.isEmpty || token.length > DadosDispositivo.tamanhoMaximoToken) {
      throw const ValidacaoException('Token do dispositivo inválido.');
    }
    if (!DadosDispositivo.plataformasAceitas.contains(dados.plataforma)) {
      throw const ValidacaoException('Por enquanto, só Android é aceito.');
    }
    await _dispositivos.salvar(
      usuarioId: usuario.id,
      token: token,
      plataforma: dados.plataforma,
      agora: _relogio.agora(),
    );
  }
}
