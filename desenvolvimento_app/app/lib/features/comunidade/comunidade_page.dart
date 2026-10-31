import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/routing/app_routes.dart';
import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../data/comunidade/comunidade_repository.dart';
import '../../shared/widgets/estados.dart';
import 'cartao_da_publicacao.dart';
import 'comunidade_view_model.dart';

/// T40 — Comunidade (aba): o painel de impacto de todos, o feed e o botão
/// **Publicar**.
class ComunidadePage extends StatefulWidget {
  const ComunidadePage({
    super.key,
    required this.comunidade,
    required this.sessao,
  });

  final ComunidadeRepository comunidade;
  final Sessao sessao;

  @override
  State<ComunidadePage> createState() => _ComunidadePageState();
}

class _ComunidadePageState extends State<ComunidadePage> {
  late final ComunidadeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ComunidadeViewModel(
      comunidade: widget.comunidade,
      sessao: widget.sessao,
    )..carregar();
    _viewModel.addListener(_mostrarErro);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_mostrarErro);
    _viewModel.dispose();
    super.dispose();
  }

  /// Erro de apoio ou denúncia (com a lista já na tela): aviso embaixo.
  void _mostrarErro() {
    final erro = _viewModel.erro;
    if (erro == null || !_viewModel.carregou || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    _viewModel.limparErro();
  }

  Future<void> _publicar() async {
    final publicou = await Navigator.pushNamed(
      context,
      AppRoutes.novaPublicacao,
    );
    if (publicou == true && mounted) _viewModel.carregar();
  }

  Future<void> _denunciar(Publicacao publicacao) async {
    final motivo = await showDialog<MotivoDenuncia>(
      context: context,
      builder: (contexto) => SimpleDialog(
        title: const Text('Denunciar a publicação'),
        children: [
          for (final motivo in MotivoDenuncia.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(contexto, motivo),
              child: Text(motivo.rotulo),
            ),
        ],
      ),
    );
    if (motivo == null) return;
    final denunciou = await _viewModel.denunciar(publicacao, motivo);
    if (denunciou && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obrigado. A publicação será revisada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidade')),
      // Acima da barra inferior (o corpo da casca passa por trás dela).
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          key: const Key('botao_publicar'),
          onPressed: _publicar,
          icon: const Icon(Icons.edit),
          label: const Text('Publicar'),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (!_viewModel.carregou) {
            final erro = _viewModel.erro;
            return erro == null
                ? const CarregandoWidget()
                : ErroWidget(mensagem: erro, onTentar: _viewModel.carregar);
          }
          return RefreshIndicator(
            onRefresh: _viewModel.carregar,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 180),
              children: [
                if (_viewModel.impacto != null)
                  _PainelDeImpacto(impacto: _viewModel.impacto!),
                for (final publicacao in _viewModel.publicacoes)
                  CartaoDaPublicacao(
                    publicacao: publicacao,
                    minha: _viewModel.ehMinha(publicacao),
                    aoApoiar: () => _viewModel.alternarApoio(publicacao),
                    aoDenunciar: () => _denunciar(publicacao),
                  ),
                if (_viewModel.temMais)
                  Center(
                    child: _viewModel.carregandoMais
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          )
                        : TextButton(
                            onPressed: _viewModel.carregarMais,
                            child: const Text('Ver publicações mais antigas'),
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "1.240 kg de alimento salvos • 312 doações • 890 famílias ajudadas".
/// Reforça os ODS 2 (fome zero) e 12 (consumo responsável).
class _PainelDeImpacto extends StatelessWidget {
  const _PainelDeImpacto({required this.impacto});

  final Impacto impacto;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('painel_impacto'),
      margin: const EdgeInsets.all(16),
      color: AppColors.verde,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            const Text(
              'O impacto de todos',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Numero(Formatador.peso(impacto.kgSalvos), 'salvos'),
                _Numero('${impacto.doacoesConcluidas}', 'doações'),
                _Numero('${impacto.familiasAjudadas}', 'famílias'),
                _Numero('${impacto.refeicoes}', 'refeições'),
              ],
            ),
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
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(rotulo, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}
