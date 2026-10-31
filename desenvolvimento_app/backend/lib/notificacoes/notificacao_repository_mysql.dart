import 'package:shared_models/shared_models.dart';

import '../core/db/database.dart';
import '../core/utils/datas.dart';
import 'notificacao_repository.dart';

/// [NotificacaoRepository] no MySQL.
class NotificacaoRepositoryMysql implements NotificacaoRepository {
  NotificacaoRepositoryMysql(this._db);

  final Database _db;

  @override
  Future<Notificacao> criar(NovaNotificacao nova) async {
    final id = await _db.inserir(
      '''
      INSERT INTO notificacoes (usuario_id, tipo, titulo, corpo, doacao_id,
                                reserva_id, lida, criado_em)
      VALUES (:usuario, :tipo, :titulo, :corpo, :doacao, :reserva, FALSE,
              :criadoEm)
      ''',
      {
        'usuario': nova.usuarioId,
        'tipo': nova.tipo.name,
        'titulo': nova.titulo,
        'corpo': nova.corpo,
        'doacao': nova.doacaoId,
        'reserva': nova.reservaId,
        'criadoEm': Datas.paraSql(nova.criadoEm),
      },
    );
    return Notificacao(
      id: id,
      tipo: nova.tipo,
      titulo: nova.titulo,
      corpo: nova.corpo,
      criadoEm: nova.criadoEm,
      doacaoId: nova.doacaoId,
      reservaId: nova.reservaId,
    );
  }

  @override
  Future<List<Notificacao>> depoisDe(
    int usuarioId,
    int depoisDe, {
    required int limite,
  }) async {
    final linhas = await _db.consultar(
      '''
      SELECT * FROM notificacoes
       WHERE usuario_id = :usuario AND id > :depois
       ORDER BY id
       LIMIT :limite
      ''',
      {'usuario': usuarioId, 'depois': depoisDe, 'limite': limite},
    );
    return [
      for (final linha in linhas)
        Notificacao(
          id: int.parse(linha['id']!),
          tipo: TipoNotificacao.values.byName(linha['tipo']!),
          titulo: linha['titulo']!,
          corpo: linha['corpo']!,
          criadoEm: Datas.deSql(linha['criado_em']!),
          doacaoId: int.tryParse(linha['doacao_id'] ?? ''),
          reservaId: int.tryParse(linha['reserva_id'] ?? ''),
          lida: linha['lida'] == '1',
        ),
    ];
  }

  @override
  Future<void> marcarLidas(int usuarioId, int ate) async {
    await _db.executar(
      'UPDATE notificacoes SET lida = TRUE '
      'WHERE usuario_id = :usuario AND id <= :ate AND lida = FALSE',
      {'usuario': usuarioId, 'ate': ate},
    );
  }

  @override
  Future<bool> existe(TipoNotificacao tipo, int reservaId) async {
    final linhas = await _db.consultar(
      'SELECT 1 FROM notificacoes '
      'WHERE tipo = :tipo AND reserva_id = :reserva LIMIT 1',
      {'tipo': tipo.name, 'reserva': reservaId},
    );
    return linhas.isNotEmpty;
  }

  @override
  Future<List<OngParaAviso>> ongsParaAvisar(
    int doacaoId,
    DateTime agora,
  ) async {
    final linhas = await _db.consultar(
      '''
      SELECT p.usuario_id, p.latitude, p.longitude, p.raio_km
        FROM perfis p
        JOIN usuarios u ON u.id = p.usuario_id
       WHERE u.tipo = 'ong'
         AND p.busca_ativa = TRUE
         AND (p.suspensa_ate IS NULL OR p.suspensa_ate <= :agora)
         -- RN22: quem desistiu desta doação não é avisado de novo.
         AND NOT EXISTS (SELECT 1 FROM bloqueios_doacao b
                          WHERE b.ong_id = p.usuario_id
                            AND b.doacao_id = :doacao)
      ''',
      {'doacao': doacaoId, 'agora': Datas.paraSql(agora)},
    );
    return [
      for (final linha in linhas)
        OngParaAviso(
          usuarioId: int.parse(linha['usuario_id']!),
          coordenadas: Coordenadas(
            double.parse(linha['latitude']!),
            double.parse(linha['longitude']!),
          ),
          raioKm: double.parse(linha['raio_km']!),
        ),
    ];
  }
}
