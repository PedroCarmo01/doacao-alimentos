import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/utils/formatador.dart';

/// Os textos curtos que as telas mostram.
void main() {
  Doacao doacao(double quantidade, Unidade unidade, double pesoKg) => Doacao(
    id: 1,
    doadorId: 1,
    titulo: 'Teste',
    categoria: CategoriaAlimento.padaria,
    quantidade: quantidade,
    unidade: unidade,
    pesoKg: pesoKg,
    conservacao: Conservacao.ambiente,
    validade: DateTime.utc(2026, 9, 16),
    janelaInicio: DateTime.utc(2026, 9, 15, 12),
    janelaFim: DateTime.utc(2026, 9, 15, 15),
    latitude: 0,
    longitude: 0,
    status: StatusDoacao.disponivel,
    criadoEm: DateTime.utc(2026, 9, 15, 12),
  );

  test('quantidade e peso: "30 unidades • 6 kg"', () {
    expect(
      Formatador.quantidadeEPeso(doacao(30, Unidade.unidades, 6)),
      '30 unidades • 6 kg',
    );
  });

  test('em kg, o peso não se repete: "4 kg"', () {
    expect(Formatador.quantidadeEPeso(doacao(4, Unidade.kg, 4)), '4 kg');
  });

  test('contador regressivo: minutos e, com 1 h ou mais, horas', () {
    expect(
      Formatador.contador(const Duration(minutes: 58, seconds: 41)),
      '58:41',
    );
    expect(
      Formatador.contador(const Duration(hours: 1, seconds: 5)),
      '1:00:05',
    );
  });
}
