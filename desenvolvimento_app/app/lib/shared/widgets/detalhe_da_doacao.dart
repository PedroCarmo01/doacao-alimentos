import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import 'foto_da_doacao.dart';

// Partes do detalhe de uma doação usadas pelo doador (T12) e pela ONG (T22).

/// Fotos para deslizar (ou o ícone da categoria, se não houver).
class GaleriaDeFotos extends StatelessWidget {
  const GaleriaDeFotos({super.key, required this.doacao});

  final Doacao doacao;

  @override
  Widget build(BuildContext context) {
    final fotos = doacao.fotos;
    return SizedBox(
      height: 220,
      child: fotos.isEmpty
          ? FotoDaDoacao(caminho: null, categoria: doacao.categoria, raio: 0)
          : PageView(
              children: [
                for (var i = 0; i < fotos.length; i++)
                  Semantics(
                    label: 'Foto ${i + 1} de ${fotos.length}',
                    child: FotoDaDoacao(caminho: fotos[i], raio: 0),
                  ),
              ],
            ),
    );
  }
}

/// Os dados da doação, um por linha (ícone + rótulo + valor).
class DadosDaDoacao extends StatelessWidget {
  const DadosDaDoacao({super.key, required this.doacao});

  final Doacao doacao;

  @override
  Widget build(BuildContext context) {
    final preparo = doacao.preparadoEm;
    final veiculo = doacao.veiculo;
    final descricao = doacao.descricao;
    return Column(
      children: [
        _Dado(Icons.category_outlined, 'Categoria', doacao.categoria.rotulo),
        _Dado(
          Icons.inventory_2_outlined,
          'Quantidade',
          Formatador.quantidadeEPeso(doacao),
        ),
        _Dado(Icons.ac_unit, 'Conservação', doacao.conservacao.rotulo),
        _Dado(Icons.event, 'Validade', Formatador.data(doacao.validade)),
        if (preparo != null)
          _Dado(
            Icons.soup_kitchen,
            'Preparada em',
            Formatador.diaHora(preparo),
          ),
        _Dado(
          Icons.schedule,
          'Retirada',
          'de ${Formatador.diaHora(doacao.janelaInicio)} '
              'até ${Formatador.diaHora(doacao.janelaFim)}',
        ),
        _Dado(Icons.place_outlined, 'Endereço', doacao.endereco ?? '—'),
        if (veiculo != null)
          _Dado(Icons.local_shipping_outlined, 'Transporte', veiculo.rotulo),
        if (descricao != null) _Dado(Icons.notes, 'Observações', descricao),
      ],
    );
  }
}

class _Dado extends StatelessWidget {
  const _Dado(this.icone, this.rotulo, this.valor);

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icone, color: AppColors.verde),
    title: Text(rotulo, style: const TextStyle(color: AppColors.cinza)),
    subtitle: Text(valor, style: const TextStyle(fontSize: 16)),
  );
}
