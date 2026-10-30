import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../shared/widgets/app_text_field.dart';
import 'nova_doacao_view_model.dart';

/// T11 — campos de escolha do formulário da doação: categoria, quantidade
/// com unidade, peso, conservação e "precisa de veículo?".
class CamposDaEscolha extends StatelessWidget {
  const CamposDaEscolha({
    super.key,
    required this.viewModel,
    required this.quantidade,
    required this.peso,
  });

  final NovaDoacaoViewModel viewModel;
  final TextEditingController quantidade;
  final TextEditingController peso;

  @override
  Widget build(BuildContext context) {
    const numero = TextInputType.numberWithOptions(decimal: true);
    final vm = viewModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<CategoriaAlimento>(
            initialValue: vm.categoria,
            decoration: const InputDecoration(
              labelText: 'Categoria',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              for (final categoria in CategoriaAlimento.values)
                DropdownMenuItem(
                  value: categoria,
                  child: Text(categoria.rotulo),
                ),
            ],
            onChanged: (categoria) => vm.escolherCategoria(categoria!),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                key: const Key('campo_quantidade'),
                label: 'Quantidade',
                controller: quantidade,
                keyboardType: numero,
                validator: (texto) => ValidadorDoacao.quantidade(
                  ValidadorDoacao.lerNumero(texto),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<Unidade>(
                initialValue: vm.unidade,
                decoration: const InputDecoration(labelText: 'Unidade'),
                items: [
                  for (final unidade in Unidade.values)
                    DropdownMenuItem(
                      value: unidade,
                      child: Text(unidade.rotulo),
                    ),
                ],
                onChanged: (unidade) => vm.escolherUnidade(unidade!),
              ),
            ),
          ],
        ),
        AppTextField(
          key: const Key('campo_peso'),
          label: 'Peso aproximado (kg)',
          controller: peso,
          keyboardType: numero,
          prefixIcon: Icons.scale_outlined,
          textoAjuda: 'Entra na conta dos "kg salvos" da Comunidade.',
          validator: (texto) =>
              ValidadorDoacao.pesoKg(ValidadorDoacao.lerNumero(texto)),
        ),
        FileiraDeEscolhas(
          titulo: 'Conservação',
          rotulos: [for (final opcao in Conservacao.values) opcao.rotulo],
          selecionada: Conservacao.values.indexOf(vm.conservacao),
          aoEscolher: (indice) {
            // Conservação é obrigatória: tocar de novo não desmarca.
            if (indice != null) {
              vm.escolherConservacao(Conservacao.values[indice]);
            }
          },
        ),
      ],
    );
  }
}

/// Uma fileira de botões ("chips") para escolher UMA opção, pela posição
/// na lista de [rotulos]. Tocar na escolhida desmarca ([aoEscolher] recebe
/// `null`).
class FileiraDeEscolhas extends StatelessWidget {
  const FileiraDeEscolhas({
    super.key,
    required this.titulo,
    required this.rotulos,
    required this.selecionada,
    required this.aoEscolher,
  });

  final String titulo;
  final List<String> rotulos;

  /// Posição da opção escolhida (-1 ou `null` = nenhuma).
  final int? selecionada;
  final ValueChanged<int?> aoEscolher;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < rotulos.length; i++)
              ChoiceChip(
                label: Text(rotulos[i]),
                selected: i == selecionada,
                onSelected: (marcado) => aoEscolher(marcado ? i : null),
              ),
          ],
        ),
      ],
    ),
  );
}
