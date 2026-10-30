import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/sessao/sessao.dart';
import '../../../data/doacoes/doacao_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Nova doação — PLACEHOLDER do Sprint 0.
///
/// Responsável: Pessoa 2. Passo a passo: trilha/18-app-doador.md
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
    responsavel: 'Pessoa 2',
    etapa: 'trilha/18-app-doador.md',
  );
}
