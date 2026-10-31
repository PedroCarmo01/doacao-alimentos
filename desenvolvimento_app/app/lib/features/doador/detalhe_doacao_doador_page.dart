import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/reservas/reserva_repository.dart';
import '../../shared/widgets/estados.dart';
import '../../shared/widgets/etiqueta_status.dart';
import '../../shared/widgets/primary_button.dart';
import 'detalhe_doacao_doador_view_model.dart';
import '../../shared/widgets/detalhe_da_doacao.dart';
import 'partes_do_detalhe.dart';

/// T12 — Detalhe da doação (doador): fotos, dados, linha do tempo, a ONG
/// que vem buscar e as ações (editar, cancelar, confirmar a retirada com o
/// código e "A ONG não compareceu"). O chat entra na etapa 6.
class DetalheDoacaoDoadorPage extends StatefulWidget {
  const DetalheDoacaoDoadorPage({
    super.key,
    required this.doacaoId,
    required this.doacoes,
    required this.reservas,
    required this.relogio,
  });

  final int doacaoId;
  final DoacaoRepository doacoes;
  final ReservaRepository reservas;
  final Relogio relogio;

  @override
  State<DetalheDoacaoDoadorPage> createState() =>
      _DetalheDoacaoDoadorPageState();
}

class _DetalheDoacaoDoadorPageState extends State<DetalheDoacaoDoadorPage> {
  late final DetalheDoacaoDoadorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DetalheDoacaoDoadorViewModel(
      doacoes: widget.doacoes,
      reservas: widget.reservas,
      relogio: widget.relogio,
      doacaoId: widget.doacaoId,
    );
    _viewModel.carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _editar() async {
    final salvou = await Navigator.pushNamed(
      context,
      AppRoutes.novaDoacao,
      arguments: widget.doacaoId,
    );
    if (salvou == true && mounted) _viewModel.carregar();
  }

  /// T13: o doador digita o código da ONG.
  Future<void> _confirmarRetirada(Reserva reserva) async {
    final confirmou = await Navigator.pushNamed(
      context,
      AppRoutes.confirmarRetirada,
      arguments: reserva.id,
    );
    if (confirmou == true && mounted) _viewModel.carregar();
  }

  /// RN28: depois do prazo, a doação volta para outras ONGs.
  Future<void> _naoCompareceu() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('A ONG não compareceu?'),
        content: const Text(
          'A doação volta a ficar disponível para outras ONGs e isso conta '
          'como desistência para esta ONG.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    final deu = await _viewModel.marcarNaoCompareceu();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deu
              ? 'A doação está disponível de novo.'
              : (_viewModel.erro ?? 'Não deu certo.'),
        ),
      ),
    );
    if (!deu) _viewModel.carregar(); // o servidor pode ter expirado antes
  }

  /// Ação perigosa: sempre confirma. Se reservada, pede o motivo (RN12).
  Future<void> _cancelar(Doacao doacao) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) =>
          _DialogoCancelamento(pedeMotivo: doacao.cancelamentoExigeMotivo),
    );
    if (motivo == null || !mounted) return;
    final cancelou = await _viewModel.cancelar(
      motivo: motivo.isEmpty ? null : motivo,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cancelou
              ? 'Doação cancelada.'
              : (_viewModel.erro ?? 'Não deu certo.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final detalhe = _viewModel.detalhe;
        return Scaffold(
          appBar: AppBar(
            title: Text(detalhe?.doacao.titulo ?? 'Doação'),
            actions: [
              // Menu com "A ONG não compareceu", só depois do prazo (RN28).
              if (_viewModel.podeMarcarNaoCompareceu)
                PopupMenuButton<void>(
                  key: const Key('menu_detalhe'),
                  itemBuilder: (_) => [
                    PopupMenuItem<void>(
                      onTap: _naoCompareceu,
                      child: const Text('A ONG não compareceu'),
                    ),
                  ],
                ),
            ],
          ),
          body: detalhe == null
              ? _semDados()
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(child: _conteudo(detalhe)),
                      _acoes(detalhe),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _semDados() {
    final erro = _viewModel.erro;
    if (erro == null) return const CarregandoWidget();
    return ErroWidget(mensagem: erro, onTentar: _viewModel.carregar);
  }

  Widget _conteudo(DetalheDoacao detalhe) {
    final doacao = detalhe.doacao;
    final ong = detalhe.ong;
    final motivo = doacao.motivoCancelamento;
    return ListView(
      children: [
        GaleriaDeFotos(doacao: doacao),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      doacao.titulo,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Etiqueta.doStatus(doacao.status),
                ],
              ),
              const SizedBox(height: 12),
              LinhaDoTempo(detalhe: detalhe, agora: _viewModel.agora),
              if (ong != null) ...[
                const SizedBox(height: 12),
                CartaoDaOng(ong: ong),
              ],
              if (motivo != null) ...[
                const SizedBox(height: 12),
                Text('Motivo do cancelamento: $motivo'),
              ],
              const Divider(height: 32),
              DadosDaDoacao(doacao: doacao),
            ],
          ),
        ),
      ],
    );
  }

  /// Botões fixos embaixo, conforme o status (T12).
  Widget _acoes(DetalheDoacao detalhe) {
    final doacao = detalhe.doacao;
    final reserva = detalhe.reserva;
    if (!doacao.podeSerCancelada) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (doacao.podeSerEditada)
            PrimaryButton(
              key: const Key('botao_editar'),
              texto: 'Editar',
              carregando: _viewModel.ocupado,
              onPressed: _editar,
            )
          else if (reserva != null) ...[
            PrimaryButton(
              key: const Key('botao_confirmar_retirada'),
              texto: 'Confirmar retirada',
              onPressed: () => _confirmarRetirada(reserva),
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
              label: const Text('Conversar com a ONG'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
          // Ação perigosa: pequena, vermelha e longe da principal.
          TextButton(
            key: const Key('botao_cancelar'),
            onPressed: _viewModel.ocupado ? null : () => _cancelar(doacao),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.erro,
              minimumSize: const Size(48, 48),
            ),
            child: const Text('Cancelar doação'),
          ),
        ],
      ),
    );
  }
}

/// Confirma o cancelamento. Devolve o motivo ('' se não pediu) ou `null`
/// se a pessoa desistiu de cancelar.
class _DialogoCancelamento extends StatefulWidget {
  const _DialogoCancelamento({required this.pedeMotivo});

  final bool pedeMotivo;

  @override
  State<_DialogoCancelamento> createState() => _DialogoCancelamentoState();
}

class _DialogoCancelamentoState extends State<_DialogoCancelamento> {
  final _motivo = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (widget.pedeMotivo) {
      final erro = ValidadorDoacao.motivoCancelamento(_motivo.text);
      if (erro != null) {
        setState(() => _erro = erro);
        return;
      }
    }
    Navigator.pop(context, _motivo.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar a doação?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.pedeMotivo
                ? 'Uma ONG já aceitou. Ela será avisada do motivo e não será '
                      'penalizada.'
                : 'As ONGs deixam de ver esta doação.',
          ),
          if (widget.pedeMotivo)
            TextField(
              key: const Key('campo_motivo'),
              controller: _motivo,
              maxLength: ValidadorDoacao.tamanhoMaximoMotivo,
              decoration: InputDecoration(
                labelText: 'Motivo',
                errorText: _erro,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar'),
        ),
        TextButton(
          onPressed: _confirmar,
          style: TextButton.styleFrom(foregroundColor: AppColors.erro),
          child: const Text('Cancelar doação'),
        ),
      ],
    );
  }
}
