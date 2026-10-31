import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/fotos/seletor_de_fotos.dart';
import 'foto_da_doacao.dart';

/// O que a [SecaoFotos] precisa de uma tela que tem fotos.
///
/// POLIMORFISMO: a nova doação (T11) e a nova publicação (T41) são
/// ViewModels diferentes, mas os dois "sabem" guardar fotos. A seção de
/// fotos conversa com esta interface e serve para os dois.
abstract interface class EscolhaDeFotos {
  /// As já enviadas ao servidor (nome do arquivo).
  List<String> get fotosSalvas;

  /// As escolhidas agora, que ainda vão ser enviadas.
  List<FotoEscolhida> get fotosNovas;

  bool get podeAdicionarFoto;

  /// Pergunta ao [SeletorDeFotos] (câmera ou galeria).
  Future<bool> adicionarFoto({required bool daCamera});

  void removerFotoNova(FotoEscolhida foto);
}

/// Até 3 fotos: as já enviadas, as novas (com "x" para tirar) e o botão
/// de adicionar, que pergunta: câmera ou galeria? (T11 e T41)
class SecaoFotos extends StatelessWidget {
  const SecaoFotos({super.key, required this.viewModel, this.dica});

  final EscolhaDeFotos viewModel;

  /// O texto pequeno embaixo das fotos.
  final String? dica;

  static const _lado = 96.0;

  Future<void> _escolherOrigem(BuildContext context) async {
    final daCamera = await showModalBottomSheet<bool>(
      context: context,
      builder: (contexto) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(contexto, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(contexto, false),
            ),
          ],
        ),
      ),
    );
    if (daCamera == null) return;
    await viewModel.adicionarFoto(daCamera: daCamera);
  }

  @override
  Widget build(BuildContext context) {
    final total = viewModel.fotosSalvas.length + viewModel.fotosNovas.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos ($total de 3) — recomendado',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final nome in viewModel.fotosSalvas)
              FotoDaDoacao(caminho: nome, tamanho: _lado),
            for (final foto in viewModel.fotosNovas)
              _FotoNova(
                caminho: foto.caminho,
                aoRemover: () => viewModel.removerFotoNova(foto),
              ),
            if (viewModel.podeAdicionarFoto)
              _BotaoAdicionar(aoTocar: () => _escolherOrigem(context)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          dica ?? 'Fotos dos alimentos ajudam a ONG a decidir mais rápido.',
          style: const TextStyle(color: AppColors.cinza, fontSize: 12),
        ),
      ],
    );
  }
}

class _FotoNova extends StatelessWidget {
  const _FotoNova({required this.caminho, required this.aoRemover});

  final String caminho;
  final VoidCallback aoRemover;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FotoDaDoacao(caminho: caminho, tamanho: SecaoFotos._lado),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton.filled(
            tooltip: 'Tirar esta foto',
            iconSize: 18,
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
            icon: const Icon(Icons.close),
            onPressed: aoRemover,
          ),
        ),
      ],
    );
  }
}

class _BotaoAdicionar extends StatelessWidget {
  const _BotaoAdicionar({required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Adicionar foto',
      child: InkWell(
        key: const Key('botao_adicionar_foto'),
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: SecaoFotos._lado,
          height: SecaoFotos._lado,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.verde, width: 2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, color: AppColors.verde),
              SizedBox(height: 4),
              Text('Adicionar', style: TextStyle(color: AppColors.verde)),
            ],
          ),
        ),
      ),
    );
  }
}
