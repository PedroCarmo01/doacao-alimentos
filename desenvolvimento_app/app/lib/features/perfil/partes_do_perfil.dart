import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import 'perfil_view_model.dart';

/// Pedaços da tela T50, separados para a página ficar curta.

/// Os números do Perfil: doador → doações e kg; ONG → retiradas, kg,
/// comparecimento e desistências (RN24).
class CartaoDeEstatisticas extends StatelessWidget {
  const CartaoDeEstatisticas({
    super.key,
    required this.estatisticas,
    required this.ehOng,
  });

  final EstatisticasDoPerfil estatisticas;
  final bool ehOng;

  @override
  Widget build(BuildContext context) {
    final e = estatisticas;
    final comparecimento = e.comparecimento;
    return Card(
      key: const Key('estatisticas'),
      color: AppColors.verdeClaro,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _Numero('${e.concluidas}', ehOng ? 'retiradas' : 'doações'),
            _Numero(Formatador.peso(e.kg), ehOng ? 'recebidos' : 'doados'),
            if (ehOng) ...[
              _Numero(
                comparecimento == null
                    ? '—'
                    : '${(comparecimento * 100).round()}%',
                'compareceu',
              ),
              _Numero(
                '${e.desistenciasRecentes ?? 0}',
                'desistências\n(30 dias)',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero(this.valor, this.rotulo);

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.verde,
          ),
        ),
        Text(
          rotulo,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.cinza, fontSize: 12),
        ),
      ],
    ),
  );
}

/// ONG: busca ativa e raio (os mesmos do Início, salvos no perfil).
class CartaoDaBusca extends StatelessWidget {
  const CartaoDaBusca({super.key, required this.viewModel});

  final PerfilViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final perfil = viewModel.conta!.perfil;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            key: const Key('perfil_busca_ativa'),
            value: perfil.buscaAtiva,
            onChanged: viewModel.ocupado ? null : viewModel.mudarBuscaAtiva,
            title: const Text('Busca ativa'),
            subtitle: const Text('Receber avisos de doações perto de você.'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final km in PerfilViewModel.raios)
                  ChoiceChip(
                    label: Text('${km.toStringAsFixed(0)} km'),
                    selected: perfil.raioKm == km,
                    onSelected: viewModel.ocupado
                        ? null
                        : (_) => viewModel.mudarRaio(km),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// T50: ligar/desligar os avisos por tipo. Os da retirada (aceite, prazo,
/// código) chegam sempre.
class CartaoDosAvisos extends StatelessWidget {
  const CartaoDosAvisos({super.key, required this.viewModel});

  final PerfilViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final a = viewModel.avisos;
    void mudar({bool? doacoes, bool? mensagens, bool? comunidade}) =>
        viewModel.mudarAvisos(
          PreferenciasDeAviso(
            doacoes: doacoes ?? a.doacoes,
            mensagens: mensagens ?? a.mensagens,
            comunidade: comunidade ?? a.comunidade,
          ),
        );
    final ocupado = viewModel.ocupado;
    return Card(
      child: Column(
        children: [
          if (viewModel.ehOng)
            SwitchListTile(
              key: const Key('aviso_doacoes'),
              value: a.doacoes,
              onChanged: ocupado ? null : (v) => mudar(doacoes: v),
              title: const Text('Doações novas perto'),
            ),
          SwitchListTile(
            key: const Key('aviso_mensagens'),
            value: a.mensagens,
            onChanged: ocupado ? null : (v) => mudar(mensagens: v),
            title: const Text('Mensagens do chat'),
          ),
          SwitchListTile(
            key: const Key('aviso_comunidade'),
            value: a.comunidade,
            onChanged: ocupado ? null : (v) => mudar(comunidade: v),
            title: const Text('Apoios nas minhas publicações'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Os avisos da retirada (aceite, prazo e confirmação) chegam '
              'sempre.',
              style: TextStyle(color: AppColors.cinza, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
