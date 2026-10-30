import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../data/reservas/reserva_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Minhas reservas (ativas + histórico) — PLACEHOLDER do Sprint 0.
///
/// Responsável: Pessoa 5. Passo a passo: trilha/19-app-ong.md
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class MinhasReservasPage extends StatelessWidget {
  const MinhasReservasPage({
    super.key,
    required this.reservas,
    required this.relogio,
  });

  final ReservaRepository reservas;
  final Relogio relogio;

  @override
  Widget build(BuildContext context) => const EmConstrucao(
        titulo: 'Minhas reservas',
        responsavel: 'Pessoa 5',
        etapa: 'trilha/19-app-ong.md',
      );
}
