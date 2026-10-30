import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Um item da [BarraInferior]: ícone, texto e (opcional) contador.
class ItemDaBarra {
  const ItemDaBarra({
    required this.icone,
    required this.rotulo,
    this.contador = 0,
  });

  final IconData icone;
  final String rotulo;

  /// Número vermelho (ex.: mensagens não lidas). 0 = não mostra.
  final int contador;
}

/// Barra de navegação inferior com 5 itens e o do MEIO maior, redondo e
/// saltando para fora da barra (seção 2 da especificação).
///
/// Por que assim: a barra fica onde o polegar alcança e a ação mais
/// importante (Doar / Mapa) fica no meio, o ponto mais fácil de tocar.
/// Todos os itens têm ícone E texto e área de toque de pelo menos 48 dp.
class BarraInferior extends StatelessWidget {
  const BarraInferior({
    super.key,
    required this.itens,
    required this.indiceAtual,
    required this.aoTocar,
  }) : assert(itens.length == 5, 'A barra tem exatamente 5 itens.');

  final List<ItemDaBarra> itens;
  final int indiceAtual;
  final ValueChanged<int> aoTocar;

  static const indiceCentral = 2;
  static const alturaDaBarra = 64.0;
  static const tamanhoDoBotaoCentral = 72.0;

  /// Quanto o botão central sobe acima da barra.
  static const salto = 20.0;

  @override
  Widget build(BuildContext context) {
    final margemDoSistema = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: alturaDaBarra + salto + margemDoSistema,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: alturaDaBarra + margemDoSistema,
            child: Material(
              color: Colors.white,
              elevation: 12,
              child: Padding(
                padding: EdgeInsets.only(bottom: margemDoSistema),
                child: Row(
                  children: [
                    for (var i = 0; i < itens.length; i++)
                      Expanded(
                        child: i == indiceCentral
                            ? const SizedBox.shrink()
                            : _ItemComum(
                                item: itens[i],
                                selecionado: i == indiceAtual,
                                aoTocar: () => aoTocar(i),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _BotaoCentral(
              item: itens[indiceCentral],
              selecionado: indiceAtual == indiceCentral,
              aoTocar: () => aoTocar(indiceCentral),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemComum extends StatelessWidget {
  const _ItemComum({
    required this.item,
    required this.selecionado,
    required this.aoTocar,
  });

  final ItemDaBarra item;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? AppColors.verde : AppColors.cinza;
    return Semantics(
      button: true,
      selected: selecionado,
      child: InkWell(
        onTap: aoTocar,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: item.contador > 0,
              label: Text('${item.contador}'),
              backgroundColor: AppColors.erro,
              child: Icon(item.icone, color: cor),
            ),
            const SizedBox(height: 4),
            Text(
              item.rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: cor,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoCentral extends StatelessWidget {
  const _BotaoCentral({
    required this.item,
    required this.selecionado,
    required this.aoTocar,
  });

  final ItemDaBarra item;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    const tamanho = BarraInferior.tamanhoDoBotaoCentral;
    return Semantics(
      button: true,
      selected: selecionado,
      label: item.rotulo,
      excludeSemantics: true,
      child: Material(
        color: AppColors.verde,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 4),
        ),
        elevation: 6,
        child: InkWell(
          key: const Key('botao_central'),
          customBorder: const CircleBorder(),
          onTap: aoTocar,
          child: SizedBox.square(
            dimension: tamanho,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icone, color: Colors.white, size: 30),
                Text(
                  item.rotulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
