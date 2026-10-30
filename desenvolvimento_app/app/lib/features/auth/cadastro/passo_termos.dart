import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';

/// Cadastro, passo 5 — aceite dos Termos de Uso e da Política de
/// Privacidade (LGPD).
class PassoTermos extends StatelessWidget {
  const PassoTermos({super.key, required this.aceitou, required this.aoMudar});

  final bool aceitou;
  final ValueChanged<bool> aoMudar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Quase lá!', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Para criar a conta, leia e aceite como o app usa os seus dados.',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.termos),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Ler os Termos e a Política de Privacidade'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          key: const Key('aceite_termos'),
          value: aceitou,
          onChanged: (marcado) => aoMudar(marcado ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Li e aceito os Termos de Uso e a Política de Privacidade.',
          ),
        ),
      ],
    );
  }
}
