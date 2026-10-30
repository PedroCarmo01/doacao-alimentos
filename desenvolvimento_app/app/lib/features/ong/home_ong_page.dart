import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_routes.dart';
import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/perfil/perfil_repository.dart';
import '../../shared/widgets/aviso.dart';
import '../../shared/widgets/doacao_card.dart';
import '../../shared/widgets/estados.dart';
import 'home_ong_view_model.dart';

/// T20 — Início da ONG ("Doações perto de você"): busca ativa, raio e a
/// lista da mais perto para a mais longe. Atualiza sozinha a cada 15 s.
class HomeOngPage extends StatefulWidget {
  const HomeOngPage({
    super.key,
    required this.doacoes,
    required this.perfis,
    required this.sessao,
    required this.relogio,
  });

  final DoacaoRepository doacoes;
  final PerfilRepository perfis;
  final Sessao sessao;
  final Relogio relogio;

  @override
  State<HomeOngPage> createState() => _HomeOngPageState();
}

class _HomeOngPageState extends State<HomeOngPage> {
  late final HomeOngViewModel _viewModel;
  Timer? _relogioDaTela;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeOngViewModel(
      doacoes: widget.doacoes,
      perfis: widget.perfis,
      sessao: widget.sessao,
      relogio: widget.relogio,
    );
    _viewModel.carregar();
    // ADR-008: consulta a cada 15 s em vez de conexão aberta (WebSocket).
    _relogioDaTela = Timer.periodic(
      AppConfig.intervaloAtualizacao,
      (_) => _viewModel.atualizarEmSilencio(),
    );
  }

  @override
  void dispose() {
    _relogioDaTela?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _abrir(Doacao doacao) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.detalheDoacaoOng,
      arguments: doacao.id,
    );
    if (mounted) _viewModel.carregar();
  }

  Future<void> _escolherRaio() async {
    final escolhido = await showModalBottomSheet<double>(
      context: context,
      builder: (contexto) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Buscar doações até:')),
            for (final km in ValidadorUsuario.raiosPermitidosKm)
              ListTile(
                leading: Icon(
                  km == _viewModel.raioKm
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.verde,
                ),
                title: Text('${km.toStringAsFixed(0)} km'),
                onTap: () => Navigator.pop(contexto, km),
              ),
          ],
        ),
      ),
    );
    if (escolhido != null) await _viewModel.mudarRaio(escolhido);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doações perto de você'),
        actions: [
          IconButton(
            key: const Key('minhas_retiradas'),
            tooltip: 'Minhas retiradas',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.minhasReservas),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Column(
          children: [
            if (_viewModel.suspensaAte != null)
              _FaixaSuspensa(ate: _viewModel.suspensaAte!),
            _BuscaAtiva(viewModel: _viewModel, aoAlterarRaio: _escolherRaio),
            Expanded(child: _lista()),
          ],
        ),
      ),
    );
  }

  /// Os 4 estados de uma lista: carregando, erro, vazio e com dados.
  Widget _lista() {
    final vm = _viewModel;
    if (!vm.carregou) {
      final erro = vm.erro;
      return erro == null
          ? const CarregandoWidget()
          : ErroWidget(mensagem: erro, onTentar: vm.carregar);
    }
    return RefreshIndicator(
      onRefresh: vm.carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          if (vm.doacoes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: VazioWidget(
                icone: Icons.search_off,
                texto:
                    'Nenhuma doação disponível até '
                    '${vm.raioKm.toStringAsFixed(0)} km agora.\n'
                    'Puxe para atualizar ou aumente o raio.',
              ),
            ),
          for (final doacao in vm.doacoes)
            DoacaoCard(
              doacao: doacao,
              agora: vm.agora,
              novidade: vm.ehNova(doacao),
              onTap: () => _abrir(doacao),
            ),
        ],
      ),
    );
  }
}

/// Interruptor grande "Busca ativa" e o raio, com o "alterar".
class _BuscaAtiva extends StatelessWidget {
  const _BuscaAtiva({required this.viewModel, required this.aoAlterarRaio});

  final HomeOngViewModel viewModel;
  final VoidCallback aoAlterarRaio;

  @override
  Widget build(BuildContext context) {
    final ligada = viewModel.buscaAtiva;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('busca_ativa'),
            value: ligada,
            onChanged: viewModel.ocupado ? null : viewModel.mudarBuscaAtiva,
            title: Text(
              ligada ? 'Busca ativa' : 'Busca desligada',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              ligada
                  ? 'Você recebe avisos de doações novas.'
                  : 'Você continua vendo a lista, mas não recebe avisos.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.radar, color: AppColors.verde),
            title: Text('Até ${viewModel.raioKm.toStringAsFixed(0)} km'),
            trailing: TextButton(
              key: const Key('alterar_raio'),
              onPressed: viewModel.ocupado ? null : aoAlterarRaio,
              child: const Text('Alterar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// RN24 — faixa vermelha no topo enquanto a ONG está suspensa.
class _FaixaSuspensa extends StatelessWidget {
  const _FaixaSuspensa({required this.ate});

  final DateTime ate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Aviso(
      key: const Key('faixa_suspensa'),
      cor: AppColors.erro,
      icone: Icons.block,
      texto:
          'Você está suspensa até ${Formatador.diaHora(ate)} por '
          'desistências. Ainda pode ver as doações, mas não pode aceitar.',
    ),
  );
}
