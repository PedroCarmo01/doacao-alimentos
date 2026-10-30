import 'package:flutter/material.dart';

import '../../../core/sessao/sessao.dart';
import '../../../data/doacoes/doacao_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Minhas doações (início do doador) — provisória.
///
/// Provisória: a etapa indicada no EmConstrucao (05-PLANO-DE-CONSTRUCAO.md)
/// troca o conteúdo desta tela.
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class HomeDoadorPage extends StatelessWidget {
  const HomeDoadorPage({
    super.key,
    required this.doacoes,
    required this.sessao,
  });

  final DoacaoRepository doacoes;
  final Sessao sessao;

  @override
  Widget build(BuildContext context) => const EmConstrucao(
    titulo: 'Minhas doações',
    etapa: 2,
    descricao: 'Suas doações ativas e o histórico, com fotos e status.',
  );
}
