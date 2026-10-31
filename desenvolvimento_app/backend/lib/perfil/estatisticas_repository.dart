import 'package:shared_models/shared_models.dart';

import '../core/db/database.dart';
import '../core/utils/datas.dart';

/// CONTRATO: os números do Perfil (T50).
abstract interface class EstatisticasRepository {
  /// Doações entregues e kg doados.
  Future<EstatisticasDoPerfil> doDoador(int doadorId);

  /// Retiradas, kg recebidos, comparecimento e desistências desde
  /// [desistenciasDesde] (RN24).
  Future<EstatisticasDoPerfil> daOng(
    int ongId, {
    required DateTime desistenciasDesde,
  });
}

/// [EstatisticasRepository] no MySQL: só `COUNT` e `SUM`.
class EstatisticasRepositoryMysql implements EstatisticasRepository {
  EstatisticasRepositoryMysql(this._db);

  final Database _db;

  @override
  Future<EstatisticasDoPerfil> doDoador(int doadorId) async {
    final linha = (await _db.consultar(
      '''
      SELECT COUNT(*) AS concluidas, COALESCE(SUM(peso_kg), 0) AS kg
        FROM doacoes
       WHERE doador_id = :doador AND status = 'concluida'
      ''',
      {'doador': doadorId},
    )).first;
    return EstatisticasDoPerfil(
      concluidas: int.parse(linha['concluidas']!),
      kg: double.parse(linha['kg']!),
    );
  }

  @override
  Future<EstatisticasDoPerfil> daOng(
    int ongId, {
    required DateTime desistenciasDesde,
  }) async {
    // SUM(condição) conta as linhas em que a condição é verdadeira.
    final linha = (await _db.consultar(
      '''
      SELECT COALESCE(SUM(r.status = 'concluida'), 0) AS concluidas,
             COALESCE(SUM(IF(r.status = 'concluida', d.peso_kg, 0)), 0) AS kg,
             COALESCE(SUM(r.conta_desistencia), 0) AS desistencias,
             COALESCE(SUM(r.conta_desistencia AND r.encerrada_em >= :desde), 0)
               AS recentes
        FROM reservas r
        JOIN doacoes d ON d.id = r.doacao_id
       WHERE r.ong_id = :ong
      ''',
      {'ong': ongId, 'desde': Datas.paraSql(desistenciasDesde)},
    )).first;
    final concluidas = int.parse(linha['concluidas']!);
    final desistencias = int.parse(linha['desistencias']!);
    return EstatisticasDoPerfil(
      concluidas: concluidas,
      kg: double.parse(linha['kg']!),
      comparecimento: comparecimento(concluidas, desistencias),
      desistenciasRecentes: int.parse(linha['recentes']!),
    );
  }

  /// Retiradas feitas sobre as que contaram (feitas + desistências). As
  /// desistências dentro da tolerância (RN23) não contam. `null` = ainda
  /// não há retiradas para calcular.
  static double? comparecimento(int concluidas, int desistencias) {
    final total = concluidas + desistencias;
    return total == 0 ? null : concluidas / total;
  }
}
