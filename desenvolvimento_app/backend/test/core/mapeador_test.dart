import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/db/mapeador.dart';
import 'package:test/test.dart';

void main() {
  group('Mapeador', () {
    test('converte a linha de texto do banco em uma Doacao tipada', () {
      // É assim que o driver do MySQL entrega os dados: tudo como texto.
      final linha = <String, String?>{
        'id': '10',
        'doador_id': '1',
        'titulo': 'Frutas do dia',
        'descricao': null,
        'categoria': 'hortifruti',
        'quantidade': '5 caixas',
        'validade': '2026-09-20',
        'janela_inicio': '2026-09-15 14:00:00',
        'janela_fim': '2026-09-15 20:00:00',
        'endereco': null,
        'latitude': '-23.522900',
        'longitude': '-46.188000',
        'status': 'disponivel',
        'criado_em': '2026-09-15 13:00:00',
        'distancia_km': '1.25',
      };

      final doacao = Mapeador.doacao(linha);

      expect(doacao.id, 10);
      expect(doacao.categoria, CategoriaAlimento.hortifruti);
      expect(doacao.janelaInicio, DateTime.utc(2026, 9, 15, 14));
      expect(doacao.latitude, closeTo(-23.5229, 0.000001));
      expect(doacao.distanciaKm, 1.25);
      // E o JSON que vai para o app sai em camelCase:
      expect(doacao.toJson()['doadorId'], 1);
    });

    test('coluna obrigatória ausente gera erro explicando o motivo', () {
      expect(
        () => Mapeador.usuario({'id': '1', 'nome': 'Ana'}),
        throwsA(
          isA<StateError>().having(
            (erro) => erro.message,
            'mensagem',
            contains('"email"'),
          ),
        ),
      );
    });
  });
}
