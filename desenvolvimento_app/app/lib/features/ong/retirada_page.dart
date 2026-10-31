import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/rota_no_mapa.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/reservas/reserva_repository.dart';
import '../../shared/widgets/estados.dart';
import 'partes_da_retirada.dart';
import 'retirada_view_model.dart';

/// T23 — Retirada em andamento (ONG): contador regressivo, o código em
/// destaque, endereço com **Como chegar**, **Ligar** e, longe dos outros
/// botões, **Desistir da retirada**.
class RetiradaPage extends StatefulWidget {
  const RetiradaPage({
    super.key,
    required this.reservaId,
    required this.reservas,
    required this.doacoes,
    required this.relogio,
  });

  final int reservaId;
  final ReservaRepository reservas;
  final DoacaoRepository doacoes;
  final Relogio relogio;

  @override
  State<RetiradaPage> createState() => _RetiradaPageState();
}

class _RetiradaPageState extends State<RetiradaPage> {
  late final RetiradaViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RetiradaViewModel(
      reservas: widget.reservas,
      doacoes: widget.doacoes,
      relogio: widget.relogio,
      reservaId: widget.reservaId,
    )..iniciarContadores();
    _viewModel.carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Abre outro app (mapas ou telefone). Se não houver, avisa.
  Future<void> _abrir(Uri endereco, String semApp) async {
    final abriu = await launchUrl(
      endereco,
      mode: LaunchMode.externalApplication,
    );
    if (!abriu && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(semApp)));
    }
  }

  /// Ação perigosa: sempre confirma e explica se vai contar (RN23).
  Future<void> _desistir() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Desistir da retirada?'),
        content: Text(_viewModel.avisoDaDesistencia),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Continuar retirando'),
          ),
          TextButton(
            key: const Key('confirmar_desistencia'),
            onPressed: () => Navigator.pop(contexto, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.erro),
            child: const Text('Desistir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    final deu = await _viewModel.desistir();
    if (!deu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.erro ?? 'Não deu certo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retirada')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final reserva = _viewModel.reserva;
          if (reserva == null) {
            final erro = _viewModel.erro;
            return erro == null
                ? const CarregandoWidget()
                : ErroWidget(mensagem: erro, onTentar: _viewModel.carregar);
          }
          if (!reserva.estaAtiva) {
            return RetiradaEncerrada(
              reserva: reserva,
              desistencia: _viewModel.desistencia,
              aoContarNaComunidade: () => Navigator.pushNamed(
                context,
                AppRoutes.novaPublicacao,
                arguments: reserva.doacaoId,
              ),
            );
          }
          return SafeArea(child: _emAndamento(reserva));
        },
      ),
    );
  }

  Widget _emAndamento(Reserva reserva) {
    final detalhe = _viewModel.detalhe;
    final telefone = detalhe?.doador?.telefone;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Contador(restante: _viewModel.restante),
        const SizedBox(height: 16),
        CodigoDeRetirada(codigo: reserva.codigoRetirada ?? '----'),
        const SizedBox(height: 16),
        if (detalhe != null) ...[
          EnderecoDaRetirada(detalhe: detalhe),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _abrir(
              RotaNoMapa.para(detalhe.doacao.coordenadas),
              'Não achamos um app de mapas neste celular.',
            ),
            icon: const Icon(Icons.directions),
            label: const Text('Como chegar'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: telefone == null
                ? null
                : () => _abrir(
                    Uri(scheme: 'tel', path: telefone),
                    'Não foi possível abrir o telefone.',
                  ),
            icon: const Icon(Icons.call),
            label: const Text('Ligar para o doador'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('conversar'),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.chat,
              arguments: reserva.id,
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Conversar com o doador'),
          ),
        ],
        // Ação perigosa: pequena, vermelha e longe das outras.
        const SizedBox(height: 48),
        Center(
          child: TextButton(
            key: const Key('desistir'),
            onPressed: _viewModel.ocupado ? null : _desistir,
            style: TextButton.styleFrom(foregroundColor: AppColors.erro),
            child: const Text('Desistir da retirada'),
          ),
        ),
      ],
    );
  }
}
