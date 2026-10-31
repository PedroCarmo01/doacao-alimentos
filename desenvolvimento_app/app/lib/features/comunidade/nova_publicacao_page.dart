import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../data/comunidade/comunidade_repository.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/fotos/seletor_de_fotos.dart';
import '../../data/reservas/reserva_repository.dart';
import '../../shared/widgets/aviso.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secao_fotos.dart';
import 'nova_publicacao_view_model.dart';

/// T41 — Nova publicação: texto, até 3 fotos, a doação concluída ligada
/// (opcional), famílias e refeições. Devolve `true` ao publicar.
class NovaPublicacaoPage extends StatefulWidget {
  const NovaPublicacaoPage({
    super.key,
    required this.comunidade,
    required this.doacoes,
    required this.reservas,
    required this.seletor,
    required this.sessao,
    this.doacaoId,
  });

  final ComunidadeRepository comunidade;
  final DoacaoRepository doacoes;
  final ReservaRepository reservas;
  final SeletorDeFotos seletor;
  final Sessao sessao;

  /// Veio do botão "Publicar na Comunidade" de uma retirada concluída.
  final int? doacaoId;

  @override
  State<NovaPublicacaoPage> createState() => _NovaPublicacaoPageState();
}

class _NovaPublicacaoPageState extends State<NovaPublicacaoPage> {
  late final NovaPublicacaoViewModel _viewModel;
  final _texto = TextEditingController();
  final _familias = TextEditingController();
  final _refeicoes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = NovaPublicacaoViewModel(
      comunidade: widget.comunidade,
      doacoes: widget.doacoes,
      reservas: widget.reservas,
      seletor: widget.seletor,
      sessao: widget.sessao,
      doacaoInicial: widget.doacaoId,
    )..carregarOpcoes();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _texto.dispose();
    _familias.dispose();
    _refeicoes.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    final publicou = await _viewModel.publicar(
      texto: _texto.text,
      familias: _familias.text,
      refeicoes: _refeicoes.text,
    );
    if (!mounted) return;
    if (!publicou) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.erro ?? 'Não deu certo.')),
      );
      return;
    }
    final falharam = _viewModel.fotosQueFalharam;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          falharam == 0
              ? 'Publicado na Comunidade!'
              : 'Publicado, mas $falharam foto(s) não foram enviadas.',
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova publicação')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // LGPD e ECA: cuidado com fotos de pessoas.
            const Aviso(
              icone: Icons.privacy_tip_outlined,
              texto:
                  'Não publique rostos de crianças nem de pessoas sem '
                  'autorização. Prefira fotos dos alimentos e das refeições.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('campo_texto_publicacao'),
              controller: _texto,
              maxLength: DadosPublicacao.tamanhoMaximoTexto,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'O que aconteceu com a doação?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            SecaoFotos(
              viewModel: _viewModel,
              dica: 'Prefira fotos dos alimentos e das refeições.',
            ),
            const SizedBox(height: 16),
            _doacaoLigada(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _numero(_familias, 'Famílias ajudadas')),
                const SizedBox(width: 12),
                Expanded(child: _numero(_refeicoes, 'Refeições')),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Opcional. Os números somam no painel de impacto.',
              style: TextStyle(color: AppColors.cinza, fontSize: 12),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              key: const Key('botao_enviar_publicacao'),
              texto: 'Publicar',
              carregando: _viewModel.ocupado,
              onPressed: _publicar,
            ),
          ],
        ),
      ),
    );
  }

  /// "Ligar a uma doação concluída" (opcional).
  Widget _doacaoLigada() {
    return DropdownButtonFormField<int?>(
      key: const Key('doacao_ligada'),
      initialValue: _viewModel.doacaoId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Ligar a uma doação concluída (opcional)',
      ),
      items: [
        const DropdownMenuItem<int?>(child: Text('Nenhuma')),
        for (final opcao in _viewModel.opcoes)
          DropdownMenuItem<int?>(
            value: opcao.doacaoId,
            child: Text(opcao.titulo, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: _viewModel.escolherDoacao,
    );
  }

  Widget _numero(TextEditingController controle, String rotulo) => TextField(
    controller: controle,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: rotulo),
  );
}
