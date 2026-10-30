import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Caixa de aviso com ícone e texto (ex.: "Sua sessão expirou").
///
/// Acessibilidade: a informação está no TEXTO, a cor é só um reforço.
class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.texto,
    this.icone = Icons.info_outline,
    this.cor = AppColors.laranja,
  });

  final String texto;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
