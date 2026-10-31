import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import '../apoio/cenario_de_retirada.dart';

/// Quem recebe cada aviso da seção 9 (RN11 e os eventos da retirada).
/// No cenário, o doador e as duas ONGs ficam no mesmo ponto.
void main() {
  late CenarioDeRetirada c;

  setUp(() async => c = await CenarioDeRetirada.criar());

  List<TipoNotificacao> tipos(int usuarioId) => [
    for (final n in c.notificacoes.de(usuarioId)) n.tipo,
  ];

  group('RN11: doação nova', () {
    test('avisa as ONGs com a busca ativa dentro do raio', () async {
      await c.publicar();

      expect(tipos(c.ongA.id), [TipoNotificacao.doacaoNova]);
      expect(tipos(c.ongB.id), [TipoNotificacao.doacaoNova]);
      expect(
        c.notificacoes.de(c.ongA.id).single.corpo,
        contains('Retirar até'),
      );
    });

    test('não avisa quem desligou a busca ativa', () async {
      c.contas.alterarPerfil(c.ongB.id, {'buscaAtiva': false});

      final resposta = await c.doacaoService.publicar(
        c.doador,
        _dados(c.agora),
      );

      expect(resposta.ongsAvisadas, 1);
      expect(tipos(c.ongB.id), isEmpty);
    });

    test('não avisa a ONG fora do raio dela', () async {
      // São Paulo, ~45 km de Mogi: fora do raio de 10 km.
      c.contas.alterarPerfil(c.ongB.id, {
        'latitude': -23.5505,
        'longitude': -46.6333,
      });

      await c.publicar();

      expect(tipos(c.ongB.id), isEmpty);
    });

    test('não avisa a ONG suspensa', () async {
      c.contas.suspender(c.ongB.id, c.agora.add(const Duration(hours: 1)));

      await c.publicar();

      expect(tipos(c.ongB.id), isEmpty);
    });
  });

  group('retirada', () {
    test('aceitar avisa o doador', () async {
      final doacao = await c.publicar();
      await c.service.aceitar(c.ongA, doacao.id);

      expect(tipos(c.doador.id), [TipoNotificacao.doacaoAceita]);
      expect(
        c.notificacoes.de(c.doador.id).single.corpo,
        contains('vai retirar'),
      );
    });

    test('faltando 10 min, a ONG é lembrada uma vez só', () async {
      final doacao = await c.publicar();
      await c.service.aceitar(c.ongA, doacao.id);
      c.avancar(const Duration(minutes: 51)); // faltam 9 min

      await c.service.avisarPrazosAcabando();
      await c.service.avisarPrazosAcabando(); // a próxima rodada do job

      final lembretes = tipos(
        c.ongA.id,
      ).where((t) => t == TipoNotificacao.prazoAcabando);
      expect(lembretes, hasLength(1));
    });

    test('RN22: o prazo acabando avisa os dois e a doação volta para a '
        'outra ONG', () async {
      final doacao = await c.publicar();
      await c.service.aceitar(c.ongA, doacao.id);
      c.avancar(const Duration(minutes: 61));

      await c.service.expirarVencidas();

      expect(tipos(c.ongA.id), contains(TipoNotificacao.prazoAcabouOng));
      expect(tipos(c.doador.id), contains(TipoNotificacao.prazoAcabouDoador));
      expect(
        tipos(c.ongB.id),
        contains(TipoNotificacao.doacaoDisponivelDeNovo),
      );
      // A ONG bloqueada não é avisada de que a doação voltou.
      expect(
        tipos(c.ongA.id),
        isNot(contains(TipoNotificacao.doacaoDisponivelDeNovo)),
      );
    });

    test('RN27: retirada confirmada avisa os dois', () async {
      final doacao = await c.publicar();
      final reserva = await c.service.aceitar(c.ongA, doacao.id);

      await c.confirmacao.confirmar(
        c.doador,
        reserva.id,
        CenarioDeRetirada.codigo,
      );

      expect(tipos(c.doador.id), contains(TipoNotificacao.retiradaConfirmada));
      expect(tipos(c.ongA.id), contains(TipoNotificacao.retiradaConfirmada));
    });

    test('RN12: cancelar uma reservada avisa a ONG com o motivo', () async {
      final doacao = await c.publicar();
      await c.service.aceitar(c.ongA, doacao.id);

      await c.doacaoService.cancelar(c.doador, doacao.id, motivo: 'Estragou');

      final aviso = c.notificacoes
          .de(c.ongA.id)
          .firstWhere((n) => n.tipo == TipoNotificacao.doacaoCancelada);
      expect(aviso.corpo, contains('Motivo: Estragou'));
    });

    test('RN24: a suspensão gera um aviso para a ONG', () async {
      for (var i = 0; i < 3; i++) {
        final reserva = await c.service.aceitar(
          c.ongA,
          (await c.publicar()).id,
        );
        c.avancar(const Duration(minutes: 10));
        await c.service.desistir(c.ongA, reserva.id);
      }

      expect(tipos(c.ongA.id), contains(TipoNotificacao.suspensao));
    });
  });

  test('cada um busca só as próprias, depois do último id', () async {
    await c.publicar();
    await c.publicar();
    final todas = c.notificacoes.de(c.ongA.id);

    final novas = await c.notificacoes.depoisDe(
      c.ongA.id,
      todas.first.id,
      limite: 50,
    );

    expect(novas, [todas.last]);
  });
}

DadosNovaDoacao _dados(DateTime agora) => DadosNovaDoacao(
  titulo: 'Pães do dia',
  categoria: CategoriaAlimento.padaria,
  quantidade: 30,
  unidade: Unidade.unidades,
  pesoKg: 6,
  conservacao: Conservacao.ambiente,
  validade: DateTime.utc(2026, 9, 16),
  janelaInicio: agora,
  janelaFim: agora.add(const Duration(hours: 3)),
  declaracaoAlimentosProprios: true,
);
