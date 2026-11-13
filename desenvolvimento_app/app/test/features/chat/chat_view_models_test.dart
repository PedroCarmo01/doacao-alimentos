import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/core/notificacoes/mostrador_de_notificacoes.dart';
import 'package:summit_app/core/notificacoes/receptor_de_notificacoes.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/data/notificacoes/notificacao_repository.dart';
import 'package:summit_app/features/chat/chat_view_model.dart';
import 'package:summit_app/features/chat/conversas_view_model.dart';

/// Etapa 6 — o chat da retirada no modo Fake. O exemplo: Mãos Amigas está
/// retirando os mantimentos do mercado e os dois já trocaram 3 mensagens
/// (a última, do mercado, a ONG ainda não leu).
void main() {
  late RelogioFixo relogio;
  late BancoFake banco;
  late Dependencias deps;
  late MostradorEmMemoria mostrador;
  late ReceptorPorConsulta receptor;

  setUp(() {
    relogio = RelogioFixo(DateTime.utc(2026, 9, 15, 15));
    banco = BancoFake(
      relogio: relogio,
      atrasoDeRede: Duration.zero,
      simularNovasDoacoes: false,
    );
    mostrador = MostradorEmMemoria();
    deps = Dependencias.fake(banco: banco, mostrador: mostrador);
    receptor = ReceptorPorConsulta(
      notificacoes: NotificacaoRepositoryFake(banco),
      mostrador: mostrador,
      relogio: relogio,
    );
  });

  Future<void> entrarComo(String email) async => deps.sessao.iniciar(
    await deps.auth.entrar(DadosLogin(email: email, senha: 'senha123')),
  );

  ResumoConversa mantimentos(List<ResumoConversa> conversas) => conversas
      .firstWhere((c) => c.tituloDoacao == 'Mantimentos não perecíveis');

  Future<int> reservaDosMantimentos() async =>
      mantimentos(await deps.chat.conversas()).reservaId;

  ChatViewModel abrir(int reservaId) => ChatViewModel(
    chat: deps.chat,
    sessao: deps.sessao,
    receptor: receptor,
    reservaId: reservaId,
  );

  test('T31: a ONG vê a conversa dos mantimentos com 1 não lida', () async {
    await entrarComo('maosamigas@exemplo.com');
    final vm = ConversasViewModel(chat: deps.chat, relogio: relogio);

    await vm.carregar();

    final conversa = mantimentos(vm.conversas);
    expect(conversa.nomeOutro, 'Mercado Bom Preço');
    expect(conversa.naoLidas, 1); // "Combinado. Pode entrar pelo portão..."
    expect(conversa.somenteLeitura, isFalse);
    expect(vm.totalNaoLidas, 1);
    vm.dispose();
  });

  test('RN31: as retiradas encerradas há menos de 7 dias ficam só para '
      'leitura', () async {
    // O Prato Cheio deixou o prazo acabar nas 2 doações dos exemplos.
    await entrarComo('pratocheio@exemplo.com');
    final vm = ConversasViewModel(chat: deps.chat, relogio: relogio);

    await vm.carregar();

    expect(vm.conversas, hasLength(2));
    expect(vm.conversas.every((c) => c.somenteLeitura), isTrue);
    vm.dispose();
  });

  test('T30: abrir a conversa marca como lida e o outro vê "✓ lida"', () async {
    await entrarComo('maosamigas@exemplo.com');
    final reserva = await reservaDosMantimentos();
    final vm = abrir(reserva);

    await vm.carregar();

    expect(vm.mensagens.first.ehDoSistema, isTrue);
    expect(vm.titulo, 'Mercado Bom Preço');
    expect(mantimentos(await deps.chat.conversas()).naoLidas, 0);

    await entrarComo('mercado@exemplo.com');
    final doMercado = abrir(reserva);
    await doMercado.carregar();
    final minha = doMercado.mensagens.last; // "Combinado. Pode entrar.."
    expect(doMercado.ehMinha(minha), isTrue);
    expect(doMercado.foiLida(minha), isTrue);
  });

  test('RN30: enviar uma resposta rápida avisa o outro', () async {
    await entrarComo('maosamigas@exemplo.com');
    final reserva = await reservaDosMantimentos();
    final vm = abrir(reserva);
    await vm.carregar();

    expect(await vm.enviar(vm.respostasRapidas[1]), isTrue); // "Cheguei"

    expect(vm.mensagens.last.texto, 'Cheguei');
    await entrarComo('mercado@exemplo.com');
    await receptor.consultar();
    expect(mostrador.mostradas.last.tipo, TipoNotificacao.mensagemNova);
    expect(mostrador.mostradas.last.corpo, 'Cheguei');
  });

  test('a conversa aberta na tela não vira notificação', () async {
    await entrarComo('maosamigas@exemplo.com');
    final reserva = await reservaDosMantimentos();
    await deps.chat.enviar(reserva, 'Estou chegando');

    await entrarComo('mercado@exemplo.com');
    receptor.conversaAberta(reserva);
    await receptor.consultar();

    expect(
      mostrador.mostradas.where((n) => n.tipo == TipoNotificacao.mensagemNova),
      isEmpty,
    );
  });

  test('RN30: mensagem vazia não é enviada', () async {
    await entrarComo('maosamigas@exemplo.com');
    final vm = abrir(await reservaDosMantimentos());
    await vm.carregar();

    expect(await vm.enviar('   '), isFalse);
    expect(vm.erro, 'Escreva uma mensagem.');
  });

  test('RN30: outra ONG não vê a conversa', () async {
    await entrarComo('maosamigas@exemplo.com');
    final reserva = await reservaDosMantimentos();

    await entrarComo('pratocheio@exemplo.com');
    final vm = abrir(reserva);

    expect(await vm.carregar(), isFalse);
    final daPratoCheio = await deps.chat.conversas();
    expect(daPratoCheio.any((c) => c.reservaId == reserva), isFalse);
  });

  test('RN31: confirmada a retirada, a conversa fica só de leitura', () async {
    await entrarComo('mercado@exemplo.com');
    final reserva = await reservaDosMantimentos();
    await deps.reservas.confirmar(reserva, '4821');

    final vm = abrir(reserva);
    await vm.carregar();

    expect(vm.somenteLeitura, isTrue);
    expect(vm.mensagens.last.texto, contains('Retirada confirmada'));
    expect(await vm.enviar('Obrigado!'), isFalse);
  });
}
