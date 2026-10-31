import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:test/test.dart';

import '../apoio/cenario_de_retirada.dart';

/// O chat da retirada: quem participa (RN30), só leitura depois do fim
/// (RN31), mensagens do sistema, "✓ lida" e a notificação.
void main() {
  late CenarioDeRetirada c;
  late Reserva reserva;

  setUp(() async {
    c = await CenarioDeRetirada.criar();
    reserva = await c.service.aceitar(c.ongA, (await c.publicar()).id);
  });

  Future<List<Mensagem>> todas(UsuarioAutenticado quem) async =>
      (await c.chat.mensagens(quem, reserva.id, 0)).mensagens;

  test('o aceite abre a conversa com a mensagem do sistema', () async {
    final mensagens = await todas(c.doador);

    expect(mensagens.single.ehDoSistema, isTrue);
    expect(mensagens.single.texto, contains('aceitou a doação'));
  });

  test('RN30: doador e ONG conversam e a outra pessoa é avisada', () async {
    await c.chat.enviar(c.ongA, reserva.id, 'Estou a caminho');
    await c.chat.enviar(c.doador, reserva.id, 'Pode entrar pelo portão');

    final textos = [for (final m in await todas(c.ongA)) m.texto];
    expect(textos.skip(1), ['Estou a caminho', 'Pode entrar pelo portão']);
    final aviso = c.notificacoes
        .de(c.doador.id)
        .lastWhere((n) => n.tipo == TipoNotificacao.mensagemNova);
    expect(aviso.corpo, 'Estou a caminho');
    expect(aviso.reservaId, reserva.id);
  });

  test('RN30: outra ONG não lê nem escreve', () {
    expect(
      () => c.chat.mensagens(c.ongB, reserva.id, 0),
      throwsA(isA<NaoEncontradoException>()),
    );
    expect(
      () => c.chat.enviar(c.ongB, reserva.id, 'Oi'),
      throwsA(isA<NaoEncontradoException>()),
    );
  });

  test('RN30: mensagem vazia é recusada', () {
    expect(
      () => c.chat.enviar(c.ongA, reserva.id, '   '),
      throwsA(isA<ValidacaoException>()),
    );
  });

  test('RN31: depois da retirada, só leitura', () async {
    await c.confirmacao.confirmar(
      c.doador,
      reserva.id,
      CenarioDeRetirada.codigo,
    );

    final resposta = await c.chat.mensagens(c.ongA, reserva.id, 0);
    expect(resposta.somenteLeitura, isTrue);
    expect(resposta.mensagens.last.texto, contains('Retirada confirmada'));
    expect(
      () => c.chat.enviar(c.ongA, reserva.id, 'Obrigado!'),
      throwsA(
        isA<ConflitoException>().having(
          (e) => e.codigo,
          'codigo',
          'CHAT_SOMENTE_LEITURA',
        ),
      ),
    );
  });

  test('RN31: 7 dias depois do fim, a conversa some', () async {
    c.avancar(const Duration(minutes: 61));
    await c.service.expirarVencidas(); // o prazo acabou

    expect(await c.chat.conversas(c.doador), hasLength(1));
    c.avancar(const Duration(days: 8));
    expect(await c.chat.conversas(c.doador), isEmpty);
    expect(
      () => c.chat.mensagens(c.doador, reserva.id, 0),
      throwsA(isA<NaoEncontradoException>()),
    );
  });

  test('não lidas na lista e "✓ lida" para quem enviou', () async {
    final enviada = await c.chat.enviar(c.ongA, reserva.id, 'Cheguei');

    final antes = await c.chat.conversas(c.doador);
    expect(antes.single.naoLidas, 1);
    expect(antes.single.nomeOutro, 'Org a@ex.com');

    await c.chat.marcarLidas(c.doador, reserva.id);

    expect((await c.chat.conversas(c.doador)).single.naoLidas, 0);
    final paraOng = await c.chat.mensagens(c.ongA, reserva.id, enviada.id);
    expect(paraOng.lidasAte, enviada.id);
  });

  test('só as novas depois do último id (consulta a cada 4 s)', () async {
    final primeira = await c.chat.enviar(c.ongA, reserva.id, 'Um');
    await c.chat.enviar(c.ongA, reserva.id, 'Dois');

    final novas = await c.chat.mensagens(c.doador, reserva.id, primeira.id);

    expect([for (final m in novas.mensagens) m.texto], ['Dois']);
  });
}
