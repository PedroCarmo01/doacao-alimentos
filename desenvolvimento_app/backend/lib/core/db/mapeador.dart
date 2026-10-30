import 'package:shared_models/shared_models.dart';

import '../utils/datas.dart';
import 'database.dart';

/// Converte linhas do banco (texto, snake_case) em modelos do
/// `shared_models` (tipados, camelCase).
///
/// Foi a falta desta camada que fazia o app receber `"doador_id": "1"` em
/// vez de `"doadorId": 1` (achado A01 da análise técnica).
///
/// Nomes de coluna esperados (use estes aliases nas queries):
/// - usuario: `id, nome, email, tipo`
/// - perfil:  todas as colunas de `perfis` (nas queries: `p.*`)
/// - doacao:  colunas de `doacoes` + opcionais `fotos` (nomes separados por
///   vírgula), `nome_doador`, `distancia_km`, `nome_ong`, `prazo_retirada`
/// - reserva: colunas de `reservas` + opcionais `titulo_doacao`, `nome_ong`
abstract final class Mapeador {
  static Usuario usuario(Linha linha) => Usuario(
    id: _inteiro(linha, 'id'),
    nome: _texto(linha, 'nome'),
    email: _texto(linha, 'email'),
    tipo: TipoUsuario.values.byName(_texto(linha, 'tipo')),
  );

  static Perfil perfil(Linha linha) => Perfil(
    usuarioId: _inteiro(linha, 'usuario_id'),
    nomeOrganizacao: _texto(linha, 'nome_organizacao'),
    tipoEstabelecimento: _enumOpcional(
      linha,
      'tipo_estabelecimento',
      TipoEstabelecimento.values,
    ),
    tipoDocumento: TipoDocumento.values.byName(_texto(linha, 'tipo_documento')),
    documento: _texto(linha, 'documento'),
    razaoSocial: linha['razao_social'],
    verificacao: Verificacao.values.byName(_texto(linha, 'verificacao')),
    telefone: linha['telefone'],
    endereco: linha['endereco'],
    cep: linha['cep'],
    latitude: _decimal(linha, 'latitude'),
    longitude: _decimal(linha, 'longitude'),
    familiasAtendidas: _inteiroOpcional(linha, 'familias_atendidas'),
    transporte: _enumOpcional(linha, 'transporte', Transporte.values),
    buscaAtiva: _booleano(linha, 'busca_ativa'),
    raioKm: _decimal(linha, 'raio_km'),
    suspensaAte: _instanteOpcional(linha, 'suspensa_ate'),
    infoExtra: linha['info_extra'],
  );

  /// Linha de um `JOIN` entre `usuarios` e `perfis`.
  static Conta conta(Linha linha) =>
      Conta(usuario: usuario(linha), perfil: perfil(linha));

  static Doacao doacao(Linha linha) => Doacao(
    id: _inteiro(linha, 'id'),
    doadorId: _inteiro(linha, 'doador_id'),
    titulo: _texto(linha, 'titulo'),
    descricao: linha['descricao'],
    categoria: CategoriaAlimento.values.byName(_texto(linha, 'categoria')),
    quantidade: _decimal(linha, 'quantidade_numero'),
    unidade: Unidade.values.byName(_texto(linha, 'unidade')),
    pesoKg: _decimal(linha, 'peso_kg'),
    conservacao: Conservacao.values.byName(_texto(linha, 'conservacao')),
    veiculo: _enumOpcional(linha, 'precisa_veiculo', VeiculoNecessario.values),
    validade: Datas.dataDeSql(_texto(linha, 'validade')),
    preparadoEm: _instanteOpcional(linha, 'preparado_em'),
    janelaInicio: Datas.deSql(_texto(linha, 'janela_inicio')),
    janelaFim: Datas.deSql(_texto(linha, 'janela_fim')),
    endereco: linha['endereco'],
    latitude: _decimal(linha, 'latitude'),
    longitude: _decimal(linha, 'longitude'),
    status: StatusDoacao.values.byName(_texto(linha, 'status')),
    motivoCancelamento: linha['motivo_cancelamento'],
    criadoEm: Datas.deSql(_texto(linha, 'criado_em')),
    fotos: _lista(linha, 'fotos'),
    nomeDoador: linha['nome_doador'],
    distanciaKm: _decimalOpcional(linha, 'distancia_km'),
    nomeOng: linha['nome_ong'],
    prazoRetirada: _instanteOpcional(linha, 'prazo_retirada'),
  );

  static Reserva reserva(Linha linha) => Reserva(
    id: _inteiro(linha, 'id'),
    doacaoId: _inteiro(linha, 'doacao_id'),
    ongId: _inteiro(linha, 'ong_id'),
    status: StatusReserva.values.byName(_texto(linha, 'status')),
    reservadoEm: Datas.deSql(_texto(linha, 'reservado_em')),
    expiraEm: Datas.deSql(_texto(linha, 'expira_em')),
    encerradaEm: _instanteOpcional(linha, 'encerrada_em'),
    motivo: linha['motivo'],
    tituloDoacao: linha['titulo_doacao'],
    nomeOng: linha['nome_ong'],
  );

  /// Colunas: `usuario_id, nome_organizacao, verificacao, nome_responsavel,
  /// telefone, tipo_estabelecimento, transporte`.
  static ResumoOrganizacao resumo(Linha linha) => ResumoOrganizacao(
    usuarioId: _inteiro(linha, 'usuario_id'),
    nomeOrganizacao: _texto(linha, 'nome_organizacao'),
    verificacao: Verificacao.values.byName(_texto(linha, 'verificacao')),
    nomeResponsavel: linha['nome_responsavel'],
    telefone: linha['telefone'],
    tipoEstabelecimento: _enumOpcional(
      linha,
      'tipo_estabelecimento',
      TipoEstabelecimento.values,
    ),
    transporte: _enumOpcional(linha, 'transporte', Transporte.values),
  );

  /// Texto "a.jpg,b.jpg" (GROUP_CONCAT do MySQL) → lista. Nulo = vazia.
  static List<String> _lista(Linha linha, String coluna) {
    final valor = linha[coluna];
    if (valor == null || valor.isEmpty) return const [];
    return valor.split(',');
  }

  static String _texto(Linha linha, String coluna) =>
      linha[coluna] ??
      (throw StateError(
        'A coluna "$coluna" não veio na consulta (ou veio nula). '
        'Confira o SELECT e os aliases.',
      ));

  static int _inteiro(Linha linha, String coluna) =>
      int.parse(_texto(linha, coluna));

  static double _decimal(Linha linha, String coluna) =>
      double.parse(_texto(linha, coluna));

  static int? _inteiroOpcional(Linha linha, String coluna) {
    final valor = linha[coluna];
    return valor == null ? null : int.parse(valor);
  }

  /// O MySQL guarda BOOLEAN como número: '1' = verdadeiro, '0' = falso.
  static bool _booleano(Linha linha, String coluna) =>
      _texto(linha, coluna) == '1';

  static T? _enumOpcional<T extends Enum>(
    Linha linha,
    String coluna,
    List<T> valores,
  ) {
    final valor = linha[coluna];
    return valor == null ? null : valores.byName(valor);
  }

  static double? _decimalOpcional(Linha linha, String coluna) {
    final valor = linha[coluna];
    return valor == null ? null : double.parse(valor);
  }

  static DateTime? _instanteOpcional(Linha linha, String coluna) {
    final valor = linha[coluna];
    return valor == null ? null : Datas.deSql(valor);
  }
}
