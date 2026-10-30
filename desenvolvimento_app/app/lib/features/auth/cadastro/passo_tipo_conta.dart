import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/theme/app_theme.dart';

/// Cadastro, passo 1 — "Quem é você?": dois cartões grandes (RN01).
class PassoTipoConta extends StatelessWidget {
  const PassoTipoConta({
    super.key,
    required this.selecionado,
    required this.aoEscolher,
  });

  final TipoUsuario? selecionado;
  final ValueChanged<TipoUsuario> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Quem é você?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Cada conta é de um tipo só. Escolha o seu.'),
        const SizedBox(height: 24),
        CartaoDeEscolha(
          key: const Key('escolha_ong'),
          icone: Icons.groups,
          titulo: 'Sou ONG',
          texto:
              'Recebo doações para pessoas atendidas pela minha '
              'organização.',
          selecionado: selecionado == TipoUsuario.ong,
          aoTocar: () => aoEscolher(TipoUsuario.ong),
        ),
        const SizedBox(height: 16),
        CartaoDeEscolha(
          key: const Key('escolha_doador'),
          icone: Icons.storefront,
          titulo: 'Sou doador',
          texto: 'Tenho alimentos sobrando no meu estabelecimento.',
          selecionado: selecionado == TipoUsuario.doador,
          aoTocar: () => aoEscolher(TipoUsuario.doador),
        ),
      ],
    );
  }
}

/// Cartão grande e tocável, com ícone, título e explicação.
class CartaoDeEscolha extends StatelessWidget {
  const CartaoDeEscolha({
    super.key,
    required this.icone,
    required this.titulo,
    required this.aoTocar,
    this.texto,
    this.selecionado = false,
  });

  final IconData icone;
  final String titulo;
  final String? texto;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionado,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selecionado ? AppColors.verde : const Color(0xFFE0E0E0),
            width: selecionado ? 2 : 1,
          ),
        ),
        color: selecionado ? AppColors.verdeClaro : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icone, size: 40, color: AppColors.verde),
                const SizedBox(width: 16),
                Expanded(child: _textos(context)),
                const Icon(Icons.chevron_right, color: AppColors.cinza),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textos(BuildContext context) {
    final explicacao = texto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        if (explicacao != null) ...[
          const SizedBox(height: 4),
          Text(explicacao, style: const TextStyle(color: AppColors.cinza)),
        ],
      ],
    );
  }
}
