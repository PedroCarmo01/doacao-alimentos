import 'package:mysql_client/mysql_client.dart';

import '../config/env.dart';

/// Uma linha de resultado: nome da coluna → valor em texto (ou `null`).
///
/// O driver devolve TUDO como texto. A conversão para `int`, `double` e
/// `DateTime` fica em um único lugar: o `Mapeador`.
typedef Linha = Map<String, String?>;

/// Operações SQL que o banco e uma transação oferecem.
///
/// Os repositórios recebem um [ExecutorSql]. Assim, o mesmo código de
/// repositório funciona dentro ou fora de uma transação.
///
/// SEMPRE use parâmetros nomeados (`WHERE id = :id`), nunca concatene
/// texto na query. Isso impede SQL Injection.
abstract interface class ExecutorSql {
  /// `SELECT`: devolve as linhas encontradas.
  Future<List<Linha>> consultar(String sql, [Map<String, Object?>? parametros]);

  /// `UPDATE`/`DELETE`: devolve quantas linhas foram afetadas.
  Future<int> executar(String sql, [Map<String, Object?>? parametros]);

  /// `INSERT`: devolve o id gerado pelo `AUTO_INCREMENT`.
  Future<int> inserir(String sql, [Map<String, Object?>? parametros]);
}

/// Acesso ao MySQL por meio de um *pool* de conexões.
///
/// O pool abre conexões sob demanda e substitui as que o servidor encerrar
/// (por exemplo, depois de horas sem uso).
class Database implements ExecutorSql {
  Database._(this._pool);

  factory Database.conectar(Env env) => Database._(
        MySQLConnectionPool(
          host: env.dbHost,
          port: env.dbPorta,
          userName: env.dbUsuario,
          password: env.dbSenha,
          databaseName: env.dbNome,
          maxConnections: 5,
          secure: env.dbTls,
        ),
      );

  final MySQLConnectionPool _pool;

  @override
  Future<List<Linha>> consultar(
    String sql, [
    Map<String, Object?>? parametros,
  ]) async {
    final resultado = await _pool.execute(sql, parametros);
    return [for (final linha in resultado.rows) linha.assoc()];
  }

  @override
  Future<int> executar(String sql, [Map<String, Object?>? parametros]) async {
    final resultado = await _pool.execute(sql, parametros);
    return resultado.affectedRows.toInt();
  }

  @override
  Future<int> inserir(String sql, [Map<String, Object?>? parametros]) async {
    final resultado = await _pool.execute(sql, parametros);
    return resultado.lastInsertID.toInt();
  }

  /// Executa [acao] em uma TRANSAÇÃO: ou tudo é gravado (COMMIT) ou, se
  /// qualquer exceção acontecer lá dentro, nada é gravado (ROLLBACK).
  Future<T> transacao<T>(Future<T> Function(ExecutorSql transacao) acao) =>
      _pool.transactional((conexao) => acao(_Transacao(conexao)));

  /// `true` se o banco responde. Usado pelo health check (`GET /`).
  Future<bool> ping() async {
    try {
      await _pool.execute('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fechar() => _pool.close();
}

/// As mesmas operações, mas em uma conexão que está dentro de uma transação.
class _Transacao implements ExecutorSql {
  _Transacao(this._conexao);

  final MySQLConnection _conexao;

  @override
  Future<List<Linha>> consultar(
    String sql, [
    Map<String, Object?>? parametros,
  ]) async {
    final resultado = await _conexao.execute(sql, parametros);
    return [for (final linha in resultado.rows) linha.assoc()];
  }

  @override
  Future<int> executar(String sql, [Map<String, Object?>? parametros]) async {
    final resultado = await _conexao.execute(sql, parametros);
    return resultado.affectedRows.toInt();
  }

  @override
  Future<int> inserir(String sql, [Map<String, Object?>? parametros]) async {
    final resultado = await _conexao.execute(sql, parametros);
    return resultado.lastInsertID.toInt();
  }
}
