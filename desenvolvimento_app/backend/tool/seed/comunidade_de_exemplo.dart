import 'contas_de_exemplo.dart';
import 'gravador_de_exemplos.dart';

/// 2 publicações com foto, sem doação ligada, e um apoio em cada uma
/// (as MESMAS do modo Fake, em `app/lib/data/fake/comunidade_fake.dart`).
Future<void> criarComunidadeDeExemplo(
  GravadorDeExemplos ex,
  ContasDeExemplo contas, {
  required DateTime agora,
}) async {
  final cestas = await ex.publicacao(
    autorId: contas.pratoCheio,
    texto:
        'Com os mantimentos do Mercado Bom Preço montamos 40 cestas '
        'básicas esta semana: arroz, feijão, macarrão, farinha de milho, '
        'açúcar e óleo. Obrigado pela parceria!',
    familias: 40,
    em: agora.subtract(const Duration(days: 2)),
  );
  await ex.fotoDaPublicacao(cestas, 'mantimentos.jpg');

  final cafe = await ex.publicacao(
    autorId: contas.maosAmigas,
    texto:
        'Os pães do dia da Padaria Pão Quente viraram o café da manhã '
        'de 80 pessoas no nosso projeto. Nada foi para o lixo!',
    refeicoes: 80,
    em: agora.subtract(const Duration(days: 1)),
  );
  await ex.fotoDaPublicacao(cafe, 'paes.jpg');

  final em = agora.subtract(const Duration(hours: 1));
  await ex.apoio(publicacaoId: cestas, usuarioId: contas.mercado, em: em);
  await ex.apoio(publicacaoId: cafe, usuarioId: contas.padaria, em: em);
}
