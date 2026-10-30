import 'package:flutter/material.dart';

import '../../../core/sessao/sessao.dart';
import '../../../data/doacoes/doacao_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Minhas doações (início do doador) — PLACEHOLDER do Sprint 0.
///
/// Responsável: Pessoa 2. Passo a passo: trilha/18-app-doador.md
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
  Widget build(BuildContext context) => EmConstrucao(
        titulo: 'Minhas doações',
        responsavel: 'Pessoa 2',
        etapa: 'trilha/18-app-doador.md',
        sessao: sessao,
      );
}
