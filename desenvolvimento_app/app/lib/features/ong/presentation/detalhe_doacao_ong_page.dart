import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../data/doacoes/doacao_repository.dart';
import '../../../data/reservas/reserva_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Detalhe da doação (ONG), com o botão Reservar — PLACEHOLDER.
///
/// Provisória: a etapa indicada no EmConstrucao (05-PLANO-DE-CONSTRUCAO.md)
/// troca o conteúdo desta tela.
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class DetalheDoacaoOngPage extends StatelessWidget {
  const DetalheDoacaoOngPage({
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
    etapa: 3,
    descricao: 'Fotos, dados da doação e o botão Vou retirar.',
  );
}
