import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/features/doador/confirmar_retirada_view_model.dart';
import 'package:summit_app/features/navegacao/faixa_de_retirada_view_model.dart';
import 'package:summit_app/features/ong/detalhe_doacao_ong_view_model.dart';
import 'package:summit_app/features/ong/retirada_view_model.dart';

/// Etapa 4 — aceite, retirada em andamento, código e faixa, no modo Fake
/// (prazo de 2 min, como o BancoFake usa para a demonstração).
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
    );
  });

  Future<void> entrarComo(String email) async => deps.sessao.iniciar(
    await deps.auth.entrar(DadosLogin(email: email, senha: 'senha123')),
  );

  Future<Doacao> doacaoProxima(String inicioDoTitulo) async {
    final lista = await deps.doacoes.listarProximas();
    return lista.firstWhere((d) => d.titulo.startsWith(inicioDoTitulo));
  }

  DetalheDoacaoOngViewModel detalhe(int doacaoId) => DetalheDoacaoOngViewModel(
    doacoes: deps.doacoes,
    reservas: deps.reservas,
    sessao: deps.sessao,
    relogio: relogio,
    doacaoId: doacaoId,
  );

  RetiradaViewModel retirada(int reservaId) => RetiradaViewModel(
    reservas: deps.reservas,
    doacoes: deps.doacoes,
    relogio: relogio,
    reservaId: reservaId,
  );

  /// Mãos Amigas aceita as frutas e devolve a retirada.
  Future<Reserva> maosAmigasAceitaFrutas() async {
    await entrarComo('maosamigas@exemplo.com');
    final vm = detalhe((await doacaoProxima('Frutas')).id);
    await vm.carregar();
    return (await vm.aceitar())!;
  }

  group('Vou retirar (T22)', () {
    test('RN20: a primeira aceita; a segunda vê "Que pena!"', () async {
      await entrarComo('maosamigas@exemplo.com');
      final frutas = await doacaoProxima('Frutas');
      final primeira = detalhe(frutas.id);
      await primeira.carregar();

      await entrarComo('pratocheio@exemplo.com');
      final segunda = detalhe(frutas.id);
      await segunda.carregar(); // as duas abriram a doação disponível

      await entrarComo('maosamigas@exemplo.com');
      expect(await primeira.aceitar(), isNotNull);
      await entrarComo('pratocheio@exemplo.com');
      expect(await segunda.aceitar(), isNull);
      expect(segunda.outraOngAceitou, isTrue);
    });

    test('RN21/RN26: aceite com prazo e código de 4 dígitos', () async {
      final reserva = await maosAmigasAceitaFrutas();

      expect(reserva.codigoRetirada, matches(RegExp(r'^\d{4}$')));
      expect(reserva.expiraEm, relogio.agora().add(const Duration(minutes: 2)));
    });

    test(
      'RN24: na 2ª desistência o aviso diz que a próxima suspende',
      () async {
        await entrarComo('pratocheio@exemplo.com'); // tem 2 desistências
        final vm = detalhe((await doacaoProxima('Frutas')).id);
        await vm.carregar();

        expect(vm.avisoDoAceite, contains('mais uma desistência'));
        expect(vm.avisoDoAceite, startsWith('Você terá 2 min para retirar'));
      },
    );

    test('RN24: ONG suspensa vê o botão desativado com o motivo', () async {
      await entrarComo('suspensa@exemplo.com');
      final vm = detalhe((await doacaoProxima('Frutas')).id);
      await vm.carregar();

      expect(vm.motivoParaNaoAceitar, contains('suspensa'));
    });

    test('RN25: com 2 retiradas em andamento não aceita a 3ª', () async {
      await maosAmigasAceitaFrutas(); // já tinha as cestas: agora são 2
      final vm = detalhe((await doacaoProxima('Marmitas')).id);
      await vm.carregar();

      expect(vm.motivoParaNaoAceitar, contains('2 retiradas'));
    });
  });

  group('Retirada em andamento (T23)', () {
    test('mostra o contador e o código', () async {
      final reserva = await maosAmigasAceitaFrutas();
      final vm = retirada(reserva.id);

      await vm.carregar();

      expect(vm.reserva!.codigoRetirada, reserva.codigoRetirada);
      expect(vm.restante, const Duration(minutes: 2));
      expect(vm.detalhe!.doacao.titulo, startsWith('Frutas'));
    });

    test('RN23: desistir no primeiro minuto não conta', () async {
      final reserva = await maosAmigasAceitaFrutas();
      final vm = retirada(reserva.id);
      await vm.carregar();
      relogio.avancar(const Duration(minutes: 1));

      expect(vm.dentroDaTolerancia, isTrue);
      expect(await vm.desistir(), isTrue);
      expect(vm.desistencia!.contouDesistencia, isFalse);
      expect(vm.reserva!.status, StatusReserva.canceladaOng);
    });

    test('RN22: a doação vencida volta e some para quem não retirou', () async {
      final reserva = await maosAmigasAceitaFrutas();
      relogio.avancar(const Duration(minutes: 3)); // passou do prazo (2 min)

      final vm = retirada(reserva.id);
      await vm.carregar();

      expect(vm.reserva!.status, StatusReserva.expirada);
      final proximas = await deps.doacoes.listarProximas();
      expect(proximas.any((d) => d.id == reserva.doacaoId), isFalse);
    });
  });

  group('Confirmar retirada (T13)', () {
    late Reserva reserva;

    setUp(() async {
      reserva = await maosAmigasAceitaFrutas();
      await entrarComo('mercado@exemplo.com');
    });

    ConfirmarRetiradaViewModel confirmar() => ConfirmarRetiradaViewModel(
      reservas: deps.reservas,
      reservaId: reserva.id,
    );

    test('RN27: código errado mostra quantas tentativas restam', () async {
      final vm = confirmar();
      final errado = reserva.codigoRetirada == '0000' ? '1111' : '0000';

      expect(await vm.confirmar(errado), isFalse);
      expect(vm.erro, contains('Restam 4'));
    });

    test('RN27: código certo conclui a retirada', () async {
      final vm = confirmar();

      expect(await vm.confirmar(reserva.codigoRetirada!), isTrue);
      expect(vm.confirmada, isTrue);
    });

    test('RN27: menos de 4 números nem vai ao servidor', () async {
      final vm = confirmar();

      expect(await vm.confirmar('12'), isFalse);
      expect(vm.erro, 'Digite os 4 números do código.');
    });
  });

  group('Faixa de retirada', () {
    FaixaDeRetiradaViewModel faixa() => FaixaDeRetiradaViewModel(
      reservas: deps.reservas,
      doacoes: deps.doacoes,
      sessao: deps.sessao,
      relogio: relogio,
    );

    test('ONG: "Retirada em andamento" com o tempo restante', () async {
      await entrarComo('maosamigas@exemplo.com'); // tem as cestas (60 min)
      final vm = faixa();

      await vm.atualizar();

      expect(vm.visivel, isTrue);
      expect(vm.texto, 'Retirada em andamento • 50:00 restantes');
      vm.dispose();
    });

    test('doador: "ONG Mãos Amigas a caminho"', () async {
      await entrarComo('mercado@exemplo.com');
      final vm = faixa();

      await vm.atualizar();

      expect(vm.texto, 'ONG Mãos Amigas a caminho');
      vm.dispose();
    });

    test('quem não tem retirada não vê a faixa', () async {
      await entrarComo('padaria@exemplo.com');
      final vm = faixa();

      await vm.atualizar();

      expect(vm.visivel, isFalse);
      vm.dispose();
    });
  });
}
