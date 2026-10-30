import 'package:shared_models/shared_models.dart';

import '../core/db/database.dart';
import 'perfil_repository.dart';

/// [PerfilRepository] gravando no MySQL (tabelas `perfis` e `usuarios`).
class PerfilRepositoryMysql implements PerfilRepository {
  PerfilRepositoryMysql(this._db);

  final Database _db;

  @override
  Future<void> atualizar(int usuarioId, DadosPerfil dados) {
    // Transação: o nome do responsável (usuarios) e os dados da
    // organização (perfis) mudam juntos, ou nenhum muda.
    return _db.transacao((t) async {
      await t.executar('UPDATE usuarios SET nome = :nome WHERE id = :id', {
        'nome': dados.nome,
        'id': usuarioId,
      });
      await t.executar(
        '''
        UPDATE perfis
           SET nome_organizacao = :organizacao, telefone = :telefone,
               endereco = :endereco, cep = :cep,
               latitude = :lat, longitude = :lng,
               familias_atendidas = :familias, transporte = :transporte,
               info_extra = :infoExtra,
               busca_ativa = :buscaAtiva, raio_km = :raioKm
         WHERE usuario_id = :id
        ''',
        {
          'organizacao': dados.nomeOrganizacao,
          'telefone': dados.telefone,
          'endereco': dados.endereco,
          'cep': dados.cep,
          'lat': dados.latitude,
          'lng': dados.longitude,
          'familias': dados.familiasAtendidas,
          'transporte': dados.transporte?.name,
          'infoExtra': dados.infoExtra,
          'buscaAtiva': dados.buscaAtiva ? 1 : 0,
          'raioKm': dados.raioKm,
          'id': usuarioId,
        },
      );
    });
  }

  @override
  Future<List<PerfilPendente>> pendentesDeVerificacao({
    required int limite,
  }) async {
    final linhas = await _db.consultar(
      '''
      SELECT p.usuario_id, p.documento, u.tipo
        FROM perfis p
        JOIN usuarios u ON u.id = p.usuario_id
       WHERE p.verificacao = 'pendente' AND p.tipo_documento = 'cnpj'
       ORDER BY p.usuario_id
       LIMIT :limite
      ''',
      {'limite': limite},
    );
    return [
      for (final linha in linhas)
        PerfilPendente(
          usuarioId: int.parse(linha['usuario_id']!),
          tipo: TipoUsuario.values.byName(linha['tipo']!),
          cnpj: linha['documento']!,
        ),
    ];
  }

  @override
  Future<void> marcarVerificada(
    int usuarioId, {
    required String razaoSocial,
  }) async {
    await _db.executar(
      '''
      UPDATE perfis SET verificacao = 'verificada', razao_social = :razao
       WHERE usuario_id = :id
      ''',
      {'razao': razaoSocial, 'id': usuarioId},
    );
  }
}
