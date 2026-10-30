import 'package:mysql_client/exception.dart' show MySQLServerException;
import 'package:shared_models/shared_models.dart';

import '../core/db/database.dart';
import '../core/db/mapeador.dart';
import '../core/erros/app_exception.dart';
import '../core/utils/datas.dart';
import 'reserva_repository.dart';

/// [ReservaRepository] no MySQL (tabelas `reservas`, `bloqueios_doacao` e a
/// coluna `suspensa_ate` de `perfis`).
class ReservaRepositoryMysql implements ReservaRepository {
  ReservaRepositoryMysql(this._db);

  final Database _db;

  /// Os aliases `titulo_doacao` e `nome_ong` preenchem os campos de leitura
  /// do modelo `Reserva`.
  static const _select = '''
    SELECT r.*, d.titulo AS titulo_doacao, p.nome_organizacao AS nome_ong
      FROM reservas r
      JOIN doacoes d ON d.id = r.doacao_id
      JOIN perfis p ON p.usuario_id = r.ong_id
  ''';

  @override
  Future<Reserva?> buscar(int reservaId) => _buscarCom(_db, reservaId);

  Future<Reserva?> _buscarCom(ExecutorSql executor, int reservaId) async {
    final linhas = await executor.consultar('$_select WHERE r.id = :id', {
      'id': reservaId,
    });
    return linhas.isEmpty ? null : Mapeador.reserva(linhas.first);
  }

  @override
  Future<List<Reserva>> daOng(int ongId, SituacaoDaLista situacao) async {
    // Os dois textos abaixo são constantes nossas (não vêm do usuário).
    final filtro = situacao == SituacaoDaLista.ativas
        ? "r.status = 'ativa'"
        : "r.status <> 'ativa'";
    final linhas = await _db.consultar(
      '$_select WHERE r.ong_id = :ong AND $filtro '
      'ORDER BY r.reservado_em DESC, r.id DESC',
      {'ong': ongId},
    );
    return [for (final linha in linhas) Mapeador.reserva(linha)];
  }

  @override
  Future<Reserva?> criarSeDisponivel(NovaReserva nova) {
    return _db.transacao((t) async {
      // FOR UPDATE: trava a linha da doação até o fim da transação. Uma
      // segunda ONG que chegue agora ESPERA aqui e depois lê o status novo.
      final linhas = await t.consultar(
        '''
        SELECT id FROM doacoes
         WHERE id = :id AND status = 'disponivel' AND janela_fim > :agora
         FOR UPDATE
        ''',
        {'id': nova.doacaoId, 'agora': Datas.paraSql(nova.reservadoEm)},
      );
      if (linhas.isEmpty) return null; // outra ONG chegou antes

      await t.executar(
        "UPDATE doacoes SET status = 'reservada' WHERE id = :id",
        {'id': nova.doacaoId},
      );
      final int id;
      try {
        id = await t.inserir(
          '''
          INSERT INTO reservas (doacao_id, ong_id, status, codigo_retirada,
                                reservado_em, expira_em)
          VALUES (:doacao, :ong, 'ativa', :codigo, :reservadoEm, :expiraEm)
          ''',
          {
            'doacao': nova.doacaoId,
            'ong': nova.ongId,
            'codigo': nova.codigo,
            'reservadoEm': Datas.paraSql(nova.reservadoEm),
            'expiraEm': Datas.paraSql(nova.expiraEm),
          },
        );
      } on MySQLServerException catch (erro) {
        // 1062 = "Duplicate entry": o índice UNIQUE barrou uma segunda
        // retirada ativa (3ª camada da RN20). LANÇAR faz a transação dar
        // ROLLBACK, desfazendo também o UPDATE acima.
        if (erro.errorCode == 1062) {
          throw const ConflitoException(
            'DOACAO_INDISPONIVEL',
            'Que pena! Outra ONG aceitou esta doação primeiro.',
          );
        }
        rethrow;
      }
      return _buscarCom(t, id);
    });
  }

  @override
  Future<bool> concluir(int reservaId, DateTime agora) {
    return _db.transacao((t) async {
      final alteradas = await t.executar(
        '''
        UPDATE reservas SET status = 'concluida', encerrada_em = :agora
         WHERE id = :id AND status = 'ativa'
        ''',
        {'id': reservaId, 'agora': Datas.paraSql(agora)},
      );
      if (alteradas != 1) return false;
      await t.executar(
        '''
        UPDATE doacoes d JOIN reservas r ON r.doacao_id = d.id
           SET d.status = 'concluida'
         WHERE r.id = :id
        ''',
        {'id': reservaId},
      );
      return true;
    });
  }

  @override
  Future<bool> encerrarDevolvendo(
    int reservaId, {
    required StatusReserva status,
    required DateTime agora,
    required bool contaDesistencia,
  }) {
    final parametros = {'id': reservaId, 'agora': Datas.paraSql(agora)};
    // Transação: retirada, doação e bloqueio mudam juntos, ou nada muda.
    return _db.transacao((t) async {
      // "AND status = 'ativa'": se o job e a ONG tentarem ao mesmo tempo,
      // só um consegue (o outro altera 0 linhas e recebe false).
      final alteradas = await t.executar(
        '''
        UPDATE reservas
           SET status = :status, encerrada_em = :agora,
               conta_desistencia = :conta
         WHERE id = :id AND status = 'ativa'
        ''',
        {
          ...parametros,
          'status': status.name,
          'conta': contaDesistencia ? 1 : 0,
        },
      );
      if (alteradas != 1) return false;
      await t.executar('''
        UPDATE doacoes d JOIN reservas r ON r.doacao_id = d.id
           SET d.status = 'disponivel'
         WHERE r.id = :id AND d.status = 'reservada'
        ''', parametros);
      if (contaDesistencia) {
        // RN22: esta ONG não pode aceitar a mesma doação de novo.
        // INSERT IGNORE: se o bloqueio já existe, não dá erro.
        await t.executar('''
          INSERT IGNORE INTO bloqueios_doacao (ong_id, doacao_id, criado_em)
          SELECT ong_id, doacao_id, :agora FROM reservas WHERE id = :id
          ''', parametros);
      }
      return true;
    });
  }

  @override
  Future<List<Reserva>> vencidas(DateTime agora) async {
    final linhas = await _db.consultar(
      "$_select WHERE r.status = 'ativa' AND r.expira_em <= :agora",
      {'agora': Datas.paraSql(agora)},
    );
    return [for (final linha in linhas) Mapeador.reserva(linha)];
  }

  @override
  Future<int> desistenciasDesde(int ongId, DateTime desde) async {
    final linhas = await _db.consultar(
      '''
      SELECT COUNT(*) AS total FROM reservas
       WHERE ong_id = :ong AND conta_desistencia = TRUE
         AND encerrada_em >= :desde
      ''',
      {'ong': ongId, 'desde': Datas.paraSql(desde)},
    );
    return int.parse(linhas.first['total'] ?? '0');
  }

  @override
  Future<void> suspender(int ongId, DateTime ate) async {
    await _db.executar(
      'UPDATE perfis SET suspensa_ate = :ate WHERE usuario_id = :ong',
      {'ong': ongId, 'ate': Datas.paraSql(ate)},
    );
  }

  @override
  Future<ControleDoCodigo?> controleDoCodigo(int reservaId) async {
    final linhas = await _db.consultar(
      'SELECT codigo_retirada, tentativas_codigo, bloqueado_ate '
      'FROM reservas WHERE id = :id',
      {'id': reservaId},
    );
    if (linhas.isEmpty) return null;
    final linha = linhas.first;
    final bloqueado = linha['bloqueado_ate'];
    return ControleDoCodigo(
      codigo: linha['codigo_retirada']!,
      tentativas: int.parse(linha['tentativas_codigo'] ?? '0'),
      bloqueadoAte: bloqueado == null ? null : Datas.deSql(bloqueado),
    );
  }

  @override
  Future<void> salvarTentativas(
    int reservaId, {
    required int tentativas,
    DateTime? bloqueadoAte,
  }) async {
    await _db.executar(
      '''
      UPDATE reservas SET tentativas_codigo = :tentativas, bloqueado_ate = :ate
       WHERE id = :id
      ''',
      {
        'id': reservaId,
        'tentativas': tentativas,
        'ate': bloqueadoAte == null ? null : Datas.paraSql(bloqueadoAte),
      },
    );
  }
}
