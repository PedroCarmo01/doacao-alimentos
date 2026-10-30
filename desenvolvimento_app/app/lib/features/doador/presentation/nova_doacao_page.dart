import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/sessao/sessao.dart';
import '../../../data/doacoes/doacao_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Nova doação — provisória.
///
/// Provisória: a etapa indicada no EmConstrucao (05-PLANO-DE-CONSTRUCAO.md)
/// troca o conteúdo desta tela.
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class NovaDoacaoPage extends StatelessWidget {
  const NovaDoacaoPage({
    super.key,
    required this.doacoes,
    required this.sessao,
    required this.relogio,
  });

  final DoacaoRepository doacoes;
  final Sessao sessao;
  final Relogio relogio;

  @override
  Widget build(BuildContext context) => const EmConstrucao(
    titulo: 'Nova doação',
    etapa: 2,
    descricao: 'Formulário para publicar uma doação com até 3 fotos.',
  );
}
