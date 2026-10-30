import 'package:shared_models/shared_models.dart';

import '../core/db/database.dart';
import '../core/db/mapeador.dart';
import '../core/utils/datas.dart';
import 'area_de_busca.dart';
import 'proximidade_repository.dart';

/// [ProximidadeRepository] no MySQL.
class ProximidadeRepositoryMysql implements ProximidadeRepository {
  ProximidadeRepositoryMysql(this._db);

  final Database _db;

  @override
  Future<List<Doacao>> disponiveisNaArea(
    AreaDeBusca area, {
    required int ongId,
    required DateTime agora,
  }) async {
    final linhas = await _db.consultar(
      '''
      SELECT d.*, p.nome_organizacao AS nome_doador,
             (SELECT GROUP_CONCAT(f.arquivo ORDER BY f.ordem SEPARATOR ',')
                FROM fotos_doacao f WHERE f.doacao_id = d.id) AS fotos
        FROM doacoes d
        JOIN perfis p ON p.usuario_id = d.doador_id
       WHERE d.status = 'disponivel'
         AND d.janela_fim > :agora
         AND d.latitude  BETWEEN :latMin AND :latMax
         AND d.longitude BETWEEN :lngMin AND :lngMax
         -- RN22 - a ONG não vê a doação que ela deixou expirar.
         AND NOT EXISTS (SELECT 1 FROM bloqueios_doacao b
                          WHERE b.doacao_id = d.id AND b.ong_id = :ong)
      ''',
      {
        'agora': Datas.paraSql(agora),
        'latMin': area.latitudeMin,
        'latMax': area.latitudeMax,
        'lngMin': area.longitudeMin,
        'lngMax': area.longitudeMax,
        'ong': ongId,
      },
    );
    return [for (final linha in linhas) Mapeador.doacao(linha)];
  }
}
