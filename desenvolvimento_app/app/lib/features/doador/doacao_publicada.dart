import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/aviso.dart';
import '../../shared/widgets/primary_button.dart';

/// T11 — tela de sucesso: "Doação publicada! 7 ONGs próximas foram
/// avisadas." O número vem do servidor (RN11; os avisos começam na etapa 5).
class DoacaoPublicada extends StatelessWidget {
  const DoacaoPublicada({
    super.key,
    required this.ongsAvisadas,
    this.fotosQueFalharam = 0,
  });

  final int ongsAvisadas;
  final int fotosQueFalharam;

  String get _textoDosAvisos => switch (ongsAvisadas) {
    0 => 'As ONGs próximas já podem vê-la na lista de doações.',
    1 => '1 ONG próxima foi avisada.',
    _ => '$ongsAvisadas ONGs próximas foram avisadas.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 56,
                backgroundColor: AppColors.verdeClaro,
                child: Icon(Icons.check, size: 64, color: AppColors.verde),
              ),
              const SizedBox(height: 24),
              Text(
                'Doação publicada!',
                key: const Key('doacao_publicada'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _textoDosAvisos,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (fotosQueFalharam > 0) ...[
                const SizedBox(height: 16),
                Aviso(
                  texto:
                      '$fotosQueFalharam foto(s) não foram enviadas. Abra a '
                      'doação e use "Editar" para tentar de novo.',
                ),
              ],
              const Spacer(),
              PrimaryButton(
                texto: 'Ver minhas doações',
                // `true` avisa a tela anterior que algo mudou.
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
