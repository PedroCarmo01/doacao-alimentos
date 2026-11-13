import 'package:shared_models/shared_models.dart';
import 'package:summit_app/data/fake/banco_fake.dart';

/// Os dados de exemplo têm só 2 doações: os mantimentos (já reservados
/// pela Mãos Amigas) e o pão francês (disponível, mas bloqueado para o
/// Prato Cheio). Os testes que precisam de MAIS doações disponíveis
/// publicam outras com esta função, como um doador faria no app.
///
/// Atenção: ela entra no [banco] com o [doador]. Depois, faça login de
/// novo com quem o teste precisa.
Doacao publicarDoacaoExtra(
  BancoFake banco,
  Relogio relogio, {
  required String titulo,
  String doador = 'mercado@exemplo.com',
  double pesoKg = 10,
}) {
  banco.tokenPara(banco.autenticar(doador, BancoFake.senhaPadrao));
  final agora = relogio.agora();
  return banco
      .publicarDoacao(
        DadosNovaDoacao(
          titulo: titulo,
          categoria: CategoriaAlimento.hortifruti,
          quantidade: 3,
          unidade: Unidade.caixas,
          pesoKg: pesoKg,
          conservacao: Conservacao.ambiente,
          validade: Calendario.somenteData(agora.add(const Duration(days: 1))),
          janelaInicio: agora,
          janelaFim: agora.add(const Duration(hours: 6)),
          declaracaoAlimentosProprios: true,
        ),
      )
      .doacao;
}
