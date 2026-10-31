import 'package:shared_models/shared_models.dart';

import '../core/db/database.dart';
import '../core/utils/datas.dart';
import 'comunidade_repository.dart';

/// [ComunidadeRepository] no MySQL.
class ComunidadeRepositoryMysql implements ComunidadeRepository {
  ComunidadeRepositoryMysql(this._db);

  final Database _db;

  /// A publicação com tudo o que o feed mostra, numa consulta só:
  /// autor, fotos, número de apoios, se o leitor já apoiou e o resumo da
  /// doação ligada (doador → ONG que retirou).
  static const _select = '''
    SELECT p.*, u.tipo AS tipo_autor, pa.nome_organizacao AS nome_autor,
           pa.verificacao AS verificacao_autor,
           (SELECT GROUP_CONCAT(f.arquivo ORDER BY f.ordem SEPARATOR ',')
              FROM fotos_publicacao f WHERE f.publicacao_id = p.id) AS fotos,
           (SELECT COUNT(*) FROM apoios a WHERE a.publicacao_id = p.id)
             AS apoios,
           EXISTS (SELECT 1 FROM apoios a
                    WHERE a.publicacao_id = p.id AND a.usuario_id = :leitor)
             AS apoiada,
           d.titulo AS titulo_doacao, pd.nome_organizacao AS nome_doador,
           (SELECT po.nome_organizacao FROM reservas r
              JOIN perfis po ON po.usuario_id = r.ong_id
             WHERE r.doacao_id = d.id AND r.status = 'concluida' LIMIT 1)
             AS nome_ong
      FROM publicacoes p
      JOIN usuarios u ON u.id = p.autor_id
      JOIN perfis pa ON pa.usuario_id = p.autor_id
      LEFT JOIN doacoes d ON d.id = p.doacao_id
      LEFT JOIN perfis pd ON pd.usuario_id = d.doador_id
  ''';

  @override
  Future<Impacto> impacto() async {
    final doacoes = (await _db.consultar('''
      SELECT COUNT(*) AS total, COALESCE(SUM(peso_kg), 0) AS kg
        FROM doacoes WHERE status = 'concluida'
      ''')).first;
    final publicacoes = (await _db.consultar(
      'SELECT COALESCE(SUM(familias_ajudadas), 0) AS familias, '
      'COALESCE(SUM(refeicoes), 0) AS refeicoes '
      'FROM publicacoes WHERE oculta = FALSE',
    )).first;
    return Impacto(
      kgSalvos: double.parse(doacoes['kg']!),
      doacoesConcluidas: int.parse(doacoes['total']!),
      familiasAjudadas: int.parse(publicacoes['familias']!),
      refeicoes: int.parse(publicacoes['refeicoes']!),
    );
  }

  @override
  Future<List<Publicacao>> feed(
    int leitorId, {
    required int antesDe,
    required int limite,
  }) async {
    final linhas = await _db.consultar(
      '$_select WHERE p.oculta = FALSE AND (:antes = 0 OR p.id < :antes) '
      'ORDER BY p.id DESC LIMIT :limite',
      {'leitor': leitorId, 'antes': antesDe, 'limite': limite},
    );
    return [for (final l in linhas) _publicacao(l)];
  }

  @override
  Future<Publicacao?> buscar(int publicacaoId, int leitorId) async {
    final linhas = await _db.consultar('$_select WHERE p.id = :id', {
      'leitor': leitorId,
      'id': publicacaoId,
    });
    return linhas.isEmpty ? null : _publicacao(linhas.first);
  }

  @override
  Future<int> criar(int autorId, DadosPublicacao dados, DateTime agora) =>
      _db.inserir(
        '''
        INSERT INTO publicacoes (autor_id, texto, doacao_id,
                                 familias_ajudadas, refeicoes, criado_em)
        VALUES (:autor, :texto, :doacao, :familias, :refeicoes, :agora)
        ''',
        {
          'autor': autorId,
          'texto': dados.texto.trim(),
          'doacao': dados.doacaoId,
          'familias': dados.familiasAjudadas,
          'refeicoes': dados.refeicoes,
          'agora': Datas.paraSql(agora),
        },
      );

  @override
  Future<void> adicionarFoto(int publicacaoId, String arquivo, int ordem) =>
      _db.inserir(
        'INSERT INTO fotos_publicacao (publicacao_id, arquivo, ordem) '
        'VALUES (:publicacao, :arquivo, :ordem)',
        {'publicacao': publicacaoId, 'arquivo': arquivo, 'ordem': ordem},
      );

  @override
  Future<bool> apoiar(int publicacaoId, int usuarioId, DateTime agora) async {
    // INSERT IGNORE: se a chave (publicação, usuário) já existe, não grava
    // de novo e não dá erro (RN41).
    final novas = await _db.executar(
      'INSERT IGNORE INTO apoios (publicacao_id, usuario_id, criado_em) '
      'VALUES (:publicacao, :usuario, :agora)',
      {
        'publicacao': publicacaoId,
        'usuario': usuarioId,
        'agora': Datas.paraSql(agora),
      },
    );
    return novas == 1;
  }

  @override
  Future<void> desfazerApoio(int publicacaoId, int usuarioId) => _db.executar(
    'DELETE FROM apoios '
    'WHERE publicacao_id = :publicacao AND usuario_id = :usuario',
    {'publicacao': publicacaoId, 'usuario': usuarioId},
  );

  @override
  Future<bool> denunciar(
    int publicacaoId,
    int usuarioId,
    MotivoDenuncia motivo,
    DateTime agora,
  ) async {
    final novas = await _db.executar(
      '''
      INSERT IGNORE INTO denuncias (publicacao_id, usuario_id, motivo,
                                    criado_em)
      VALUES (:publicacao, :usuario, :motivo, :agora)
      ''',
      {
        'publicacao': publicacaoId,
        'usuario': usuarioId,
        'motivo': motivo.name,
        'agora': Datas.paraSql(agora),
      },
    );
    return novas == 1;
  }

  @override
  Future<int> denuncias(int publicacaoId) async {
    final linhas = await _db.consultar(
      'SELECT COUNT(*) AS total FROM denuncias '
      'WHERE publicacao_id = :publicacao',
      {'publicacao': publicacaoId},
    );
    return int.parse(linhas.first['total']!);
  }

  @override
  Future<void> ocultar(int publicacaoId) => _db.executar(
    'UPDATE publicacoes SET oculta = TRUE WHERE id = :id',
    {'id': publicacaoId},
  );

  @override
  Future<bool> estaOculta(int publicacaoId) async {
    final linhas = await _db.consultar(
      'SELECT 1 FROM publicacoes WHERE id = :id AND oculta = TRUE',
      {'id': publicacaoId},
    );
    return linhas.isNotEmpty;
  }

  @override
  Future<bool> participouDaDoacaoConcluida(int usuarioId, int doacaoId) async {
    final linhas = await _db.consultar(
      '''
      SELECT 1 FROM doacoes d
       WHERE d.id = :doacao AND d.status = 'concluida'
         AND (d.doador_id = :usuario
              OR EXISTS (SELECT 1 FROM reservas r
                          WHERE r.doacao_id = d.id AND r.ong_id = :usuario
                            AND r.status = 'concluida'))
       LIMIT 1
      ''',
      {'doacao': doacaoId, 'usuario': usuarioId},
    );
    return linhas.isNotEmpty;
  }

  static Publicacao _publicacao(Linha l) {
    final fotos = l['fotos'];
    final titulo = l['titulo_doacao'];
    return Publicacao(
      id: int.parse(l['id']!),
      autorId: int.parse(l['autor_id']!),
      nomeAutor: l['nome_autor']!,
      tipoAutor: TipoUsuario.values.byName(l['tipo_autor']!),
      verificacaoAutor: Verificacao.values.byName(l['verificacao_autor']!),
      texto: l['texto']!,
      criadoEm: Datas.deSql(l['criado_em']!),
      fotos: (fotos == null || fotos.isEmpty) ? const [] : fotos.split(','),
      doacaoId: int.tryParse(l['doacao_id'] ?? ''),
      resumoDoacao: titulo == null
          ? null
          : '$titulo — ${l['nome_doador']}'
                '${l['nome_ong'] == null ? '' : ' → ${l['nome_ong']}'}',
      familiasAjudadas: int.tryParse(l['familias_ajudadas'] ?? ''),
      refeicoes: int.tryParse(l['refeicoes'] ?? ''),
      apoios: int.parse(l['apoios'] ?? '0'),
      apoiadaPorMim: l['apoiada'] == '1',
    );
  }
}
