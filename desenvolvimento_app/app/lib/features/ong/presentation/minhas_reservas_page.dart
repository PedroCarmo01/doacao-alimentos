import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../data/reservas/reserva_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Minhas reservas (ativas + histórico) — provisória.
///
/// Provisória: a etapa indicada no EmConstrucao (05-PLANO-DE-CONSTRUCAO.md)
/// troca o conteúdo desta tela.
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
    etapa: 4,
    descricao: 'Suas retiradas em andamento e o histórico.',
  );
}
