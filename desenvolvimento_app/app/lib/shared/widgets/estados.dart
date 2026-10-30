import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Spinner central para o estado de carregamento.
class CarregandoWidget extends StatelessWidget {
  const CarregandoWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Estado de erro com mensagem e botão opcional "Tentar novamente".
class ErroWidget extends StatelessWidget {
  const ErroWidget({super.key, required this.mensagem, this.onTentar});

  final String mensagem;
  final VoidCallback? onTentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.erro),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            if (onTentar != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onTentar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vazio (lista sem itens).
class VazioWidget extends StatelessWidget {
  const VazioWidget({super.key, required this.texto, this.icone});

  final String texto;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone ?? Icons.inbox_outlined,
              size: 56,
              color: AppColors.cinza,
            ),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.cinza),
            ),
          ],
        ),
      ),
    );
  }
}
