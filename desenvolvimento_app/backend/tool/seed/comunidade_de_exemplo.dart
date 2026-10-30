import 'contas_de_exemplo.dart';
import 'gravador_de_exemplos.dart';

/// 4 publicações e alguns apoios, para o painel de impacto (etapa 7).
Future<void> criarComunidadeDeExemplo(
  GravadorDeExemplos ex,
  ContasDeExemplo contas, {
  required DateTime agora,
  required List<int> doacoesConcluidas,
}) async {
  final arroz = await ex.publicacao(
    autorId: contas.maosAmigas,
    texto:
        'O arroz e o feijão do Mercado Bom Preço viraram 160 refeições '
        'na nossa cozinha comunitária. Obrigado!',
    doacaoId: doacoesConcluidas[0],
    familias: 40,
    refeicoes: 160,
    em: agora.subtract(const Duration(days: 5)),
  );
  final enlatados = await ex.publicacao(
    autorId: contas.pratoCheio,
    texto: 'Os enlatados completaram as cestas básicas desta semana.',
    doacaoId: doacoesConcluidas[1],
    familias: 25,
    em: agora.subtract(const Duration(days: 2)),
  );
  await ex.publicacao(
    autorId: contas.mercado,
    texto:
        'Este mês já evitamos o desperdício de 100 kg de alimentos. '
        'Obrigado às ONGs parceiras!',
    em: agora.subtract(const Duration(days: 1)),
  );
  await ex.publicacao(
    autorId: contas.padaria,
    texto: 'Todo dia às 14h temos pães e marmitas para doar.',
    em: agora.subtract(const Duration(hours: 6)),
  );
  final em = agora.subtract(const Duration(hours: 1));
  await ex.apoio(publicacaoId: arroz, usuarioId: contas.mercado, em: em);
  await ex.apoio(publicacaoId: arroz, usuarioId: contas.padaria, em: em);
  await ex.apoio(publicacaoId: enlatados, usuarioId: contas.mercado, em: em);
}
