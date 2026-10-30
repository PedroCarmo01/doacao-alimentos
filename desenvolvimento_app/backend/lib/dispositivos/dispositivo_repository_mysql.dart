import '../core/db/database.dart';
import '../core/utils/datas.dart';
import 'dispositivo_repository.dart';

/// [DispositivoRepository] no MySQL.
class DispositivoRepositoryMysql implements DispositivoRepository {
  DispositivoRepositoryMysql(this._db);

  final Database _db;

  @override
  Future<void> salvar({
    required int usuarioId,
    required String token,
    required String plataforma,
    required DateTime agora,
  }) async {
    // "ON DUPLICATE KEY UPDATE": se o token já está na tabela (índice
    // único), atualiza a linha em vez de dar erro. Acontece quando outra
    // pessoa entra no mesmo celular.
    await _db.executar(
      '''
      INSERT INTO dispositivos (usuario_id, token, plataforma, atualizado_em)
      VALUES (:usuarioId, :token, :plataforma, :agora)
      ON DUPLICATE KEY UPDATE usuario_id = :usuarioId, atualizado_em = :agora
      ''',
      {
        'usuarioId': usuarioId,
        'token': token,
        'plataforma': plataforma,
        'agora': Datas.paraSql(agora),
      },
    );
  }
}
