import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/notificacoes/mostrador_de_notificacoes.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/core/utils/rota_no_mapa.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/features/mapa/mapa_view_model.dart';
import 'package:summit_app/features/ong/detalhe_doacao_ong_view_model.dart';
import 'package:summit_app/features/ong/home_ong_view_model.dart';

/// Etapa 3 — a ONG encontra doações: lista, raio, busca ativa, NOVA, mapa e
/// detalhe. Tudo no modo Fake, que usa os mesmos lugares do seed.
void main() {
  late RelogioFixo relogio;
  late Dependencias deps;

  setUp(() {
    relogio = RelogioFixo(DateTime.utc(2026, 9, 15, 15));
    deps = Dependencias.fake(
      mostrador: MostradorEmMemoria(),
      banco: BancoFake(
        relogio: relogio,
        atrasoDeRede: Duration.zero,
        simularNovasDoacoes: false,
      ),
    );
  });

  Future<void> entrarComo(String email) async => deps.sessao.iniciar(
    await deps.auth.entrar(DadosLogin(email: email, senha: 'senha123')),
  );

  HomeOngViewModel inicio() => HomeOngViewModel(
    doacoes: deps.doacoes,
    perfis: deps.perfis,
    sessao: deps.sessao,
    relogio: relogio,
  );

  group('HomeOngViewModel', () {
    test(
      'RN11: a ONG vê as do raio, da mais perto para a mais longe',
      () async {
        await entrarComo('maosamigas@exemplo.com');
        final vm = inicio();

        await vm.carregar();

        expect(vm.doacoes, hasLength(5)); // as 5 disponíveis de Mogi
        final distancias = [for (final d in vm.doacoes) d.distanciaKm!];
        expect(distancias, orderedEquals([...distancias]..sort()));
        expect(distancias.last, lessThan(10));
      },
    );

    test('a ONG a 45 km não vê nada (fora do raio)', () async {
      await entrarComo('distante@exemplo.com');
      final vm = inicio();

      await vm.carregar();

      expect(vm.doacoes, isEmpty);
    });

    test('raio menor mostra menos doações e fica salvo no perfil', () async {
      await entrarComo('pratocheio@exemplo.com'); // ~3 km do centro
      final vm = inicio();
      await vm.carregar();
      final noRaioDe10 = vm.doacoes.length;

      await vm.mudarRaio(2);

      expect(vm.doacoes.length, lessThan(noRaioDe10));
      expect(deps.sessao.perfil!.raioKm, 2);
    });

    test('desligar a busca ativa fica salvo e a lista continua', () async {
      await entrarComo('maosamigas@exemplo.com');
      final vm = inicio();
      await vm.carregar();

      expect(await vm.mudarBuscaAtiva(false), isTrue);

      expect(vm.buscaAtiva, isFalse);
      expect(deps.sessao.perfil!.buscaAtiva, isFalse);
      expect(vm.doacoes, isNotEmpty);
    });

    test('NOVA: só o que apareceu depois da última vez', () async {
      relogio.avancar(const Duration(hours: 2)); // exemplos ficam "velhos"
      await entrarComo('maosamigas@exemplo.com');
      final vm = inicio();
      await vm.carregar();
      expect(vm.doacoes.where(vm.ehNova), isEmpty);

      // O mercado publica uma doação nova...
      await entrarComo('mercado@exemplo.com');
      await deps.doacoes.publicar(
        DadosNovaDoacao(
          titulo: 'Bananas',
          categoria: CategoriaAlimento.hortifruti,
          quantidade: 2,
          unidade: Unidade.caixas,
          pesoKg: 10,
          conservacao: Conservacao.ambiente,
          validade: DateTime.utc(2026, 9, 15),
          janelaInicio: relogio.agora(),
          janelaFim: relogio.agora().add(const Duration(hours: 2)),
          declaracaoAlimentosProprios: true,
        ),
      );
      // ...e a lista da ONG se atualiza sozinha.
      await entrarComo('maosamigas@exemplo.com');
      await vm.atualizarEmSilencio();

      final novas = vm.doacoes.where(vm.ehNova).toList();
      expect([for (final d in novas) d.titulo], ['Bananas']);
    });

    test('RN24: ONG suspensa vê a faixa (e a lista)', () async {
      await entrarComo('suspensa@exemplo.com');
      final vm = inicio();

      await vm.carregar();

      expect(vm.suspensaAte, isNotNull);
      expect(vm.doacoes, isNotEmpty);
    });
  });

  test('MapaViewModel: centro na ONG, raio do perfil e as doações', () async {
    await entrarComo('maosamigas@exemplo.com');
    final vm = MapaViewModel(doacoes: deps.doacoes, sessao: deps.sessao);

    await vm.carregar();
    vm.selecionar(vm.doacoes.first);

    expect(vm.centro, deps.sessao.perfil!.coordenadas);
    expect(vm.raioKm, 10);
    expect(vm.zoomInicial, 12);
    expect(vm.selecionada, isNotNull);
  });

  test('DetalheDoacaoOngViewModel: dados do doador e distância', () async {
    await entrarComo('maosamigas@exemplo.com');
    final lista = await deps.doacoes.listarProximas();
    final frutas = lista.firstWhere((d) => d.titulo.startsWith('Frutas'));
    final vm = DetalheDoacaoOngViewModel(
      doacoes: deps.doacoes,
      reservas: deps.reservas,
      sessao: deps.sessao,
      relogio: relogio,
      doacaoId: frutas.id,
    );

    await vm.carregar();

    expect(vm.detalhe!.doador!.nomeOrganizacao, 'Mercado Bom Preço');
    expect(vm.detalhe!.doador!.verificacao, Verificacao.verificada);
    expect(vm.distanciaKm, closeTo(frutas.distanciaKm!, 0.01));
    expect(vm.suspensa, isFalse);
  });

  test('Como chegar: abre a rota do Google Maps até a doação', () {
    final uri = RotaNoMapa.para(const Coordenadas(-23.5229, -46.188));

    expect(
      uri.toString(),
      'https://www.google.com/maps/dir/?api=1&destination=-23.5229%2C-46.188',
    );
  });
}
