import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../core/utils/rota_no_mapa.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../shared/widgets/detalhe_da_doacao.dart';
import '../../shared/widgets/estados.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/selo_verificacao.dart';
import 'detalhe_doacao_ong_view_model.dart';

/// T22 — Detalhe da doação (ONG): fotos, dados, distância, o doador com o
/// selo de verificação e **Como chegar**. O botão "Vou retirar" funciona a
/// partir da etapa 4.
class DetalheDoacaoOngPage extends StatefulWidget {
  const DetalheDoacaoOngPage({
    super.key,
    required this.doacaoId,
    required this.doacoes,
    required this.sessao,
    required this.relogio,
  });

  final int doacaoId;
  final DoacaoRepository doacoes;
  final Sessao sessao;
  final Relogio relogio;

  @override
  State<DetalheDoacaoOngPage> createState() => _DetalheDoacaoOngPageState();
}

class _DetalheDoacaoOngPageState extends State<DetalheDoacaoOngPage> {
  late final DetalheDoacaoOngViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DetalheDoacaoOngViewModel(
      doacoes: widget.doacoes,
      sessao: widget.sessao,
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

  /// Abre o Google Maps (ou outro app de mapas) com a rota até a doação.
  Future<void> _comoChegar(Doacao doacao) async {
    final abriu = await launchUrl(
      RotaNoMapa.para(doacao.coordenadas),
      mode: LaunchMode.externalApplication,
    );
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não achamos um app de mapas neste celular.'),
        ),
      );
    }
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
                      _rodape(),
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
    return ErroWidget(
      // 404: outra ONG aceitou, ou o horário acabou.
      mensagem: '$erro\nEla pode ter sido aceita por outra ONG.',
      onTentar: _viewModel.carregar,
    );
  }

  Widget _conteudo(DetalheDoacao detalhe) {
    final doacao = detalhe.doacao;
    final doador = detalhe.doador;
    final distancia = _viewModel.distanciaKm;
    return ListView(
      children: [
        GaleriaDeFotos(doacao: doacao),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doacao.titulo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${distancia == null ? '' : '${Formatador.distancia(distancia)} • '}'
                'Retirar até ${Formatador.diaHora(doacao.janelaFim)}',
                style: const TextStyle(color: AppColors.cinza, fontSize: 16),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('como_chegar'),
                onPressed: () => _comoChegar(doacao),
                icon: const Icon(Icons.directions),
                label: const Text('Como chegar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              if (doador != null) ...[
                const SizedBox(height: 16),
                _CartaoDoDoador(doador: doador),
              ],
              const Divider(height: 32),
              DadosDaDoacao(doacao: doacao),
            ],
          ),
        ),
      ],
    );
  }

  /// O botão principal fica fixo embaixo. Desativado, com o motivo.
  Widget _rodape() {
    final motivo = _viewModel.suspensa
        ? 'Você está suspensa por desistências e não pode aceitar agora.'
        : 'O aceite da retirada ("Vou retirar") entra na etapa 4.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            motivo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.cinza),
          ),
          const SizedBox(height: 8),
          const PrimaryButton(texto: 'Vou retirar', onPressed: null),
        ],
      ),
    );
  }
}

/// Quem está doando: nome, tipo e o selo de verificação (RN03).
class _CartaoDoDoador extends StatelessWidget {
  const _CartaoDoDoador({required this.doador});

  final ResumoOrganizacao doador;

  @override
  Widget build(BuildContext context) {
    final tipo = doador.tipoEstabelecimento;
    return Card(
      elevation: 0,
      color: AppColors.verdeClaro,
      child: ListTile(
        leading: const Icon(Icons.storefront, color: AppColors.verde),
        title: Text(doador.nomeOrganizacao),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tipo != null) Text(tipo.rotulo),
            const SizedBox(height: 4),
            SeloVerificacao(verificacao: doador.verificacao),
          ],
        ),
      ),
    );
  }
}
