import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/config/env.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/senha_service.dart';
import 'package:summit_backend/core/utils/datas.dart';

/// Recria os DADOS DE EXEMPLO. ATENÇÃO: apaga os dados atuais do banco.
///
/// Uso, dentro da pasta `backend`:
///
///     dart run tool/seed.dart
///
/// Todos os usuários criados têm a senha `senha123`. As coordenadas ficam
/// na região central de Mogi das Cruzes (SP); uma ONG fica longe de propósito
/// (fora do raio de 10 km) para testar o filtro de proximidade.
Future<void> main() async {
  final env = Env.carregar();
  final banco = Database.conectar(env);
  final agora = const RelogioSistema().agora();
  final hoje = Calendario.dataNoFuso(agora, env.fusoHorarioUtc);
  final hash = const SenhaService().gerarHash('senha123');

  try {
    await _apagarDados(banco);

    final mercado = await _criarConta(
      banco,
      tipo: TipoUsuario.doador,
      nome: 'Gerente do Mercado',
      email: 'mercado@exemplo.com',
      organizacao: 'Mercado Bom Preço',
      endereco: 'Rua Principal, 100 - Centro',
      local: const Coordenadas(-23.5229, -46.1880),
      hash: hash,
      agora: agora,
    );
    final padaria = await _criarConta(
      banco,
      tipo: TipoUsuario.doador,
      nome: 'Dono da Padaria',
      email: 'padaria@exemplo.com',
      organizacao: 'Padaria Pão Quente',
      endereco: 'Avenida das Flores, 250',
      local: const Coordenadas(-23.5262, -46.1932),
      hash: hash,
      agora: agora,
    );
    final maosAmigas = await _criarConta(
      banco,
      tipo: TipoUsuario.ong,
      nome: 'Coordenação Mãos Amigas',
      email: 'maosamigas@exemplo.com',
      organizacao: 'ONG Mãos Amigas',
      endereco: 'Rua da Solidariedade, 45',
      local: const Coordenadas(-23.5180, -46.1850),
      hash: hash,
      agora: agora,
    );
    final pratoCheio = await _criarConta(
      banco,
      tipo: TipoUsuario.ong,
      nome: 'Coordenação Prato Cheio',
      email: 'pratocheio@exemplo.com',
      organizacao: 'Instituto Prato Cheio',
      endereco: 'Travessa do Bem, 12',
      local: const Coordenadas(-23.5400, -46.2100),
      hash: hash,
      agora: agora,
    );
    await _criarConta(
      banco,
      tipo: TipoUsuario.ong,
      nome: 'Coordenação Distante',
      email: 'distante@exemplo.com',
      organizacao: 'Associação Distante',
      endereco: 'Praça da Sé - São Paulo',
      local: const Coordenadas(-23.5505, -46.6333),
      hash: hash,
      agora: agora,
    );

    await _criarDoacao(
      banco,
      doadorId: mercado,
      titulo: 'Frutas e verduras do dia',
      categoria: CategoriaAlimento.hortifruti,
      quantidade: '5 caixas',
      validade: hoje.add(const Duration(days: 2)),
      inicio: agora.subtract(const Duration(hours: 1)),
      fim: agora.add(const Duration(hours: 6)),
      local: const Coordenadas(-23.5229, -46.1880),
      status: StatusDoacao.disponivel,
      agora: agora,
    );
    await _criarDoacao(
      banco,
      doadorId: padaria,
      titulo: 'Pães do dia anterior',
      categoria: CategoriaAlimento.padaria,
      quantidade: '30 unidades',
      validade: hoje.add(const Duration(days: 1)),
      inicio: agora,
      fim: agora.add(const Duration(hours: 4)),
      local: const Coordenadas(-23.5262, -46.1932),
      status: StatusDoacao.disponivel,
      agora: agora,
    );
    await _criarDoacao(
      banco,
      doadorId: mercado,
      titulo: 'Iogurtes perto do vencimento',
      categoria: CategoriaAlimento.laticinios,
      quantidade: '24 potes',
      validade: hoje.add(const Duration(days: 3)),
      inicio: agora.add(const Duration(hours: 1)),
      fim: agora.add(const Duration(hours: 8)),
      local: const Coordenadas(-23.5229, -46.1880),
      status: StatusDoacao.disponivel,
      agora: agora,
    );

    // Uma doação já reservada (reserva ativa) ...
    final cestas = await _criarDoacao(
      banco,
      doadorId: mercado,
      titulo: 'Cestas de mercearia',
      categoria: CategoriaAlimento.mercearia,
      quantidade: '10 cestas',
      validade: hoje.add(const Duration(days: 30)),
      inicio: agora,
      fim: agora.add(const Duration(hours: 5)),
      local: const Coordenadas(-23.5229, -46.1880),
      status: StatusDoacao.reservada,
      agora: agora,
    );
    await _criarReserva(
      banco,
      doacaoId: cestas,
      ongId: maosAmigas,
      status: StatusReserva.ativa,
      reservadoEm: agora,
      expiraEm: agora.add(env.prazoReserva),
    );

    // ... e uma já concluída, para aparecer no histórico.
    final bolos = await _criarDoacao(
      banco,
      doadorId: padaria,
      titulo: 'Bolos e salgados',
      categoria: CategoriaAlimento.refeicoesProntas,
      quantidade: '15 porções',
      validade: hoje,
      inicio: agora.subtract(const Duration(hours: 5)),
      fim: agora.subtract(const Duration(hours: 1)),
      local: const Coordenadas(-23.5262, -46.1932),
      status: StatusDoacao.concluida,
      agora: agora,
    );
    await _criarReserva(
      banco,
      doacaoId: bolos,
      ongId: pratoCheio,
      status: StatusReserva.concluida,
      reservadoEm: agora.subtract(const Duration(hours: 4)),
      expiraEm: agora.subtract(const Duration(hours: 2)),
      retiradoEm: agora.subtract(const Duration(hours: 3)),
    );

    print('''
Dados de exemplo criados. Senha de todos os usuários: senha123

  doador  mercado@exemplo.com     Mercado Bom Preço
  doador  padaria@exemplo.com     Padaria Pão Quente
  ong     maosamigas@exemplo.com  ONG Mãos Amigas (cerca de 0,6 km do mercado)
  ong     pratocheio@exemplo.com  Instituto Prato Cheio (cerca de 3 km)
  ong     distante@exemplo.com    Associação Distante (cerca de 45 km: fora do raio)

Doações: 3 disponíveis, 1 reservada (Mãos Amigas) e 1 concluída (histórico).
''');
  } finally {
    await banco.fechar();
  }
}

Future<void> _apagarDados(ExecutorSql banco) async {
  // Ordem "filhas antes das mães" por causa das chaves estrangeiras.
  await banco.executar('DELETE FROM reservas');
  await banco.executar('DELETE FROM doacoes');
  await banco.executar('DELETE FROM perfis');
  await banco.executar('DELETE FROM usuarios');
}

Future<int> _criarConta(
  ExecutorSql banco, {
  required TipoUsuario tipo,
  required String nome,
  required String email,
  required String organizacao,
  required String endereco,
  required Coordenadas local,
  required String hash,
  required DateTime agora,
}) async {
  final id = await banco.inserir(
    'INSERT INTO usuarios (nome, email, senha_hash, tipo, criado_em) '
    'VALUES (:nome, :email, :hash, :tipo, :criadoEm)',
    {
      'nome': nome,
      'email': email,
      'hash': hash,
      'tipo': tipo.name,
      'criadoEm': Datas.paraSql(agora),
    },
  );
  await banco.executar(
    'INSERT INTO perfis '
    '(usuario_id, nome_organizacao, endereco, latitude, longitude) '
    'VALUES (:usuarioId, :organizacao, :endereco, :latitude, :longitude)',
    {
      'usuarioId': id,
      'organizacao': organizacao,
      'endereco': endereco,
      'latitude': local.latitude,
      'longitude': local.longitude,
    },
  );
  return id;
}

Future<int> _criarDoacao(
  ExecutorSql banco, {
  required int doadorId,
  required String titulo,
  required CategoriaAlimento categoria,
  required String quantidade,
  required DateTime validade,
  required DateTime inicio,
  required DateTime fim,
  required Coordenadas local,
  required StatusDoacao status,
  required DateTime agora,
}) {
  return banco.inserir(
    'INSERT INTO doacoes (doador_id, titulo, categoria, quantidade, validade, '
    'janela_inicio, janela_fim, latitude, longitude, status, criado_em) '
    'VALUES (:doadorId, :titulo, :categoria, :quantidade, :validade, '
    ':inicio, :fim, :latitude, :longitude, :status, :criadoEm)',
    {
      'doadorId': doadorId,
      'titulo': titulo,
      'categoria': categoria.name,
      'quantidade': quantidade,
      'validade': Datas.dataParaSql(validade),
      'inicio': Datas.paraSql(inicio),
      'fim': Datas.paraSql(fim),
      'latitude': local.latitude,
      'longitude': local.longitude,
      'status': status.name,
      'criadoEm': Datas.paraSql(agora),
    },
  );
}

Future<void> _criarReserva(
  ExecutorSql banco, {
  required int doacaoId,
  required int ongId,
  required StatusReserva status,
  required DateTime reservadoEm,
  required DateTime expiraEm,
  DateTime? retiradoEm,
}) async {
  await banco.inserir(
    'INSERT INTO reservas '
    '(doacao_id, ong_id, status, reservado_em, expira_em, retirado_em) '
    'VALUES (:doacaoId, :ongId, :status, :reservadoEm, :expiraEm, :retiradoEm)',
    {
      'doacaoId': doacaoId,
      'ongId': ongId,
      'status': status.name,
      'reservadoEm': Datas.paraSql(reservadoEm),
      'expiraEm': Datas.paraSql(expiraEm),
      'retiradoEm': retiradoEm == null ? null : Datas.paraSql(retiradoEm),
    },
  );
}
