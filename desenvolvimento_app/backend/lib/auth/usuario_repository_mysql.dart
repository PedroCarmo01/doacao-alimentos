import 'package:shared_models/shared_models.dart';

import '../core/db/database.dart';
import '../core/db/mapeador.dart';
import '../core/utils/datas.dart';
import 'usuario_repository.dart';

/// [UsuarioRepository] gravando no MySQL (tabelas `usuarios` e `perfis`).
class UsuarioRepositoryMysql implements UsuarioRepository {
  UsuarioRepositoryMysql(this._db);

  final Database _db;

  /// Colunas com os nomes que o Mapeador espera (usuario + perfil).
  ///
  /// Não é SQL Injection: este texto é uma constante escrita por nós. O que
  /// vem do usuário entra só pelos parâmetros `:email`, `:id` etc.
  static const _selectConta = '''
    SELECT u.id, u.nome, u.email, u.tipo, u.senha_hash, p.*
      FROM usuarios u
      JOIN perfis p ON p.usuario_id = u.id
  ''';

  @override
  Future<bool> emailEmUso(String email) async {
    final linhas = await _db.consultar(
      'SELECT 1 FROM usuarios WHERE email = :email LIMIT 1',
      {'email': email},
    );
    return linhas.isNotEmpty;
  }

  @override
  Future<bool> documentoEmUso(String documento) async {
    final linhas = await _db.consultar(
      'SELECT 1 FROM perfis WHERE documento = :documento LIMIT 1',
      {'documento': documento},
    );
    return linhas.isNotEmpty;
  }

  @override
  Future<Conta> criar(
    DadosCadastro dados, {
    required String senhaHash,
    required DateTime criadoEm,
    required Verificacao verificacao,
    String? razaoSocial,
  }) async {
    // Transação: se o INSERT do perfil falhar, o usuário também não fica
    // gravado (não sobra conta "pela metade").
    final id = await _db.transacao((t) async {
      final novoId = await t.inserir(
        '''
        INSERT INTO usuarios (nome, email, senha_hash, tipo, criado_em)
        VALUES (:nome, :email, :hash, :tipo, :criadoEm)
        ''',
        {
          'nome': dados.nome,
          'email': dados.email,
          'hash': senhaHash,
          'tipo': dados.tipo.name,
          'criadoEm': Datas.paraSql(criadoEm),
        },
      );
      await t.executar(
        '''
        INSERT INTO perfis (usuario_id, nome_organizacao, tipo_estabelecimento,
                            tipo_documento, documento, razao_social,
                            verificacao, telefone, endereco, cep,
                            latitude, longitude, familias_atendidas,
                            transporte, info_extra)
        VALUES (:id, :organizacao, :estabelecimento, :tipoDocumento,
                :documento, :razao, :verificacao, :telefone, :endereco, :cep,
                :lat, :lng, :familias, :transporte, :infoExtra)
        ''',
        {
          'id': novoId,
          'organizacao': dados.nomeOrganizacao,
          'estabelecimento': dados.tipoEstabelecimento?.name,
          'tipoDocumento': dados.tipoDocumento.name,
          'documento': dados.documento,
          'razao': razaoSocial,
          'verificacao': verificacao.name,
          'telefone': dados.telefone,
          'endereco': dados.endereco,
          'cep': dados.cep,
          'lat': dados.latitude,
          'lng': dados.longitude,
          'familias': dados.familiasAtendidas,
          'transporte': dados.transporte?.name,
          'infoExtra': dados.infoExtra,
        },
      );
      return novoId;
    });
    // Lê de volta do banco: assim a conta devolvida tem os valores
    // padrão que o MySQL preencheu (busca_ativa, raio_km...).
    final conta = await buscarConta(id);
    if (conta == null) throw StateError('Conta $id não foi gravada.');
    return conta;
  }

  @override
  Future<UsuarioComSenha?> buscarPorEmail(String email) async {
    final linhas = await _db.consultar('$_selectConta WHERE u.email = :email', {
      'email': email,
    });
    if (linhas.isEmpty) return null;
    final linha = linhas.first;
    return UsuarioComSenha(
      conta: Mapeador.conta(linha),
      senhaHash: linha['senha_hash']!,
    );
  }

  @override
  Future<Conta?> buscarConta(int usuarioId) async {
    final linhas = await _db.consultar('$_selectConta WHERE u.id = :id', {
      'id': usuarioId,
    });
    return linhas.isEmpty ? null : Mapeador.conta(linhas.first);
  }
}
