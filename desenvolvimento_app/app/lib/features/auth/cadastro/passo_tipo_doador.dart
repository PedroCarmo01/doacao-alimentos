import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import 'passo_tipo_conta.dart';

/// Cadastro, passo 2 (só doador) — tipo de estabelecimento.
///
/// RN02: o tipo decide o documento aceito (feira, produtor rural e "outro"
/// podem usar CPF).
class PassoTipoDoador extends StatelessWidget {
  const PassoTipoDoador({
    super.key,
    required this.selecionado,
    required this.aoEscolher,
  });

  final TipoEstabelecimento? selecionado;
  final ValueChanged<TipoEstabelecimento> aoEscolher;

  static IconData iconeDe(TipoEstabelecimento tipo) => switch (tipo) {
    TipoEstabelecimento.supermercado => Icons.local_grocery_store,
    TipoEstabelecimento.hortifruti => Icons.eco,
    TipoEstabelecimento.feira => Icons.storefront,
    TipoEstabelecimento.padaria => Icons.bakery_dining,
    TipoEstabelecimento.restaurante => Icons.restaurant,
    TipoEstabelecimento.produtorRural => Icons.agriculture,
    TipoEstabelecimento.outro => Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Que tipo de estabelecimento?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        for (final tipo in TipoEstabelecimento.values) ...[
          CartaoDeEscolha(
            key: Key('estabelecimento_${tipo.name}'),
            icone: iconeDe(tipo),
            titulo: tipo.rotulo,
            texto: tipo.aceitaCpf ? 'CNPJ ou CPF' : 'CNPJ',
            selecionado: tipo == selecionado,
            aoTocar: () => aoEscolher(tipo),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
