import 'package:flutter/material.dart';

import '../../core/routing/app_routes.dart';
import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';

/// Tela provisória do Sprint 0 (walking skeleton).
///
/// Cada placeholder diz quem é o responsável e qual etapa da trilha tem o
/// passo a passo. Quando a pessoa implementar a tela de verdade, este widget
/// deixa de ser usado naquele arquivo.
class EmConstrucao extends StatelessWidget {
  const EmConstrucao({
    super.key,
    required this.titulo,
    required this.responsavel,
    required this.etapa,
    this.sessao,
  });

  final String titulo;
  final String responsavel;
  final String etapa;

  /// Se informado, mostra o botão "Sair" (telas iniciais de cada perfil).
  final Sessao? sessao;

  Future<void> _sair(BuildContext context) async {
    await sessao?.encerrar();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.inicio, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          if (sessao != null)
            IconButton(
              tooltip: 'Sair',
              icon: const Icon(Icons.logout),
              onPressed: () => _sair(context),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 64, color: AppColors.laranja),
              const SizedBox(height: 16),
              Text(
                'Tela em construção',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Responsável: $responsavel', textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Passo a passo: $etapa',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.cinza),
              ),
              if (sessao?.usuario != null) ...[
                const SizedBox(height: 16),
                Text('Logado como ${sessao!.usuario!.email}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
