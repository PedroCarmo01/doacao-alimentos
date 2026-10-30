import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../shared/widgets/aviso.dart';
import 'nova_doacao_view_model.dart';

/// T11 — validade, horário de retirada (de... até...) e, para refeições
/// prontas, o horário de preparo com o aviso de segurança.
///
/// Os horários ficam em UTC no ViewModel; aqui eles aparecem e são
/// escolhidos no horário do celular (`toLocal()`).
class CamposDeHorario extends StatelessWidget {
  const CamposDeHorario({super.key, required this.viewModel});

  final NovaDoacaoViewModel viewModel;

  Future<void> _escolherValidade(BuildContext context) async {
    final hoje = DateTime.now();
    final dia = await showDatePicker(
      context: context,
      initialDate: viewModel.validade,
      // Só deixa escolher de hoje em diante (RN10): o servidor confere de
      // novo, mas assim a pessoa nem consegue errar.
      firstDate: DateTime(hoje.year, hoje.month, hoje.day),
      lastDate: hoje.add(const Duration(days: 365)),
      helpText: 'Validade dos alimentos',
    );
    if (dia != null) {
      viewModel.escolherValidade(DateTime.utc(dia.year, dia.month, dia.day));
    }
  }

  /// Escolhe dia e hora; devolve o instante em UTC (ou `null`).
  static Future<DateTime?> _escolherInstante(
    BuildContext context,
    DateTime atual,
    String titulo,
  ) async {
    final local = atual.toLocal();
    final dia = await showDatePicker(
      context: context,
      initialDate: local,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: titulo,
    );
    if (dia == null || !context.mounted) return null;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(local),
      helpText: titulo,
    );
    if (hora == null) return null;
    return DateTime(
      dia.year,
      dia.month,
      dia.day,
      hora.hour,
      hora.minute,
    ).toUtc();
  }

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Linha(
          icone: Icons.event,
          rotulo: 'Validade',
          valor: Formatador.data(vm.validade),
          aoTocar: () => _escolherValidade(context),
        ),
        _Linha(
          icone: Icons.schedule,
          rotulo: 'Retirar a partir de',
          valor: Formatador.diaHora(vm.inicio),
          aoTocar: () async {
            final escolhido = await _escolherInstante(
              context,
              vm.inicio,
              'Início da retirada',
            );
            if (escolhido != null) vm.escolherInicio(escolhido);
          },
        ),
        _Linha(
          icone: Icons.timer_off_outlined,
          rotulo: 'Retirar até',
          valor: Formatador.diaHora(vm.fim),
          aoTocar: () async {
            final escolhido = await _escolherInstante(
              context,
              vm.fim,
              'Fim da retirada',
            );
            if (escolhido != null) vm.escolherFim(escolhido);
          },
        ),
        if (vm.ehRefeicaoPronta) ..._refeicaoPronta(context),
      ],
    );
  }

  List<Widget> _refeicaoPronta(BuildContext context) {
    final preparo = viewModel.preparadoEm;
    return [
      _Linha(
        icone: Icons.soup_kitchen,
        rotulo: 'Preparada em',
        valor: preparo == null ? 'Informe' : Formatador.diaHora(preparo),
        aoTocar: () async {
          final escolhido = await _escolherInstante(
            context,
            preparo ?? DateTime.now().toUtc(),
            'Horário de preparo',
          );
          if (escolhido != null) viewModel.escolherPreparo(escolhido);
        },
      ),
      const SizedBox(height: 8),
      const Aviso(
        icone: Icons.thermostat,
        texto:
            'Refeições prontas devem ser retiradas em até 2 h e mantidas na '
            'temperatura correta. O horário de retirada termina no máximo '
            '4 h depois do preparo.',
      ),
    ];
  }
}

/// Uma linha tocável: ícone, rótulo e o valor escolhido.
class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.rotulo,
    required this.valor,
    required this.aoTocar,
  });

  final IconData icone;
  final String rotulo;
  final String valor;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icone, color: AppColors.verde),
    title: Text(rotulo),
    subtitle: Text(valor, style: const TextStyle(fontSize: 16)),
    trailing: const Icon(Icons.edit_calendar, color: AppColors.cinza),
    onTap: aoTocar,
  );
}
