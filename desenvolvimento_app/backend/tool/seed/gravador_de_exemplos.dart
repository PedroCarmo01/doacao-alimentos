import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/utils/datas.dart';

/// Os INSERTs dos dados de exemplo, um método por tabela.
///
/// Fica separado do `seed.dart` para que lá apareça só a "história" dos
/// dados (quem doou o quê, quem retirou), sem o SQL no meio.
class GravadorDeExemplos {
  GravadorDeExemplos(this._banco, {required this.senhaHash});

  final ExecutorSql _banco;

  /// Hash bcrypt de "senha123", calculado uma vez só (bcrypt é lento).
  final String senhaHash;

  /// Apaga tudo, na ordem "filhas antes das mães" (chaves estrangeiras).
  Future<void> apagarTudo() async {
    for (final tabela in const [
      'denuncias',
      'apoios',
      'fotos_publicacao',
      'publicacoes',
      'mensagens',
      'dispositivos',
      'notificacoes',
      'bloqueios_doacao',
      'reservas',
      'fotos_doacao',
      'doacoes',
      'perfis',
      'usuarios',
    ]) {
      // Os nomes vêm da lista fixa acima, escrita por nós: não é texto do
      // usuário, então não há risco de SQL Injection.
      await _banco.executar('DELETE FROM $tabela');
    }
  }

  Future<int> conta({
    required TipoUsuario tipo,
    required String responsavel,
    required String email,
    required String organizacao,
    required String documento,
    required String endereco,
    required Coordenadas local,
    required DateTime criadaEm,
    TipoEstabelecimento? estabelecimento,
    Verificacao verificacao = Verificacao.verificada,
    String? razaoSocial,
    int? familias,
    Transporte? transporte,
    DateTime? suspensaAte,
    String? infoExtra,
  }) async {
    final id = await _banco.inserir(
      'INSERT INTO usuarios (nome, email, senha_hash, tipo, criado_em) '
      'VALUES (:nome, :email, :hash, :tipo, :criadoEm)',
      {
        'nome': responsavel,
        'email': email,
        'hash': senhaHash,
        'tipo': tipo.name,
        'criadoEm': Datas.paraSql(criadaEm),
      },
    );
    await _banco.executar(
      '''
      INSERT INTO perfis (usuario_id, nome_organizacao, tipo_estabelecimento,
                          tipo_documento, documento, razao_social, verificacao,
                          telefone, endereco, cep, latitude, longitude,
                          familias_atendidas, transporte, suspensa_ate,
                          info_extra)
      VALUES (:id, :organizacao, :estabelecimento, :tipoDocumento, :documento,
              :razao, :verificacao, '(11) 4799-0000', :endereco, '08780000',
              :lat, :lng, :familias, :transporte, :suspensaAte, :infoExtra)
      ''',
      {
        'id': id,
        'organizacao': organizacao,
        'estabelecimento': estabelecimento?.name,
        'tipoDocumento': TipoDocumento.doNumero(documento).name,
        'documento': documento,
        'razao': razaoSocial,
        'verificacao': verificacao.name,
        'endereco': endereco,
        'lat': local.latitude,
        'lng': local.longitude,
        'familias': familias,
        'transporte': transporte?.name,
        'suspensaAte': suspensaAte == null ? null : Datas.paraSql(suspensaAte),
        'infoExtra': infoExtra,
      },
    );
    return id;
  }

  /// Cria uma doação. [categoria], [unidade], [conservacao] e [status] são
  /// os valores dos ENUM do banco (o modelo Dart da doação muda na etapa 2).
  Future<int> doacao({
    required int doadorId,
    required String titulo,
    required String categoria,
    required double quantidade,
    required String unidade,
    required double pesoKg,
    required String conservacao,
    required DateTime validade,
    required DateTime inicio,
    required DateTime fim,
    required Coordenadas local,
    required String status,
    required DateTime criadaEm,
    String? descricao,
    DateTime? preparadoEm,
  }) {
    return _banco.inserir(
      '''
      INSERT INTO doacoes (doador_id, titulo, descricao, categoria,
                           quantidade_numero, unidade, peso_kg, conservacao,
                           validade, preparado_em, janela_inicio, janela_fim,
                           latitude, longitude, status, criado_em)
      VALUES (:doadorId, :titulo, :descricao, :categoria, :quantidade,
              :unidade, :peso, :conservacao, :validade, :preparadoEm,
              :inicio, :fim, :lat, :lng, :status, :criadoEm)
      ''',
      {
        'doadorId': doadorId,
        'titulo': titulo,
        'descricao': descricao,
        'categoria': categoria,
        'quantidade': quantidade,
        'unidade': unidade,
        'peso': pesoKg,
        'conservacao': conservacao,
        'validade': Datas.dataParaSql(validade),
        'preparadoEm': preparadoEm == null ? null : Datas.paraSql(preparadoEm),
        'inicio': Datas.paraSql(inicio),
        'fim': Datas.paraSql(fim),
        'lat': local.latitude,
        'lng': local.longitude,
        'status': status,
        'criadoEm': Datas.paraSql(criadaEm),
      },
    );
  }

  Future<int> reserva({
    required int doacaoId,
    required int ongId,
    required String status,
    required String codigo,
    required DateTime reservadaEm,
    required DateTime expiraEm,
    DateTime? encerradaEm,
    bool contaDesistencia = false,
  }) {
    return _banco.inserir(
      '''
      INSERT INTO reservas (doacao_id, ong_id, status, codigo_retirada,
                            reservado_em, expira_em, encerrada_em,
                            conta_desistencia)
      VALUES (:doacaoId, :ongId, :status, :codigo, :reservadaEm, :expiraEm,
              :encerradaEm, :desistencia)
      ''',
      {
        'doacaoId': doacaoId,
        'ongId': ongId,
        'status': status,
        'codigo': codigo,
        'reservadaEm': Datas.paraSql(reservadaEm),
        'expiraEm': Datas.paraSql(expiraEm),
        'encerradaEm': encerradaEm == null ? null : Datas.paraSql(encerradaEm),
        'desistencia': contaDesistencia ? 1 : 0,
      },
    );
  }

  /// RN22: a ONG não pode aceitar esta doação de novo.
  Future<void> bloqueio({
    required int ongId,
    required int doacaoId,
    required DateTime em,
  }) async {
    await _banco.executar(
      'INSERT INTO bloqueios_doacao (ong_id, doacao_id, criado_em) '
      'VALUES (:ong, :doacao, :em)',
      {'ong': ongId, 'doacao': doacaoId, 'em': Datas.paraSql(em)},
    );
  }

  /// [autorId] `null` = mensagem do sistema.
  Future<void> mensagem({
    required int reservaId,
    required int? autorId,
    required String texto,
    required DateTime em,
    bool lida = true,
  }) async {
    await _banco.inserir(
      'INSERT INTO mensagens (reserva_id, autor_id, texto, criado_em, lida_em) '
      'VALUES (:reserva, :autor, :texto, :em, :lidaEm)',
      {
        'reserva': reservaId,
        'autor': autorId,
        'texto': texto,
        'em': Datas.paraSql(em),
        'lidaEm': lida ? Datas.paraSql(em) : null,
      },
    );
  }

  Future<int> publicacao({
    required int autorId,
    required String texto,
    required DateTime em,
    int? doacaoId,
    int? familias,
    int? refeicoes,
  }) {
    return _banco.inserir(
      '''
      INSERT INTO publicacoes (autor_id, texto, doacao_id, familias_ajudadas,
                               refeicoes, criado_em)
      VALUES (:autor, :texto, :doacao, :familias, :refeicoes, :em)
      ''',
      {
        'autor': autorId,
        'texto': texto,
        'doacao': doacaoId,
        'familias': familias,
        'refeicoes': refeicoes,
        'em': Datas.paraSql(em),
      },
    );
  }

  /// RN41: cada conta apoia uma publicação no máximo uma vez.
  Future<void> apoio({
    required int publicacaoId,
    required int usuarioId,
    required DateTime em,
  }) async {
    await _banco.executar(
      'INSERT INTO apoios (publicacao_id, usuario_id, criado_em) '
      'VALUES (:publicacao, :usuario, :em)',
      {
        'publicacao': publicacaoId,
        'usuario': usuarioId,
        'em': Datas.paraSql(em),
      },
    );
  }
}
