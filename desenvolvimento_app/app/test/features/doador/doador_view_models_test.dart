import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/notificacoes/mostrador_de_notificacoes.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/data/fotos/seletor_de_fotos.dart';
import 'package:summit_app/features/doador/detalhe_doacao_doador_view_model.dart';
import 'package:summit_app/features/doador/home_doador_view_model.dart';
import 'package:summit_app/features/doador/nova_doacao_view_model.dart';

/// Etapa 2 — doador: publicar com fotos, minhas doações, editar e cancelar.
/// Tudo no modo Fake, que segue as mesmas regras do backend.
void main() {
  // 15/09/2026 15:00 UTC = 12:00 em Brasília (mesmo dia nos dois fusos).
  late RelogioFixo relogio;
  late Dependencias deps;

  setUp(() async {
    relogio = RelogioFixo(DateTime.utc(2026, 9, 15, 15));
    deps = Dependencias.fake(
      mostrador: MostradorEmMemoria(),
      banco: BancoFake(
        relogio: relogio,
        atrasoDeRede: Duration.zero,
        simularNovasDoacoes: false,
      ),
      seletorDeFotos: const SeletorDeFotosFake(),
    );
    final resposta = await deps.auth.entrar(
      const DadosLogin(email: 'mercado@exemplo.com', senha: 'senha123'),
    );
    await deps.sessao.iniciar(resposta);
  });

  NovaDoacaoViewModel novaDoacao({int? doacaoId}) => NovaDoacaoViewModel(
    doacoes: deps.doacoes,
    seletor: deps.seletorDeFotos,
    relogio: relogio,
    doacaoId: doacaoId,
  );

  const campos = CamposDaDoacao(
    titulo: 'Pães do dia',
    quantidade: '30',
    pesoKg: '6,5',
  );

  group('NovaDoacaoViewModel', () {
    test('RN10: publica com 2 fotos e mostra a tela de sucesso', () async {
      final vm = novaDoacao()..marcarDeclaracao(true);
      await vm.adicionarFoto(daCamera: true);
      await vm.adicionarFoto(daCamera: false);

      final salvou = await vm.salvar(campos);

      expect(salvou, isTrue, reason: vm.erro);
      expect(vm.resultado!.fotos, hasLength(2));
      expect(vm.resultado!.pesoKg, 6.5);
      expect(vm.resultado!.endereco, 'Rua Principal, 100 - Centro');
      expect(vm.fotosQueFalharam, 0);
    });

    test('RN10: validade de ontem é recusada', () async {
      final vm = novaDoacao()
        ..marcarDeclaracao(true)
        ..escolherValidade(DateTime.utc(2026, 9, 14));

      expect(await vm.salvar(campos), isFalse);
      expect(vm.erro, 'Não é permitido doar alimentos vencidos.');
    });

    test('RN10: sem a declaração não publica', () async {
      expect(await novaDoacao().salvar(campos), isFalse);
    });

    test('no máximo 3 fotos', () async {
      final vm = novaDoacao();
      for (var i = 0; i < 3; i++) {
        await vm.adicionarFoto(daCamera: true);
      }

      expect(vm.podeAdicionarFoto, isFalse);
      expect(await vm.adicionarFoto(daCamera: true), isFalse);
    });

    test('refeição pronta: retirada até 4 h depois do preparo', () async {
      final vm = novaDoacao()
        ..marcarDeclaracao(true)
        ..escolherCategoria(CategoriaAlimento.refeicoesProntas)
        ..escolherPreparo(relogio.agora().subtract(const Duration(hours: 1)));
      // Fim padrão = agora + 4 h = 5 h depois do preparo: passa do limite.

      expect(await vm.salvar(campos), isFalse);
      expect(vm.erro, startsWith('Refeições prontas devem'));
    });

    test('RN12: edita uma doação disponível', () async {
      final publicada = await deps.doacoes.publicar(
        DadosNovaDoacao(
          titulo: 'Pães',
          categoria: CategoriaAlimento.padaria,
          quantidade: 10,
          unidade: Unidade.unidades,
          pesoKg: 2,
          conservacao: Conservacao.ambiente,
          validade: DateTime.utc(2026, 9, 15),
          janelaInicio: relogio.agora(),
          janelaFim: relogio.agora().add(const Duration(hours: 2)),
          declaracaoAlimentosProprios: true,
        ),
      );
      final vm = novaDoacao(doacaoId: publicada.doacao.id);
      await vm.carregarParaEditar();

      final salvou = await vm.salvar(campos);

      expect(salvou, isTrue, reason: vm.erro);
      expect(vm.resultado!.titulo, 'Pães do dia');
    });
  });

  group('HomeDoadorViewModel', () {
    test('separa Ativas e Histórico e soma os kg das concluídas', () async {
      final vm = HomeDoadorViewModel(
        doacoes: deps.doacoes,
        sessao: deps.sessao,
        relogio: relogio,
      );

      await vm.carregar();

      // Dados de exemplo do mercado: só os mantimentos (reservados pela
      // Mãos Amigas). Ainda não há nada no histórico.
      expect(
        [for (final d in vm.ativas) d.titulo],
        ['Mantimentos não perecíveis'],
      );
      expect(vm.ativas.single.status, StatusDoacao.reservada);
      expect(vm.historico, isEmpty);
      expect(vm.totalConcluidas, 0);
      expect(vm.kgSalvos, 0);
      expect(vm.nomeOrganizacao, 'Mercado Bom Preço');
    });

    test('RN13: horário de retirada encerrado vai para o histórico', () async {
      final vm = HomeDoadorViewModel(
        doacoes: deps.doacoes,
        sessao: deps.sessao,
        relogio: relogio,
      );
      relogio.avancar(const Duration(hours: 9)); // todas as janelas acabam

      await vm.carregar();

      // Os mantimentos: o prazo da retirada venceu, a doação voltou e
      // depois o horário dela acabou.
      expect(vm.ativas, isEmpty);
      expect(
        [for (final d in vm.historico) (d.titulo, d.status)],
        [('Mantimentos não perecíveis', StatusDoacao.expirada)],
      );
    });
  });

  group('DetalheDoacaoDoadorViewModel', () {
    Future<Doacao> doacaoComTitulo(String titulo) async {
      final ativas = await deps.doacoes.listarMinhas(SituacaoDaLista.ativas);
      return ativas.firstWhere((d) => d.titulo == titulo);
    }

    test('RN12: cancela uma disponível sem motivo', () async {
      // O pão francês (disponível) é da padaria.
      await deps.sessao.iniciar(
        await deps.auth.entrar(
          const DadosLogin(email: 'padaria@exemplo.com', senha: 'senha123'),
        ),
      );
      final paes = await doacaoComTitulo('Pão francês do dia');
      final vm = DetalheDoacaoDoadorViewModel(
        doacoes: deps.doacoes,
        reservas: deps.reservas,
        relogio: relogio,
        doacaoId: paes.id,
      );

      expect(await vm.cancelar(), isTrue);
      expect(vm.doacao!.status, StatusDoacao.cancelada);
      expect(vm.mudou, isTrue);
    });

    test('RN12: reservada pede motivo e mostra a ONG', () async {
      final mantimentos = await doacaoComTitulo('Mantimentos não perecíveis');
      final vm = DetalheDoacaoDoadorViewModel(
        doacoes: deps.doacoes,
        reservas: deps.reservas,
        relogio: relogio,
        doacaoId: mantimentos.id,
      );
      await vm.carregar();
      expect(vm.detalhe!.ong?.nomeOrganizacao, 'ONG Mãos Amigas');

      expect(await vm.cancelar(), isFalse);
      expect(vm.erro, 'Conte à ONG o motivo do cancelamento.');

      expect(await vm.cancelar(motivo: 'A geladeira quebrou'), isTrue);
      expect(vm.doacao!.motivoCancelamento, 'A geladeira quebrou');
    });
  });
}
