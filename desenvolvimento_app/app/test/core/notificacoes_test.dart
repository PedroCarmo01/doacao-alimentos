import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/core/notificacoes/destino_da_notificacao.dart';
import 'package:summit_app/core/notificacoes/mostrador_de_notificacoes.dart';
import 'package:summit_app/core/notificacoes/receptor_de_notificacoes.dart';
import 'package:summit_app/core/routing/app_routes.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/data/notificacoes/notificacao_repository.dart';

/// Etapa 5 — os avisos chegam por consulta e o toque abre a tela certa.
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

  Future<RespostaPublicacao> padariaPublica() async {
    await entrarComo('padaria@exemplo.com');
    return deps.doacoes.publicar(
      DadosNovaDoacao(
        titulo: 'Pães do dia',
        categoria: CategoriaAlimento.padaria,
        quantidade: 30,
        unidade: Unidade.unidades,
        pesoKg: 6,
        conservacao: Conservacao.ambiente,
        validade: DateTime.utc(2026, 9, 16),
        janelaInicio: relogio.agora(),
        janelaFim: relogio.agora().add(const Duration(hours: 3)),
        declaracaoAlimentosProprios: true,
      ),
    );
  }

  group('RN11 no modo Fake', () {
    test('a padaria publica e as ONGs perto são avisadas', () async {
      final resposta = await padariaPublica();

      // Mãos Amigas e Prato Cheio (perto, busca ativa). A suspensa e a
      // distante (45 km) não.
      expect(resposta.ongsAvisadas, 2);
    });

    test('a ONG distante não recebe nada', () async {
      await padariaPublica();
      await entrarComo('distante@exemplo.com');

      await receptor.consultar();

      expect(mostrador.mostradas, isEmpty);
    });
  });

  group('ReceptorPorConsulta', () {
    test('mostra o aviso novo uma vez só e marca como lido', () async {
      await padariaPublica();
      await entrarComo('maosamigas@exemplo.com');

      await receptor.consultar();
      await receptor.consultar(); // a próxima rodada não repete

      expect(mostrador.mostradas, hasLength(1));
      expect(mostrador.mostradas.single.tipo, TipoNotificacao.doacaoNova);
      expect(mostrador.mostradas.single.corpo, contains('Pães do dia'));
    });

    test('aceitar avisa o doador na próxima consulta', () async {
      final publicada = await padariaPublica();
      await entrarComo('maosamigas@exemplo.com');
      await deps.reservas.aceitar(publicada.doacao.id);

      await entrarComo('padaria@exemplo.com');
      await receptor.consultar();

      expect(mostrador.mostradas.single.tipo, TipoNotificacao.doacaoAceita);
    });

    test('o prazo acabando avisa os dois', () async {
      final publicada = await padariaPublica();
      await entrarComo('maosamigas@exemplo.com');
      await deps.reservas.aceitar(publicada.doacao.id);
      relogio.avancar(banco.prazoReserva + const Duration(seconds: 1));
      await banco.simularRede(); // o "job" do Fake

      await receptor.consultar();
      final paraOng = [for (final n in mostrador.mostradas) n.tipo];
      await entrarComo('padaria@exemplo.com');
      receptor.parar(); // outra conta: começa do zero
      await receptor.consultar();

      expect(paraOng, contains(TipoNotificacao.prazoAcabouOng));
      expect(
        mostrador.mostradas.map((n) => n.tipo),
        contains(TipoNotificacao.prazoAcabouDoador),
      );
    });

    test('avisos com mais de 1 hora não apitam', () async {
      await padariaPublica();
      relogio.avancar(const Duration(hours: 2));
      await entrarComo('maosamigas@exemplo.com');

      await receptor.consultar();

      // O "doação nova" de 2 h atrás fica quieto. (O "prazo acabou" das
      // cestas do exemplo, que venceu agora, apita: é novo.)
      expect(
        mostrador.mostradas.map((n) => n.tipo),
        isNot(contains(TipoNotificacao.doacaoNova)),
      );
    });

    test('ao iniciar, pede a permissão do Android 13+', () async {
      await entrarComo('maosamigas@exemplo.com');

      await receptor.iniciar(aoTocar: (_) {});
      receptor.parar();

      expect(mostrador.pediuPermissao, isTrue);
    });
  });

  group('DestinoDaNotificacao', () {
    Notificacao aviso(TipoNotificacao tipo) => Notificacao(
      id: 1,
      tipo: tipo,
      titulo: 't',
      corpo: 'c',
      criadoEm: DateTime.utc(2026),
      doacaoId: 7,
      reservaId: 9,
    );

    test('doação nova abre o detalhe para a ONG aceitar', () {
      final destino = DestinoDaNotificacao.para(
        aviso(TipoNotificacao.doacaoNova),
        ehOng: true,
      )!;
      expect(destino.rota, AppRoutes.detalheDoacaoOng);
      expect(destino.argumento, 7);
    });

    test('prazo acabando abre a retirada em andamento', () {
      final destino = DestinoDaNotificacao.para(
        aviso(TipoNotificacao.prazoAcabando),
        ehOng: true,
      )!;
      expect(destino.rota, AppRoutes.retirada);
      expect(destino.argumento, 9);
    });

    test('retirada confirmada: a ONG vê a retirada, o doador a doação', () {
      final confirmada = aviso(TipoNotificacao.retiradaConfirmada);
      expect(
        DestinoDaNotificacao.para(confirmada, ehOng: true)!.rota,
        AppRoutes.retirada,
      );
      expect(
        DestinoDaNotificacao.para(confirmada, ehOng: false)!.rota,
        AppRoutes.detalheDoacaoDoador,
      );
    });

    test('mensagem nova abre a conversa da retirada', () {
      final destino = DestinoDaNotificacao.para(
        aviso(TipoNotificacao.mensagemNova),
        ehOng: false,
      )!;
      expect(destino.rota, AppRoutes.chat);
      expect(destino.argumento, 9);
    });

    test('doação aceita abre o detalhe do doador', () {
      expect(
        DestinoDaNotificacao.para(
          aviso(TipoNotificacao.doacaoAceita),
          ehOng: false,
        )!.rota,
        AppRoutes.detalheDoacaoDoador,
      );
    });
  });
}
