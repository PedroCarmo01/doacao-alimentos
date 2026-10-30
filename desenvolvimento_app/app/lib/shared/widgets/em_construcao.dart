import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Tela provisória para o que ainda não foi construído.
///
/// Diz o que a tela vai fazer e em qual etapa do plano
/// de construção ela fica pronta.
class EmConstrucao extends StatelessWidget {
  const EmConstrucao({
    super.key,
    required this.titulo,
    required this.etapa,
    required this.descricao,
  });

  final String titulo;

  /// Número da etapa do plano em que a tela fica pronta.
  final int etapa;

  /// O que a tela vai fazer, em uma frase.
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction,
                size: 64,
                color: AppColors.laranja,
              ),
              const SizedBox(height: 16),
              Text(
                'Em construção',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(descricao, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Fica pronta na etapa $etapa.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.cinza),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
