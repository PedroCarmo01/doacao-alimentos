import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/api/api_exception.dart';
import 'package:summit_app/data/fake/banco_fake.dart';

/// O BancoFake precisa seguir as mesmas regras do backend. Estes testes
/// usam um RelogioFixo para "avançar o tempo" sem esperar de verdade.
void main() {
  late RelogioFixo relogio;
  late BancoFake banco;

  setUp(() {
    relogio = RelogioFixo(DateTime.utc(2026, 9, 16, 15));
    banco = BancoFake(
      relogio: relogio,
      atrasoDeRede: Duration.zero,
      simularNovasDoacoes: false,
    );
  });

  void entrarComo(String email) =>
      banco.tokenPara(banco.autenticar(email, BancoFake.senhaPadrao));

  test('senha errada é recusada com CREDENCIAIS_INVALIDAS', () {
    expect(
      () => banco.autenticar('mercado@exemplo.com', 'errada'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.codigo,
          'codigo',
          'CREDENCIAIS_INVALIDAS',
        ),
      ),
    );
  });

  test('a ONG vê as doações próximas, ordenadas pela distância', () {
    entrarComo('maosamigas@exemplo.com');

    final proximas = banco.doacoesProximas();

    expect(proximas, isNotEmpty);
    expect(proximas.every((d) => d.estaDisponivel), isTrue);
    for (var i = 1; i < proximas.length; i++) {
      expect(
        proximas[i].distanciaKm,
        greaterThanOrEqualTo(proximas[i - 1].distanciaKm!),
      );
    }
  });

  test('a ONG distante (fora do raio) não vê nenhuma doação', () {
    entrarComo('distante@exemplo.com');

    expect(banco.doacoesProximas(), isEmpty);
  });

  test('duas ONGs não reservam a mesma doação', () {
    entrarComo('maosamigas@exemplo.com');
    final doacao = banco.doacoesProximas().first;
    banco.reservar(doacao.id);

    entrarComo('pratocheio@exemplo.com');
    expect(
      () => banco.reservar(doacao.id),
      throwsA(
        isA<ApiException>().having(
          (e) => e.codigo,
          'codigo',
          'DOACAO_INDISPONIVEL',
        ),
      ),
    );
  });

  test('reserva vencida expira e a doação volta a ficar disponível', () async {
    entrarComo('maosamigas@exemplo.com');
    final doacao = banco.doacoesProximas().first;
    final reserva = banco.reservar(doacao.id);

    relogio.avancar(banco.prazoReserva + const Duration(seconds: 1));
    await banco.simularRede(); // aplica a expiração, como o job do backend

    final atualizada = banco.reservas.firstWhere((r) => r.id == reserva.id);
    expect(atualizada.status, StatusReserva.expirada);
    expect(
      banco.doacoes.firstWhere((d) => d.id == doacao.id).status,
      StatusDoacao.disponivel,
    );
  });

  test('doador não pode reservar (403 SEM_PERMISSAO)', () {
    entrarComo('mercado@exemplo.com');

    expect(
      () => banco.reservar(1),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
    );
  });
}
