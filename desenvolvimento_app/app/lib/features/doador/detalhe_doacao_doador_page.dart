import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../shared/widgets/estados.dart';
import '../../shared/widgets/etiqueta_status.dart';
import '../../shared/widgets/primary_button.dart';
import 'detalhe_doacao_doador_view_model.dart';
import '../../shared/widgets/detalhe_da_doacao.dart';
import 'partes_do_detalhe.dart';

/// T12 — Detalhe da doação (doador): fotos, dados, linha do tempo, a ONG
/// que vem buscar e as ações (editar, cancelar). A confirmação da retirada
/// com o código entra na etapa 4 e o chat na etapa 6.
class DetalheDoacaoDoadorPage extends StatefulWidget {
  const DetalheDoacaoDoadorPage({
    super.key,
    required this.doacaoId,
    required this.doacoes,
    required this.relogio,
  });

  final int doacaoId;
  final DoacaoRepository doacoes;
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
          appBar: AppBar(title: Text(detalhe?.doacao.titulo ?? 'Doação')),
          body: detalhe == null
              ? _semDados()
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(child: _conteudo(detalhe)),
                      _acoes(detalhe.doacao),
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
  Widget _acoes(Doacao doacao) {
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
          else
            const Text(
              'A ONG está a caminho. A confirmação com o código de retirada '
              'entra na etapa 4.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.cinza),
            ),
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
