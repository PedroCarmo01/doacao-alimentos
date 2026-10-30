import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/proximidade/area_de_busca.dart';
import 'package:summit_backend/proximidade/proximidade_repository.dart';
import 'package:summit_backend/proximidade/proximidade_service.dart';
import 'package:test/test.dart';

import '../apoio/em_memoria.dart';

/// `GET /proximas`: raio, ordem pela distância e bloqueios (RN11 filtro,
/// RN22). Os lugares são de Mogi das Cruzes, como no seed.
void main() {
  final agora = DateTime.utc(2026, 9, 15, 15);
  const centroDaOng = Coordenadas(-23.5180, -46.1850); // Mãos Amigas

  late ContasEmMemoria contas;
  late _DoacoesNaArea doacoes;
  late ProximidadeService service;
  late UsuarioAutenticado ong;

  Doacao doacao(int id, Coordenadas local, {bool janelaAberta = true}) =>
      Doacao(
        id: id,
        doadorId: 99,
        titulo: 'Doação $id',
        categoria: CategoriaAlimento.padaria,
        quantidade: 1,
        unidade: Unidade.caixas,
        pesoKg: 1,
        conservacao: Conservacao.ambiente,
        validade: agora,
        janelaInicio: agora.subtract(const Duration(hours: 1)),
        janelaFim: janelaAberta
            ? agora.add(const Duration(hours: 3))
            : agora.subtract(const Duration(minutes: 1)),
        latitude: local.latitude,
        longitude: local.longitude,
        status: StatusDoacao.disponivel,
        criadoEm: agora,
      );

  setUp(() async {
    contas = ContasEmMemoria();
    final conta = await contas.criar(
      DadosCadastro(
        tipo: TipoUsuario.ong,
        nome: 'Coordenação',
        email: 'ong@ex.com',
        senha: 'senha123',
        nomeOrganizacao: 'ONG',
        documento: '1',
        latitude: centroDaOng.latitude,
        longitude: centroDaOng.longitude,
        aceitouTermos: true,
      ),
      senhaHash: 'x',
      criadoEm: agora,
      verificacao: Verificacao.verificada,
    );
    ong = UsuarioAutenticado(id: conta.usuario.id, tipo: TipoUsuario.ong);
    doacoes = _DoacoesNaArea([
      doacao(1, const Coordenadas(-23.5262, -46.1932)), // padaria, ~1,2 km
      doacao(2, const Coordenadas(-23.5229, -46.1880)), // mercado, ~0,6 km
      doacao(3, const Coordenadas(-23.5505, -46.6333)), // São Paulo, ~45 km
      doacao(4, const Coordenadas(-23.5400, -46.2100)), // ~3,6 km
    ]);
    service = ProximidadeService(
      proximidade: doacoes,
      usuarios: contas,
      relogio: RelogioFixo(agora),
    );
  });

  test('RN11: só as do raio, da mais perto para a mais longe', () async {
    final lista = await service.proximas(ong); // raio do perfil: 10 km

    expect([for (final d in lista) d.id], [2, 1, 4]);
    expect(lista.first.distanciaKm, closeTo(0.6, 0.1));
  });

  test('RN11: raio menor deixa só as mais próximas', () async {
    final lista = await service.proximas(ong, raioKm: 2);

    expect([for (final d in lista) d.id], [2, 1]);
  });

  test('a doação a 45 km não aparece no raio de 10 km', () async {
    final lista = await service.proximas(ong);

    expect(lista.any((d) => d.id == 3), isFalse);
  });

  test('RN22: doação bloqueada para a ONG não aparece', () async {
    doacoes.bloqueadas.add(2);

    final lista = await service.proximas(ong);

    expect(lista.any((d) => d.id == 2), isFalse);
  });

  test('horário de retirada encerrado não aparece', () async {
    doacoes.todas.add(
      doacao(5, const Coordenadas(-23.5229, -46.1880), janelaAberta: false),
    );

    final lista = await service.proximas(ong);

    expect(lista.any((d) => d.id == 5), isFalse);
  });

  test('só ONG busca doações próximas', () {
    const doador = UsuarioAutenticado(id: 7, tipo: TipoUsuario.doador);

    expect(
      () => service.proximas(doador),
      throwsA(isA<SemPermissaoException>()),
    );
  });

  test('AreaDeBusca de 10 km contém o centro e não São Paulo', () {
    final area = AreaDeBusca.aoRedor(centroDaOng, 10);

    expect(area.contem(centroDaOng), isTrue);
    expect(area.contem(const Coordenadas(-23.5505, -46.6333)), isFalse);
  });
}

/// Repositório em memória que imita o filtro do SQL: retângulo, janela
/// aberta e sem bloqueio (RN22).
class _DoacoesNaArea implements ProximidadeRepository {
  _DoacoesNaArea(this.todas);

  final List<Doacao> todas;
  final Set<int> bloqueadas = {};

  @override
  Future<List<Doacao>> disponiveisNaArea(
    AreaDeBusca area, {
    required int ongId,
    required DateTime agora,
  }) async => [
    for (final d in todas)
      if (area.contem(d.coordenadas) &&
          d.janelaFim.isAfter(agora) &&
          !bloqueadas.contains(d.id))
        d,
  ];
}
