import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../data/doacoes/doacao_repository.dart';
import '../../../data/reservas/reserva_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Detalhe da doação (doador) — PLACEHOLDER do Sprint 0.
///
/// Responsável: Pessoa 2. Passo a passo: trilha/18-app-doador.md
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class DetalheDoacaoDoadorPage extends StatelessWidget {
  const DetalheDoacaoDoadorPage({
    super.key,
    required this.doacaoId,
    required this.doacoes,
    required this.reservas,
    required this.relogio,
  });

  final int doacaoId;
  final DoacaoRepository doacoes;
  final ReservaRepository reservas;
  final Relogio relogio;

  @override
  Widget build(BuildContext context) => EmConstrucao(
        titulo: 'Doação #$doacaoId',
        responsavel: 'Pessoa 2',
        etapa: 'trilha/18-app-doador.md',
      );
}
