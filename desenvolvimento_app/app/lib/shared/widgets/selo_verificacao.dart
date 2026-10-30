import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/theme/app_theme.dart';

/// Selo "✓ Verificada" (verde) ou "Verificação pendente" (cinza) — RN03.
///
/// O doador vê este selo antes de entregar a doação. Sempre com TEXTO, não
/// só a cor (acessibilidade).
class SeloVerificacao extends StatelessWidget {
  const SeloVerificacao({super.key, required this.verificacao});

  final Verificacao verificacao;

  @override
  Widget build(BuildContext context) {
    final verificada = verificacao == Verificacao.verificada;
    final cor = verificada ? AppColors.verde : AppColors.cinza;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verificada ? Icons.verified : Icons.hourglass_empty,
            size: 16,
            color: cor,
          ),
          const SizedBox(width: 4),
          Text(
            verificacao.rotulo,
            style: TextStyle(color: cor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
