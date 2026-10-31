import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/perfil/estatisticas_repository.dart';

import 'doacoes_em_memoria.dart';

/// [EstatisticasRepository] em memória: as mesmas contas do MySQL, feitas
/// com laços sobre as doações e retiradas em memória.
class EstatisticasEmMemoria implements EstatisticasRepository {
  EstatisticasEmMemoria(this._doacoes);

  final DoacoesEmMemoria _doacoes;

  @override
  Future<EstatisticasDoPerfil> doDoador(int doadorId) async {
    var concluidas = 0;
    var kg = 0.0;
    for (final d in _doacoes.doacoes) {
      if (d.doadorId == doadorId && d.status == StatusDoacao.concluida) {
        concluidas++;
        kg += d.pesoKg;
      }
    }
    return EstatisticasDoPerfil(concluidas: concluidas, kg: kg);
  }

  @override
  Future<EstatisticasDoPerfil> daOng(
    int ongId, {
    required DateTime desistenciasDesde,
  }) async {
    var concluidas = 0;
    var kg = 0.0;
    var desistencias = 0;
    var recentes = 0;
    for (final r in _doacoes.reservas) {
      if (r.ongId != ongId) continue;
      if (r.status == StatusReserva.concluida) {
        concluidas++;
        kg += (await _doacoes.buscar(r.doacaoId))!.pesoKg;
      }
      if (r.contouDesistencia) {
        desistencias++;
        if (!r.encerradaEm!.isBefore(desistenciasDesde)) recentes++;
      }
    }
    return EstatisticasDoPerfil(
      concluidas: concluidas,
      kg: kg,
      comparecimento: EstatisticasRepositoryMysql.comparecimento(
        concluidas,
        desistencias,
      ),
      desistenciasRecentes: recentes,
    );
  }
}
