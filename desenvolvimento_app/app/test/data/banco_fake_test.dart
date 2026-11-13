import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/api/api_exception.dart';
import 'package:summit_app/data/fake/banco_fake.dart';

import '../apoio/doacao_extra.dart';

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
    // Uma doação disponível que nenhuma ONG de exemplo tem bloqueada
    // (o Prato Cheio está bloqueado nas 2 dos exemplos, RN22).
    publicarDoacaoExtra(banco, relogio, titulo: 'Frutas e verduras do dia');
  });

  void entrarComo(String email) =>
      banco.tokenPara(banco.autenticar(email, BancoFake.senhaPadrao));

  /// "Vou retirar" com a conta logada.
  Reserva aceitar(int doacaoId) =>
      banco.retiradas.aceitar(banco.ongLogada(), doacaoId);

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

  test('RN20: duas ONGs não aceitam a mesma doação', () {
    entrarComo('maosamigas@exemplo.com');
    final doacao = banco.doacoesProximas().firstWhere(
      (d) => d.titulo.startsWith('Frutas'),
    );
    aceitar(doacao.id);

    entrarComo('pratocheio@exemplo.com');
    expect(
      () => aceitar(doacao.id),
      throwsA(
        isA<ApiException>().having(
          (e) => e.codigo,
          'codigo',
          'DOACAO_INDISPONIVEL',
        ),
      ),
    );
  });

  test(
    'RN29: retirada vencida expira e a doação volta a ficar disponível',
    () async {
      entrarComo('maosamigas@exemplo.com');
      final doacao = banco.doacoesProximas().first;
      final reserva = aceitar(doacao.id);

      relogio.avancar(banco.prazoReserva + const Duration(seconds: 1));
      await banco.simularRede(); // aplica a expiração, como o job do backend

      final atualizada = banco.reservas.firstWhere((r) => r.id == reserva.id);
      expect(atualizada.status, StatusReserva.expirada);
      expect(
        banco.doacoes.firstWhere((d) => d.id == doacao.id).status,
        StatusDoacao.disponivel,
      );
    },
  );

  test('doador não pode reservar (403 SEM_PERMISSAO)', () {
    entrarComo('mercado@exemplo.com');

    expect(
      () => aceitar(1), // a conta logada não é ONG
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
    );
  });

  test('RN28: "A ONG não compareceu" só depois do prazo', () {
    entrarComo('maosamigas@exemplo.com');
    final frutas = banco.doacoesProximas().firstWhere(
      (d) => d.titulo.startsWith('Frutas'), // do mercado
    );
    final reserva = aceitar(frutas.id);
    entrarComo('mercado@exemplo.com');
    Conta doador() => banco.doadorLogado();

    expect(
      () => banco.retiradas.naoCompareceu(doador(), reserva.id),
      throwsA(
        isA<ApiException>().having(
          (e) => e.codigo,
          'codigo',
          'PRAZO_NAO_ACABOU',
        ),
      ),
    );
    relogio.avancar(banco.prazoReserva + const Duration(seconds: 1));
    banco.retiradas.naoCompareceu(doador(), reserva.id);

    final atualizada = banco.reservas.firstWhere((r) => r.id == reserva.id);
    expect(atualizada.status, StatusReserva.expirada);
    expect(atualizada.contouDesistencia, isTrue);
  });
}
