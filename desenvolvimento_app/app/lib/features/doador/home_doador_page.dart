import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/routing/app_routes.dart';
import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../shared/widgets/doacao_card.dart';
import '../../shared/widgets/estados.dart';
import 'home_doador_view_model.dart';

/// T10 — Início do doador ("Minhas doações"): resumo do impacto e as abas
/// Ativas (disponível/reservada) e Histórico (concluída/cancelada/expirada).
class HomeDoadorPage extends StatefulWidget {
  const HomeDoadorPage({
    super.key,
    required this.doacoes,
    required this.sessao,
    required this.relogio,
  });

  final DoacaoRepository doacoes;
  final Sessao sessao;
  final Relogio relogio;

  @override
  State<HomeDoadorPage> createState() => _HomeDoadorPageState();
}

class _HomeDoadorPageState extends State<HomeDoadorPage> {
  late final HomeDoadorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeDoadorViewModel(
      doacoes: widget.doacoes,
      sessao: widget.sessao,
      relogio: widget.relogio,
    );
    _viewModel.carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _abrir(Doacao doacao) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.detalheDoacaoDoador,
      arguments: doacao.id,
    );
    // Na volta, a doação pode ter sido editada ou cancelada.
    if (mounted) _viewModel.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas doações'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Ativas'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => _corpo(),
        ),
      ),
    );
  }

  /// Os 4 estados de uma lista: carregando, erro, vazio e com dados.
  Widget _corpo() {
    final vm = _viewModel;
    if (!vm.carregou) {
      final erro = vm.erro;
      if (erro != null) {
        return ErroWidget(mensagem: erro, onTentar: vm.carregar);
      }
      return const CarregandoWidget();
    }
    return TabBarView(
      children: [
        _lista(
          vm.ativas,
          vazio:
              'Você ainda não tem doações ativas. Toque em Doar para '
              'começar.',
        ),
        _lista(vm.historico, vazio: 'As doações encerradas aparecem aqui.'),
      ],
    );
  }

  Widget _lista(List<Doacao> doacoes, {required String vazio}) {
    return RefreshIndicator(
      onRefresh: _viewModel.carregar,
      child: ListView(
        // AlwaysScrollable: dá para "puxar para atualizar" até com a lista
        // vazia. O espaço embaixo é para a barra inferior não cobrir nada.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          _Resumo(viewModel: _viewModel),
          if (doacoes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: VazioWidget(texto: vazio, icone: Icons.volunteer_activism),
            ),
          for (final doacao in doacoes)
            DoacaoCard(
              doacao: doacao,
              agora: _viewModel.agora,
              onTap: () => _abrir(doacao),
            ),
        ],
      ),
    );
  }
}

/// "Olá, Mercado Bom Preço" e "2 doações • 70 kg salvos".
class _Resumo extends StatelessWidget {
  const _Resumo({required this.viewModel});

  final HomeDoadorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final total = viewModel.totalConcluidas;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.verdeClaro,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: AppColors.verde, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${viewModel.nomeOrganizacao}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '$total ${total == 1 ? 'doação entregue' : 'doações entregues'}'
                  ' • ${Formatador.peso(viewModel.kgSalvos)} salvos',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
