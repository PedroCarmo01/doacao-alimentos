import 'package:shared_models/shared_models.dart';

import '../core/db/database.dart';
import '../core/utils/datas.dart';
import 'chat_repository.dart';

/// [ChatRepository] no MySQL.
class ChatRepositoryMysql implements ChatRepository {
  ChatRepositoryMysql(this._db);

  final Database _db;

  @override
  Future<List<ResumoConversa>> conversasDe(
    int usuarioId,
    DateTime desde,
  ) async {
    // Subconsultas: a 1ª foto, a última mensagem e as não lidas de cada
    // conversa vêm numa consulta só.
    final linhas = await _db.consultar(
      '''
      SELECT r.id AS reserva_id, r.doacao_id, r.ong_id, r.status,
             r.reservado_em, d.titulo, d.categoria,
             (SELECT f.arquivo FROM fotos_doacao f
               WHERE f.doacao_id = d.id ORDER BY f.ordem LIMIT 1) AS foto,
             po.nome_organizacao AS nome_ong,
             pd.nome_organizacao AS nome_doador,
             (SELECT m.texto FROM mensagens m
               WHERE m.reserva_id = r.id ORDER BY m.id DESC LIMIT 1) AS ultima,
             (SELECT m.criado_em FROM mensagens m
               WHERE m.reserva_id = r.id ORDER BY m.id DESC LIMIT 1)
               AS ultima_em,
             (SELECT COUNT(*) FROM mensagens m
               WHERE m.reserva_id = r.id AND m.autor_id IS NOT NULL
                 AND m.autor_id <> :eu AND m.lida_em IS NULL) AS nao_lidas
        FROM reservas r
        JOIN doacoes d ON d.id = r.doacao_id
        JOIN perfis po ON po.usuario_id = r.ong_id
        JOIN perfis pd ON pd.usuario_id = d.doador_id
       WHERE (r.ong_id = :eu OR d.doador_id = :eu)
         -- RN31: encerradas há mais de 7 dias somem da lista.
         AND (r.status = 'ativa' OR r.encerrada_em >= :desde)
      ''',
      {'eu': usuarioId, 'desde': Datas.paraSql(desde)},
    );
    final conversas = [
      for (final l in linhas)
        ResumoConversa(
          reservaId: int.parse(l['reserva_id']!),
          doacaoId: int.parse(l['doacao_id']!),
          tituloDoacao: l['titulo']!,
          nomeOutro: int.parse(l['ong_id']!) == usuarioId
              ? l['nome_doador']!
              : l['nome_ong']!,
          naoLidas: int.parse(l['nao_lidas'] ?? '0'),
          somenteLeitura: l['status'] != 'ativa',
          fotoDoacao: l['foto'],
          categoria: l['categoria'],
          ultimaMensagem: l['ultima'],
          ultimaEm: Datas.deSql(l['ultima_em'] ?? l['reservado_em']!),
        ),
    ];
    // A conversa com a novidade mais recente primeiro.
    conversas.sort((a, b) => b.ultimaEm!.compareTo(a.ultimaEm!));
    return conversas;
  }

  @override
  Future<ConversaInfo?> info(int reservaId) async {
    final linhas = await _db.consultar(
      '''
      SELECT r.id, r.doacao_id, r.ong_id, d.doador_id, r.status,
             r.encerrada_em, po.nome_organizacao AS nome_ong,
             pd.nome_organizacao AS nome_doador
        FROM reservas r
        JOIN doacoes d ON d.id = r.doacao_id
        JOIN perfis po ON po.usuario_id = r.ong_id
        JOIN perfis pd ON pd.usuario_id = d.doador_id
       WHERE r.id = :id
      ''',
      {'id': reservaId},
    );
    if (linhas.isEmpty) return null;
    final l = linhas.first;
    final encerrada = l['encerrada_em'];
    return ConversaInfo(
      reservaId: reservaId,
      doacaoId: int.parse(l['doacao_id']!),
      ongId: int.parse(l['ong_id']!),
      doadorId: int.parse(l['doador_id']!),
      nomeOng: l['nome_ong']!,
      nomeDoador: l['nome_doador']!,
      ativa: l['status'] == 'ativa',
      encerradaEm: encerrada == null ? null : Datas.deSql(encerrada),
    );
  }

  @override
  Future<List<Mensagem>> mensagens(int reservaId, int depoisDe) async {
    final linhas = await _db.consultar(
      'SELECT * FROM mensagens WHERE reserva_id = :reserva AND id > :depois '
      'ORDER BY id',
      {'reserva': reservaId, 'depois': depoisDe},
    );
    return [for (final l in linhas) _mensagem(l)];
  }

  @override
  Future<int> lidasAte(int reservaId, int autorId) async {
    final linhas = await _db.consultar(
      '''
      SELECT COALESCE(MAX(id), 0) AS ate FROM mensagens
       WHERE reserva_id = :reserva AND autor_id = :autor
         AND lida_em IS NOT NULL
      ''',
      {'reserva': reservaId, 'autor': autorId},
    );
    return int.parse(linhas.first['ate'] ?? '0');
  }

  @override
  Future<Mensagem> inserir(
    int reservaId, {
    required int? autorId,
    required String texto,
    required DateTime agora,
  }) async {
    final id = await _db.inserir(
      'INSERT INTO mensagens (reserva_id, autor_id, texto, criado_em) '
      'VALUES (:reserva, :autor, :texto, :agora)',
      {
        'reserva': reservaId,
        'autor': autorId,
        'texto': texto,
        'agora': Datas.paraSql(agora),
      },
    );
    return Mensagem(
      id: id,
      reservaId: reservaId,
      autorId: autorId,
      texto: texto,
      criadoEm: agora,
    );
  }

  @override
  Future<void> marcarLidas(int reservaId, int leitorId, DateTime agora) async {
    await _db.executar(
      '''
      UPDATE mensagens SET lida_em = :agora
       WHERE reserva_id = :reserva AND autor_id IS NOT NULL
         AND autor_id <> :leitor AND lida_em IS NULL
      ''',
      {'reserva': reservaId, 'leitor': leitorId, 'agora': Datas.paraSql(agora)},
    );
  }

  static Mensagem _mensagem(Linha l) {
    final lida = l['lida_em'];
    return Mensagem(
      id: int.parse(l['id']!),
      reservaId: int.parse(l['reserva_id']!),
      autorId: int.tryParse(l['autor_id'] ?? ''),
      texto: l['texto']!,
      criadoEm: Datas.deSql(l['criado_em']!),
      lidaEm: lida == null ? null : Datas.deSql(lida),
    );
  }
}
