import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../data/reservas/reserva_repository.dart';
import '../../shared/widgets/aviso.dart';
import '../../shared/widgets/estados.dart';
import 'minhas_reservas_view_model.dart';

/// Minhas retiradas (ONG): abas "Em andamento" e "Histórico", com a
/// contagem de desistências dos últimos 30 dias (RN24).
class MinhasReservasPage extends StatefulWidget {
  const MinhasReservasPage({
    super.key,
    required this.reservas,
    required this.relogio,
  });

  final ReservaRepository reservas;
  final Relogio relogio;

  @override
  State<MinhasReservasPage> createState() => _MinhasReservasPageState();
}

class _MinhasReservasPageState extends State<MinhasReservasPage> {
  late final MinhasReservasViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MinhasReservasViewModel(
      reservas: widget.reservas,
      relogio: widget.relogio,
    );
    _viewModel.carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _abrir(Reserva reserva) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.retirada,
      arguments: reserva.id,
    );
    if (mounted) _viewModel.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas retiradas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Em andamento'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final situacao = _viewModel.situacao;
            if (situacao == null) {
              final erro = _viewModel.erro;
              return erro == null
                  ? const CarregandoWidget()
                  : ErroWidget(mensagem: erro, onTentar: _viewModel.carregar);
            }
            return Column(
              children: [
                _Desistencias(situacao: situacao),
                Expanded(
                  child: TabBarView(
                    children: [
                      _lista(_viewModel.ativas, 'Nenhuma retirada agora.'),
                      _lista(_viewModel.historico, 'Nenhuma retirada ainda.'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _lista(List<Reserva> reservas, String vazio) {
    if (reservas.isEmpty) {
      return VazioWidget(icone: Icons.inventory_2_outlined, texto: vazio);
    }
    return RefreshIndicator(
      onRefresh: _viewModel.carregar,
      child: ListView(
        children: [
          for (final reserva in reservas)
            reserva.estaAtiva
                ? ListTile(
                    leading: const Icon(Icons.timer, color: AppColors.laranja),
                    title: Text(reserva.tituloDoacao ?? 'Doação'),
                    subtitle: Text(
                      'Faltam ${Formatador.duracaoCurta(reserva.tempoRestante(_viewModel.agora))}'
                      ' • código ${reserva.codigoRetirada ?? '----'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrir(reserva),
                  )
                : ListTile(
                    leading: Icon(
                      reserva.status == StatusReserva.concluida
                          ? Icons.check_circle
                          : Icons.cancel_outlined,
                      color: reserva.status == StatusReserva.concluida
                          ? AppColors.verde
                          : AppColors.cinza,
                    ),
                    title: Text(reserva.tituloDoacao ?? 'Doação'),
                    subtitle: Text(
                      '${reserva.status.rotulo} • '
                      '${Formatador.diaHora(reserva.encerradaEm ?? reserva.reservadoEm)}'
                      '${reserva.contouDesistencia ? '\nContou como desistência' : ''}',
                    ),
                  ),
        ],
      ),
    );
  }
}

/// RN24: "2 de 3 desistências nos últimos 30 dias" e o aviso da próxima.
class _Desistencias extends StatelessWidget {
  const _Desistencias({required this.situacao});

  final SituacaoDaOng situacao;

  @override
  Widget build(BuildContext context) {
    final regras = situacao.regras;
    final texto =
        'Desistências nos últimos ${regras.janelaDesistencias.inDays} dias: '
        '${situacao.desistenciasRecentes} de '
        '${regras.desistenciasParaSuspender}.';
    if (!situacao.proximaDesistenciaSuspende) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(texto, style: const TextStyle(color: AppColors.cinza)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Aviso(
        key: const Key('aviso_suspensao'),
        cor: AppColors.laranja,
        icone: Icons.warning_amber,
        texto:
            '$texto Mais uma desistência e sua conta será suspensa por '
            '${regras.suspensao.inHours} h.',
      ),
    );
  }
}
