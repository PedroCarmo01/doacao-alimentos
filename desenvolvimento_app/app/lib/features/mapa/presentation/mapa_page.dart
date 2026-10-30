import 'package:flutter/material.dart';

import '../../../core/sessao/sessao.dart';
import '../../../data/doacoes/doacao_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Mapa de doações próximas — PLACEHOLDER do Sprint 0.
///
/// Responsável: Pessoa 4. Passo a passo: trilha/20-app-mapa.md
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class MapaPage extends StatelessWidget {
  const MapaPage({
    super.key,
    required this.doacoes,
    required this.sessao,
  });

  final DoacaoRepository doacoes;
  final Sessao sessao;

  @override
  Widget build(BuildContext context) => const EmConstrucao(
        titulo: 'Mapa de doações',
        responsavel: 'Pessoa 4',
        etapa: 'trilha/20-app-mapa.md',
      );
}
