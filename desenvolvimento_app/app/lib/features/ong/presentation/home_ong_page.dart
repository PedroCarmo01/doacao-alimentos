import 'package:flutter/material.dart';

import '../../../core/sessao/sessao.dart';
import '../../../data/doacoes/doacao_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Doações próximas (início da ONG) — provisória.
///
/// Provisória: a etapa indicada no EmConstrucao (05-PLANO-DE-CONSTRUCAO.md)
/// troca o conteúdo desta tela.
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class HomeOngPage extends StatelessWidget {
  const HomeOngPage({super.key, required this.doacoes, required this.sessao});

  final DoacaoRepository doacoes;
  final Sessao sessao;

  @override
  Widget build(BuildContext context) => const EmConstrucao(
    titulo: 'Doações próximas',
    etapa: 3,
    descricao: 'Doações perto de você, da mais perto para a mais longe.',
  );
}
