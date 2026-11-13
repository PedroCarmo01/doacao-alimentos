import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/core/notificacoes/mostrador_de_notificacoes.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/data/fotos/seletor_de_fotos.dart';
import 'package:summit_app/features/comunidade/comunidade_view_model.dart';
import 'package:summit_app/features/comunidade/nova_publicacao_view_model.dart';
import 'package:summit_app/features/perfil/editar_perfil_view_model.dart';
import 'package:summit_app/features/perfil/perfil_view_model.dart';

/// Etapa 7 — Comunidade (RN40–RN42), painel de impacto e Perfil (T50), no
/// modo Fake (as mesmas 4 publicações de exemplo do seed).
void main() {
  late RelogioFixo relogio;
  late Dependencias deps;

  setUp(() {
    relogio = RelogioFixo(DateTime.utc(2026, 9, 15, 15));
    deps = Dependencias.fake(
      banco: BancoFake(
        relogio: relogio,
        atrasoDeRede: Duration.zero,
        simularNovasDoacoes: false,
      ),
      seletorDeFotos: const SeletorDeFotosFake(),
      mostrador: MostradorEmMemoria(),
    );
  });

  Future<void> entrarComo(String email) async => deps.sessao.iniciar(
    await deps.auth.entrar(DadosLogin(email: email, senha: 'senha123')),
  );

  ComunidadeViewModel comunidade() =>
      ComunidadeViewModel(comunidade: deps.comunidade, sessao: deps.sessao);

  NovaPublicacaoViewModel novaPublicacao({int? doacao}) =>
      NovaPublicacaoViewModel(
        comunidade: deps.comunidade,
        doacoes: deps.doacoes,
        reservas: deps.reservas,
        seletor: deps.seletorDeFotos,
        sessao: deps.sessao,
        doacaoInicial: doacao,
      );

  /// O mercado confirma a retirada dos mantimentos com o código 4821: a
  /// doação fica concluída e pode ser ligada a uma publicação (RN40).
  Future<void> entregarMantimentos() async {
    await entrarComo('maosamigas@exemplo.com');
    final reserva = (await deps.reservas.listarMinhas(
      SituacaoDaLista.ativas,
    )).single;
    await entrarComo('mercado@exemplo.com');
    await deps.reservas.confirmar(reserva.id, '4821');
  }

  group('Comunidade (T40)', () {
    test(
      'painel de impacto e o feed do mais novo para o mais antigo',
      () async {
        await entrarComo('mercado@exemplo.com');
        final vm = comunidade();

        await vm.carregar();

        // As 2 publicações dos exemplos: 40 cestas e 80 cafés da manhã.
        expect(vm.impacto!.familiasAjudadas, 40);
        expect(vm.impacto!.refeicoes, 80);
        expect(vm.impacto!.doacoesConcluidas, 0);
        expect(
          [for (final p in vm.publicacoes) p.nomeAutor],
          ['ONG Mãos Amigas', 'Instituto Prato Cheio'],
        );
        expect(vm.publicacoes.first.fotos, ['assets/exemplos/paes.jpg']);
        expect(vm.publicacoes.every((p) => p.resumoDoacao == null), isTrue);
      },
    );

    test('RN41: apoiar soma na hora; tocar de novo desfaz', () async {
      await entrarComo('padaria@exemplo.com');
      final vm = comunidade();
      await vm.carregar();
      final doPratoCheio = vm.publicacoes.firstWhere(
        (p) => p.nomeAutor == 'Instituto Prato Cheio',
      );
      expect(doPratoCheio.apoios, 1); // o mercado já apoiou

      await vm.alternarApoio(doPratoCheio);
      final apoiada = vm.publicacoes.firstWhere((p) => p.id == doPratoCheio.id);
      expect(apoiada.apoios, 2);
      expect(apoiada.apoiadaPorMim, isTrue);

      await vm.alternarApoio(apoiada);
      expect(
        vm.publicacoes.firstWhere((p) => p.id == doPratoCheio.id).apoios,
        1,
      );
    });

    test('RN42: quem denuncia deixa de ver; o autor não tem a opção', () async {
      await entrarComo('maosamigas@exemplo.com');
      final vm = comunidade();
      await vm.carregar();
      final minha = vm.publicacoes.first; // a da Mãos Amigas (a mais nova)
      final outra = vm.publicacoes[1];

      expect(vm.ehMinha(minha), isTrue);
      expect(await vm.denunciar(outra, MotivoDenuncia.falso), isTrue);
      expect(vm.publicacoes.any((p) => p.id == outra.id), isFalse);
    });
  });

  group('Nova publicação (T41)', () {
    test('RN40: sem texto não publica', () async {
      await entrarComo('maosamigas@exemplo.com');
      final vm = novaPublicacao();

      expect(
        await vm.publicar(texto: '  ', familias: '', refeicoes: ''),
        isFalse,
      );
      expect(vm.erro, 'Escreva o texto da publicação.');
    });

    test('RN40: a ONG liga a uma retirada concluída, com foto, e o painel '
        'muda', () async {
      await entregarMantimentos();
      await entrarComo('maosamigas@exemplo.com');
      final antes = await deps.comunidade.impacto();
      final vm = novaPublicacao();
      await vm.carregarOpcoes();
      final mantimentos = vm.opcoes.single; // a única retirada concluída
      vm.escolherDoacao(mantimentos.doacaoId);
      await vm.adicionarFoto(daCamera: true);

      final publicou = await vm.publicar(
        texto: 'Mais 20 famílias atendidas!',
        familias: '20',
        refeicoes: '',
      );

      expect(publicou, isTrue);
      expect(vm.fotosQueFalharam, 0);
      final depois = await deps.comunidade.impacto();
      expect(depois.familiasAjudadas - antes.familiasAjudadas, 20);
      final feed = await deps.comunidade.feed();
      expect(feed.first.fotos, [SeletorDeFotosFake.foto.caminho]);
      expect(feed.first.resumoDoacao, startsWith('Mantimentos não perecíveis'));
    });

    test('sem retirada concluída, não há doação para ligar', () async {
      await entrarComo('maosamigas@exemplo.com');
      final vm = novaPublicacao();

      await vm.carregarOpcoes();

      expect(vm.opcoes, isEmpty);
    });

    test('o doador vê só as doações dele que foram entregues', () async {
      await entregarMantimentos(); // já entra como o mercado
      final vm = novaPublicacao();

      await vm.carregarOpcoes();

      expect(
        [for (final o in vm.opcoes) o.titulo],
        ['Mantimentos não perecíveis'],
      );
    });
  });

  group('Perfil (T50)', () {
    PerfilViewModel perfil() =>
        PerfilViewModel(sessao: deps.sessao, perfis: deps.perfis);

    test('estatísticas da ONG: retiradas e comparecimento', () async {
      await entrarComo('pratocheio@exemplo.com'); // 0 retiradas, 2 desistências
      final vm = perfil();

      await vm.carregarEstatisticas();

      expect(vm.estatisticas!.concluidas, 0);
      expect(vm.estatisticas!.comparecimento, 0);
      expect(vm.estatisticas!.desistenciasRecentes, 2);
    });

    test('estatísticas do doador: doações e kg', () async {
      await entregarMantimentos(); // já entra como o mercado
      final vm = perfil();

      await vm.carregarEstatisticas();

      expect(vm.estatisticas!.concluidas, 1);
      expect(vm.estatisticas!.kg, 120);
    });

    test('desligar um aviso fica salvo na conta', () async {
      await entrarComo('maosamigas@exemplo.com');
      final vm = perfil();

      await vm.mudarAvisos(const PreferenciasDeAviso(comunidade: false));

      expect(deps.sessao.perfil!.avisos.comunidade, isFalse);
      expect(vm.avisos.mensagens, isTrue);
    });

    test('a ONG troca o raio pelo Perfil', () async {
      await entrarComo('maosamigas@exemplo.com');
      final vm = perfil();

      await vm.mudarRaio(5);

      expect(deps.sessao.perfil!.raioKm, 5);
    });

    test('editar: telefone vazio é recusado; nome novo é salvo', () async {
      await entrarComo('mercado@exemplo.com');
      final vm = EditarPerfilViewModel(
        sessao: deps.sessao,
        perfis: deps.perfis,
        cep: deps.cep,
        localizacao: deps.localizacao,
      );
      final perfil = deps.sessao.perfil!;

      expect(
        await vm.salvar(
          nome: 'Ana',
          nomeOrganizacao: perfil.nomeOrganizacao,
          telefone: '',
          endereco: perfil.endereco ?? '',
          cep: perfil.cep ?? '',
          familias: '',
        ),
        isFalse,
      );
      expect(
        await vm.salvar(
          nome: 'Ana Souza',
          nomeOrganizacao: 'Mercado Bom Preço Centro',
          telefone: perfil.telefone!,
          endereco: perfil.endereco ?? '',
          cep: perfil.cep ?? '',
          familias: '',
        ),
        isTrue,
      );
      expect(deps.sessao.conta!.usuario.nome, 'Ana Souza');
      expect(deps.sessao.perfil!.nomeOrganizacao, 'Mercado Bom Preço Centro');
    });
  });
}
