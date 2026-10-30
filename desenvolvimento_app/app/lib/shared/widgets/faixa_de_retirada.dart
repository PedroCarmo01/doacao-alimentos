import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A faixa laranja fixa no topo: "Retirada em andamento • 42:10
/// restantes • Ver". A área inteira é tocável (altura mínima de 48 dp).
class FaixaDeRetirada extends StatelessWidget {
  const FaixaDeRetirada({
    super.key,
    required this.texto,
    required this.aoTocar,
  });

  final String texto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.laranja,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          key: const Key('faixa_retirada'),
          onTap: aoTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      texto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
                    'Ver',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
