import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/reservas/reserva_exceptions.dart';
import 'package:test/test.dart';

import '../apoio/cenario_de_retirada.dart';

/// O doador confirma com o código (RN27) ou marca "A ONG não compareceu"
/// (RN28).
void main() {
  late CenarioDeRetirada c;
  late Doacao doacao;
  late Reserva reserva;

  setUp(() async {
    c = await CenarioDeRetirada.criar();
    doacao = await c.publicar();
    reserva = await c.service.aceitar(c.ongA, doacao.id);
  });

  Future<void> confirmar(String codigo) =>
      c.confirmacao.confirmar(c.doador, reserva.id, codigo);

  test('RN27: código certo conclui a retirada e a doação', () async {
    final concluida = await c.confirmacao.confirmar(
      c.doador,
      reserva.id,
      CenarioDeRetirada.codigo,
    );

    expect(concluida.status, StatusReserva.concluida);
    expect(concluida.codigoRetirada, isNull); // RN26: volta sem o código
    expect((await c.doacao(doacao.id)).status, StatusDoacao.concluida);
  });

  test('RN27: código errado avisa quantas tentativas restam', () {
    expect(
      () => confirmar('0000'),
      throwsA(
        isA<CodigoIncorretoException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('Restam 4'),
        ),
      ),
    );
  });

  test('RN27: 5 erros seguidos bloqueiam por 10 minutos', () async {
    for (var i = 0; i < 4; i++) {
      await expectLater(
        confirmar('0000'),
        throwsA(isA<CodigoIncorretoException>()),
      );
    }
    await expectLater(
      confirmar('0000'),
      throwsA(isA<TentativasEsgotadasException>()),
    );
    // Nem o código certo passa durante o bloqueio...
    await expectLater(
      confirmar(CenarioDeRetirada.codigo),
      throwsA(isA<TentativasEsgotadasException>()),
    );
    // ...mas passa depois dos 10 minutos.
    c.avancar(const Duration(minutes: 10));
    await confirmar(CenarioDeRetirada.codigo);
    expect((await c.doacao(doacao.id)).status, StatusDoacao.concluida);
  });

  test('RN27: depois do prazo não dá mais para confirmar', () {
    c.avancar(const Duration(minutes: 61));
    expect(
      () => confirmar(CenarioDeRetirada.codigo),
      throwsA(
        isA<ConflitoException>().having(
          (e) => e.codigo,
          'codigo',
          'RESERVA_NAO_ATIVA',
        ),
      ),
    );
  });

  test('RN27: código com letras ou tamanho errado é recusado', () {
    expect(() => confirmar('12'), throwsA(isA<ValidacaoException>()));
  });

  test('RN27: quem digita é o doador; a ONG não confirma sozinha', () {
    expect(
      () => c.confirmacao.confirmar(c.ongA, reserva.id, '4821'),
      throwsA(isA<SemPermissaoException>()),
    );
  });

  test('RN28: "não compareceu" só depois do prazo', () {
    expect(
      () => c.confirmacao.naoCompareceu(c.doador, reserva.id),
      throwsA(
        isA<ConflitoException>().having(
          (e) => e.codigo,
          'codigo',
          'PRAZO_NAO_ACABOU',
        ),
      ),
    );
  });

  test('RN28: depois do prazo tem o mesmo efeito da expiração', () async {
    c.avancar(const Duration(minutes: 61));

    await c.confirmacao.naoCompareceu(c.doador, reserva.id);

    expect((await c.doacao(doacao.id)).status, StatusDoacao.disponivel);
    final situacao = await c.service.situacao(c.ongA);
    expect(situacao.desistenciasRecentes, 1);
  });
}
