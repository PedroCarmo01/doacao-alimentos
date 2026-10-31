import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:test/test.dart';

import '../apoio/cenario_de_retirada.dart';

/// A Comunidade (RN40–RN42), o painel de impacto, as estatísticas e as
/// preferências de aviso do Perfil (T50).
void main() {
  late CenarioDeRetirada c;

  setUp(() async => c = await CenarioDeRetirada.criar());

  /// O doador publica, a ONG A retira e o doador confirma o código.
  Future<Doacao> doacaoConcluida() async {
    final doacao = await c.publicar();
    final reserva = await c.service.aceitar(c.ongA, doacao.id);
    await c.confirmacao.confirmar(
      c.doador,
      reserva.id,
      CenarioDeRetirada.codigo,
    );
    return c.doacao(doacao.id);
  }

  group('publicar (RN40)', () {
    test('RN40: a ONG publica sobre uma doação concluída', () async {
      final doacao = await doacaoConcluida();

      final publicacao = await c.comunidade.publicar(
        c.ongA,
        DadosPublicacao(
          texto: 'Fizemos 40 marmitas com os pães!',
          doacaoId: doacao.id,
          familiasAjudadas: 12,
          refeicoes: 40,
        ),
      );

      expect(publicacao.nomeAutor, 'Org a@ex.com');
      expect(publicacao.doacaoId, doacao.id);
      final feed = await c.comunidade.feed(c.doador, 0);
      expect(feed.single.texto, 'Fizemos 40 marmitas com os pães!');
    });

    test('RN40: texto vazio é recusado', () {
      expect(
        () => c.comunidade.publicar(c.ongA, const DadosPublicacao(texto: ' ')),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('RN40: só liga a uma doação concluída da qual participou', () async {
      final doacao = await doacaoConcluida();
      final aberta = await c.publicar();

      expect(
        () => c.comunidade.publicar(
          c.ongB, // não retirou esta doação
          DadosPublicacao(texto: 'Oi', doacaoId: doacao.id),
        ),
        throwsA(isA<ValidacaoException>()),
      );
      expect(
        () => c.comunidade.publicar(
          c.doador,
          DadosPublicacao(texto: 'Oi', doacaoId: aberta.id),
        ),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('RN40: até 3 fotos, só o autor', () async {
      final p = await c.comunidade.publicar(
        c.ongA,
        const DadosPublicacao(texto: 'Fotos'),
      );
      const jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3];
      for (var i = 0; i < 3; i++) {
        await c.comunidade.adicionarFoto(c.ongA, p.id, jpeg);
      }

      expect(
        () => c.comunidade.adicionarFoto(c.ongA, p.id, jpeg),
        throwsA(isA<ConflitoException>()),
      );
      expect(
        () => c.comunidade.adicionarFoto(c.ongB, p.id, jpeg),
        throwsA(isA<NaoEncontradoException>()),
      );
    });
  });

  group('apoiar (RN41)', () {
    test('RN41: cada conta apoia uma vez e o autor é avisado', () async {
      final p = await c.comunidade.publicar(
        c.ongA,
        const DadosPublicacao(texto: 'Obrigado!'),
      );

      await c.comunidade.apoiar(c.doador, p.id);
      final depois = await c.comunidade.apoiar(c.doador, p.id); // de novo

      expect(depois.apoios, 1);
      expect(depois.apoiadaPorMim, isTrue);
      final avisos = c.notificacoes.de(c.ongA.id);
      expect(
        avisos.where((n) => n.tipo == TipoNotificacao.apoioNovo),
        hasLength(1),
      );
    });

    test('RN41: desfazer o apoio', () async {
      final p = await c.comunidade.publicar(
        c.ongA,
        const DadosPublicacao(texto: 'Obrigado!'),
      );
      await c.comunidade.apoiar(c.doador, p.id);

      final depois = await c.comunidade.desfazerApoio(c.doador, p.id);

      expect(depois.apoios, 0);
    });
  });

  group('denunciar (RN42)', () {
    test('RN42: 3 contas diferentes escondem a publicação', () async {
      final p = await c.comunidade.publicar(
        c.ongA,
        const DadosPublicacao(texto: 'Promoção imperdível!'),
      );
      final terceira = await c.outraOng('c@ex.com');

      await c.comunidade.denunciar(c.doador, p.id, MotivoDenuncia.falso);
      await c.comunidade.denunciar(c.doador, p.id, MotivoDenuncia.falso);
      await c.comunidade.denunciar(c.ongB, p.id, MotivoDenuncia.improprio);
      expect(await c.comunidade.feed(c.doador, 0), hasLength(1)); // 2 contas

      await c.comunidade.denunciar(terceira, p.id, MotivoDenuncia.outro);

      expect(await c.comunidade.feed(c.doador, 0), isEmpty);
      expect(
        () => c.comunidade.apoiar(c.doador, p.id),
        throwsA(isA<NaoEncontradoException>()),
      );
    });

    test('RN42: o autor não denuncia a própria publicação', () async {
      final p = await c.comunidade.publicar(
        c.ongA,
        const DadosPublicacao(texto: 'Minha'),
      );
      expect(
        () => c.comunidade.denunciar(c.ongA, p.id, MotivoDenuncia.outro),
        throwsA(isA<ValidacaoException>()),
      );
    });
  });

  test('painel de impacto: kg, doações e famílias mudam', () async {
    final antes = await c.comunidade.impacto();
    final doacao = await doacaoConcluida(); // 6 kg
    await c.comunidade.publicar(
      c.ongA,
      DadosPublicacao(texto: 'Ok', doacaoId: doacao.id, familiasAjudadas: 12),
    );

    final depois = await c.comunidade.impacto();

    expect(depois.kgSalvos - antes.kgSalvos, 6);
    expect(depois.doacoesConcluidas - antes.doacoesConcluidas, 1);
    expect(depois.familiasAjudadas, 12);
  });

  test(
    'o feed vem em páginas de 20, da mais nova para a mais antiga',
    () async {
      for (var i = 1; i <= 25; i++) {
        await c.comunidade.publicar(c.ongA, DadosPublicacao(texto: 'Nº $i'));
      }

      final primeira = await c.comunidade.feed(c.doador, 0);
      final segunda = await c.comunidade.feed(c.doador, primeira.last.id);

      expect(primeira, hasLength(20));
      expect(primeira.first.texto, 'Nº 25');
      expect(segunda, hasLength(5));
      expect(segunda.last.texto, 'Nº 1');
    },
  );

  group('Perfil (T50)', () {
    test('estatísticas do doador e da ONG', () async {
      await doacaoConcluida();
      final retirada = await c.service.aceitar(c.ongA, (await c.publicar()).id);
      c.avancar(const Duration(minutes: 10));
      await c.service.desistir(c.ongA, retirada.id); // 1 desistência

      final doDoador = await c.perfil.estatisticas(c.doador);
      final daOng = await c.perfil.estatisticas(c.ongA);

      expect(doDoador.concluidas, 1);
      expect(doDoador.kg, 6);
      expect(daOng.concluidas, 1);
      expect(daOng.comparecimento, 0.5); // 1 retirada, 1 desistência
      expect(daOng.desistenciasRecentes, 1);
    });

    test('quem desliga "mensagens" não recebe o aviso do chat', () async {
      final reserva = await c.service.aceitar(c.ongA, (await c.publicar()).id);
      await c.perfil.atualizarAvisos(
        c.doador,
        const PreferenciasDeAviso(mensagens: false),
      );

      await c.chat.enviar(c.ongA, reserva.id, 'Estou a caminho');

      expect(
        c.notificacoes
            .de(c.doador.id)
            .where((n) => n.tipo == TipoNotificacao.mensagemNova),
        isEmpty,
      );
    });

    test('RN11: quem desliga "doações" não é avisado de doação nova', () async {
      await c.perfil.atualizarAvisos(
        c.ongB,
        const PreferenciasDeAviso(doacoes: false),
      );

      final resposta = await c.doacaoService.publicar(
        c.doador,
        DadosNovaDoacao(
          titulo: 'Pães',
          categoria: CategoriaAlimento.padaria,
          quantidade: 1,
          unidade: Unidade.unidades,
          pesoKg: 1,
          conservacao: Conservacao.ambiente,
          validade: DateTime.utc(2026, 9, 16),
          janelaInicio: c.agora,
          janelaFim: c.agora.add(const Duration(hours: 2)),
          declaracaoAlimentosProprios: true,
        ),
      );

      expect(resposta.ongsAvisadas, 1); // só a ONG A
    });
  });
}
