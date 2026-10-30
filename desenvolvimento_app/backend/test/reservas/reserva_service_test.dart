import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:test/test.dart';

import '../apoio/cenario_de_retirada.dart';

/// Aceite, desistência, expiração e suspensão (RN20–RN26, RN29), com o
/// relógio controlado pelo teste.
void main() {
  late CenarioDeRetirada c;

  setUp(() async => c = await CenarioDeRetirada.criar());

  Matcher conflito(String codigo) => throwsA(
    isA<ConflitoException>().having((e) => e.codigo, 'codigo', codigo),
  );

  group('aceitar', () {
    test('RN20: a primeira ONG fica com a doação; a segunda não', () async {
      final doacao = await c.publicar();

      final reserva = await c.service.aceitar(c.ongA, doacao.id);

      expect(reserva.estaAtiva, isTrue);
      expect((await c.doacao(doacao.id)).status, StatusDoacao.reservada);
      expect(
        () => c.service.aceitar(c.ongB, doacao.id),
        conflito('DOACAO_INDISPONIVEL'),
      );
    });

    test('RN20: doador não aceita', () async {
      final doacao = await c.publicar();
      expect(
        () => c.service.aceitar(c.doador, doacao.id),
        throwsA(isA<SemPermissaoException>()),
      );
    });

    test('RN21: prazo de 60 min a partir do aceite', () async {
      final doacao = await c.publicar();
      final reserva = await c.service.aceitar(c.ongA, doacao.id);
      expect(reserva.expiraEm, c.agora.add(const Duration(minutes: 60)));
    });

    test('RN21: o prazo não passa do fim do horário de retirada', () async {
      final doacao = await c.publicar(janela: const Duration(minutes: 20));
      final reserva = await c.service.aceitar(c.ongA, doacao.id);
      expect(reserva.expiraEm, doacao.janelaFim);
    });

    test('RN26: gera o código de 4 dígitos para a ONG', () async {
      final doacao = await c.publicar();
      final reserva = await c.service.aceitar(c.ongA, doacao.id);
      expect(reserva.codigoRetirada, CenarioDeRetirada.codigo);
    });

    test('RN26: o doador vê a retirada no detalhe, mas sem o código', () async {
      final doacao = await c.publicar();
      await c.service.aceitar(c.ongA, doacao.id);

      final paraDoador = await c.doacaoService.detalhar(c.doador, doacao.id);
      final paraOng = await c.doacaoService.detalhar(c.ongA, doacao.id);

      expect(paraDoador.reserva!.codigoRetirada, isNull);
      expect(paraOng.reserva!.codigoRetirada, CenarioDeRetirada.codigo);
    });

    test('RN25: no máximo 2 retiradas em andamento', () async {
      for (var i = 0; i < 2; i++) {
        await c.service.aceitar(c.ongA, (await c.publicar()).id);
      }
      final terceira = await c.publicar();
      expect(
        () => c.service.aceitar(c.ongA, terceira.id),
        conflito('LIMITE_DE_RETIRADAS'),
      );
    });

    test('RN24: ONG suspensa não aceita', () async {
      c.contas.suspender(c.ongA.id, c.agora.add(const Duration(hours: 1)));
      final doacao = await c.publicar();
      expect(
        () => c.service.aceitar(c.ongA, doacao.id),
        conflito('ONG_SUSPENSA'),
      );
    });
  });

  group('desistir', () {
    test('RN23: até 5 min não conta nem bloqueia', () async {
      final doacao = await c.publicar();
      final reserva = await c.service.aceitar(c.ongA, doacao.id);
      c.avancar(const Duration(minutes: 4));

      final resposta = await c.service.desistir(c.ongA, reserva.id);

      expect(resposta.contouDesistencia, isFalse);
      expect((await c.doacao(doacao.id)).status, StatusDoacao.disponivel);
      // Pode aceitar a mesma doação de novo.
      expect((await c.service.aceitar(c.ongA, doacao.id)).estaAtiva, isTrue);
    });

    test('RN22: depois da tolerância conta, a doação volta e a ONG fica '
        'bloqueada para ela', () async {
      final doacao = await c.publicar();
      final reserva = await c.service.aceitar(c.ongA, doacao.id);
      c.avancar(const Duration(minutes: 6));

      final resposta = await c.service.desistir(c.ongA, reserva.id);

      expect(resposta.contouDesistencia, isTrue);
      expect(resposta.desistenciasRecentes, 1);
      expect((await c.doacao(doacao.id)).status, StatusDoacao.disponivel);
      expect(
        () => c.service.aceitar(c.ongA, doacao.id),
        conflito('ONG_BLOQUEADA_NESTA_DOACAO'),
      );
      // Outra ONG pode aceitar.
      expect((await c.service.aceitar(c.ongB, doacao.id)).estaAtiva, isTrue);
    });

    test('RN22: só a ONG dona desiste', () async {
      final reserva = await c.service.aceitar(c.ongA, (await c.publicar()).id);
      expect(
        () => c.service.desistir(c.ongB, reserva.id),
        throwsA(isA<NaoEncontradoException>()),
      );
    });
  });

  group('expiração', () {
    test('RN29: prazo vencido expira, conta desistência e bloqueia', () async {
      final doacao = await c.publicar();
      await c.service.aceitar(c.ongA, doacao.id);
      c.avancar(const Duration(minutes: 61));

      final expiradas = await c.service.expirarVencidas();

      expect(expiradas, hasLength(1));
      expect((await c.doacao(doacao.id)).status, StatusDoacao.disponivel);
      expect(
        () => c.service.aceitar(c.ongA, doacao.id),
        conflito('ONG_BLOQUEADA_NESTA_DOACAO'),
      );
    });

    test('RN29: antes de aceitar, a retirada vencida é expirada', () async {
      final doacao = await c.publicar();
      await c.service.aceitar(c.ongA, doacao.id);
      c.avancar(const Duration(minutes: 61)); // o job ainda não rodou

      final daOngB = await c.service.aceitar(c.ongB, doacao.id);

      expect(daOngB.estaAtiva, isTrue);
    });
  });

  group('suspensão', () {
    Future<void> desistirDeUma() async {
      final reserva = await c.service.aceitar(c.ongA, (await c.publicar()).id);
      c.avancar(const Duration(minutes: 10));
      await c.service.desistir(c.ongA, reserva.id);
    }

    test('RN24: na 2ª desistência a situação avisa que a próxima '
        'suspende', () async {
      await desistirDeUma();
      await desistirDeUma();

      final situacao = await c.service.situacao(c.ongA);

      expect(situacao.desistenciasRecentes, 2);
      expect(situacao.proximaDesistenciaSuspende, isTrue);
    });

    test('RN24: 3 desistências em 30 dias suspendem por 48 h', () async {
      await desistirDeUma();
      await desistirDeUma();
      final reserva = await c.service.aceitar(c.ongA, (await c.publicar()).id);
      c.avancar(const Duration(minutes: 10));

      final resposta = await c.service.desistir(c.ongA, reserva.id);

      expect(resposta.suspensaAte, c.agora.add(const Duration(hours: 48)));
      expect(
        () async => c.service.aceitar(c.ongA, (await c.publicar()).id),
        conflito('ONG_SUSPENSA'),
      );
    });

    test('RN24: desistências com mais de 30 dias não contam', () async {
      await desistirDeUma();
      await desistirDeUma();
      c.avancar(const Duration(days: 31));

      expect((await c.service.situacao(c.ongA)).desistenciasRecentes, 0);
    });
  });

  test('situação: retiradas em andamento com o código e as regras', () async {
    await c.service.aceitar(c.ongA, (await c.publicar()).id);

    final situacao = await c.service.situacao(c.ongA);

    expect(situacao.ativas.single.codigoRetirada, CenarioDeRetirada.codigo);
    expect(situacao.regras.prazo, const Duration(minutes: 60));
  });
}
