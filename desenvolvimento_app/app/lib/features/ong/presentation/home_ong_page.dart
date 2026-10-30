import 'package:flutter/material.dart';

import '../../../core/sessao/sessao.dart';
import '../../../data/doacoes/doacao_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Doações próximas (início da ONG) — PLACEHOLDER do Sprint 0.
///
/// Responsável: Pessoa 5. Passo a passo: trilha/19-app-ong.md
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class HomeOngPage extends StatelessWidget {
  const HomeOngPage({
    super.key,
    required this.doacoes,
    required this.sessao,
  });

  final DoacaoRepository doacoes;
  final Sessao sessao;

  @override
  Widget build(BuildContext context) => EmConstrucao(
        titulo: 'Doações próximas',
        responsavel: 'Pessoa 5',
        etapa: 'trilha/19-app-ong.md',
        sessao: sessao,
      );
}
