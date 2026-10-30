import 'package:shared_models/shared_models.dart';

import '../core/db/database.dart';
import '../core/db/mapeador.dart';
import '../core/utils/datas.dart';
import 'doacao_repository.dart';

/// [DoacaoRepository] no MySQL (tabelas `doacoes` e `fotos_doacao`).
class DoacaoRepositoryMysql implements DoacaoRepository {
  DoacaoRepositoryMysql(this._db);

  final Database _db;

  /// A doação com tudo o que as telas mostram, numa consulta só:
  /// - fotos: GROUP_CONCAT junta os nomes em um texto ("a.jpg,b.jpg");
  /// - a retirada ATIVA vem pela coluna gerada `doacao_ativa_id` (no
  ///   máximo uma por doação, garantido pelo índice único).
  static const _select = '''
    SELECT d.*, pd.nome_organizacao AS nome_doador,
           (SELECT GROUP_CONCAT(f.arquivo ORDER BY f.ordem SEPARATOR ',')
              FROM fotos_doacao f WHERE f.doacao_id = d.id) AS fotos,
           po.nome_organizacao AS nome_ong, r.expira_em AS prazo_retirada
      FROM doacoes d
      JOIN perfis pd ON pd.usuario_id = d.doador_id
      LEFT JOIN reservas r ON r.doacao_ativa_id = d.id
      LEFT JOIN perfis po ON po.usuario_id = r.ong_id
  ''';

  @override
  Future<Doacao> criar(
    DadosNovaDoacao dados, {
    required int doadorId,
    required DateTime criadoEm,
  }) async {
    final id = await _db.inserir(
      '''
      INSERT INTO doacoes (doador_id, titulo, descricao, categoria,
                           quantidade_numero, unidade, peso_kg, conservacao,
                           precisa_veiculo, validade, preparado_em,
                           janela_inicio, janela_fim, endereco,
                           latitude, longitude, status, criado_em)
      VALUES (:doador, :titulo, :descricao, :categoria, :quantidade, :unidade,
              :peso, :conservacao, :veiculo, :validade, :preparadoEm,
              :inicio, :fim, :endereco, :lat, :lng, 'disponivel', :criadoEm)
      ''',
      {..._parametros(dados), 'doador': doadorId, 'criadoEm': _sql(criadoEm)},
    );
    return (await buscar(id))!;
  }

  @override
  Future<Doacao> atualizar(int doacaoId, DadosNovaDoacao dados) async {
    await _db.executar(
      '''
      UPDATE doacoes
         SET titulo = :titulo, descricao = :descricao, categoria = :categoria,
             quantidade_numero = :quantidade, unidade = :unidade,
             peso_kg = :peso, conservacao = :conservacao,
             precisa_veiculo = :veiculo, validade = :validade,
             preparado_em = :preparadoEm, janela_inicio = :inicio,
             janela_fim = :fim, endereco = :endereco,
             latitude = :lat, longitude = :lng
       WHERE id = :id
      ''',
      {..._parametros(dados), 'id': doacaoId},
    );
    return (await buscar(doacaoId))!;
  }

  @override
  Future<Doacao?> buscar(int doacaoId) async {
    final linhas = await _db.consultar('$_select WHERE d.id = :id', {
      'id': doacaoId,
    });
    return linhas.isEmpty ? null : Mapeador.doacao(linhas.first);
  }

  @override
  Future<List<Doacao>> doDoador(int doadorId, SituacaoDaLista situacao) async {
    // Os dois textos abaixo são constantes nossas (não vêm do usuário).
    final filtro = situacao == SituacaoDaLista.ativas
        ? "d.status IN ('disponivel', 'reservada')"
        : "d.status IN ('concluida', 'cancelada', 'expirada')";
    final linhas = await _db.consultar(
      '$_select WHERE d.doador_id = :doador AND $filtro '
      'ORDER BY d.criado_em DESC, d.id DESC',
      {'doador': doadorId},
    );
    return [for (final linha in linhas) Mapeador.doacao(linha)];
  }

  @override
  Future<Reserva?> reservaAtiva(int doacaoId) async {
    final linhas = await _db.consultar(
      '''
      SELECT r.*, p.nome_organizacao AS nome_ong
        FROM reservas r JOIN perfis p ON p.usuario_id = r.ong_id
       WHERE r.doacao_ativa_id = :doacao
      ''',
      {'doacao': doacaoId},
    );
    return linhas.isEmpty ? null : Mapeador.reserva(linhas.first);
  }

  @override
  Future<ResumoOrganizacao?> resumo(int usuarioId) async {
    final linhas = await _db.consultar(
      '''
      SELECT p.usuario_id, p.nome_organizacao, p.verificacao, p.telefone,
             p.tipo_estabelecimento, p.transporte, u.nome AS nome_responsavel
        FROM perfis p JOIN usuarios u ON u.id = p.usuario_id
       WHERE p.usuario_id = :id
      ''',
      {'id': usuarioId},
    );
    return linhas.isEmpty ? null : Mapeador.resumo(linhas.first);
  }

  @override
  Future<bool> ongBloqueada(int ongId, int doacaoId) async {
    final linhas = await _db.consultar(
      'SELECT 1 FROM bloqueios_doacao '
      'WHERE ong_id = :ong AND doacao_id = :doacao LIMIT 1',
      {'ong': ongId, 'doacao': doacaoId},
    );
    return linhas.isNotEmpty;
  }

  @override
  Future<void> cancelar(
    int doacaoId, {
    required String? motivo,
    required DateTime agora,
  }) {
    // Transação: a doação e a retirada mudam juntas, ou nenhuma muda.
    return _db.transacao((t) async {
      await t.executar(
        '''
        UPDATE reservas
           SET status = 'canceladaDoador', encerrada_em = :agora,
               motivo = :motivo, conta_desistencia = FALSE
         WHERE doacao_ativa_id = :id
        ''',
        {'id': doacaoId, 'agora': _sql(agora), 'motivo': motivo},
      );
      await t.executar(
        '''
        UPDATE doacoes SET status = 'cancelada', motivo_cancelamento = :motivo
         WHERE id = :id
        ''',
        {'id': doacaoId, 'motivo': motivo},
      );
    });
  }

  @override
  Future<int> expirarJanelasEncerradas(DateTime agora) => _db.executar(
    '''
    UPDATE doacoes SET status = 'expirada'
     WHERE status = 'disponivel' AND janela_fim <= :agora
    ''',
    {'agora': _sql(agora)},
  );

  @override
  Future<void> adicionarFoto(int doacaoId, String arquivo, int ordem) async {
    await _db.inserir(
      'INSERT INTO fotos_doacao (doacao_id, arquivo, ordem) '
      'VALUES (:doacao, :arquivo, :ordem)',
      {'doacao': doacaoId, 'arquivo': arquivo, 'ordem': ordem},
    );
  }

  /// Os parâmetros em comum do INSERT e do UPDATE.
  static Map<String, Object?> _parametros(DadosNovaDoacao dados) => {
    'titulo': dados.titulo,
    'descricao': dados.descricao,
    'categoria': dados.categoria.name,
    'quantidade': dados.quantidade,
    'unidade': dados.unidade.name,
    'peso': dados.pesoKg,
    'conservacao': dados.conservacao.name,
    'veiculo': dados.veiculo?.name,
    'validade': Datas.dataParaSql(dados.validade),
    'preparadoEm': dados.preparadoEm == null ? null : _sql(dados.preparadoEm!),
    'inicio': _sql(dados.janelaInicio),
    'fim': _sql(dados.janelaFim),
    'endereco': dados.endereco,
    'lat': dados.latitude,
    'lng': dados.longitude,
  };

  static String _sql(DateTime instante) => Datas.paraSql(instante);
}
