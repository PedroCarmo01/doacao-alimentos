import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';

/// Pedaços da tela T23, separados para a página ficar curta.

/// Contador regressivo grande ("58:41"). Fica vermelho nos últimos 10 min.
class Contador extends StatelessWidget {
  const Contador({super.key, required this.restante});

  final Duration restante;

  @override
  Widget build(BuildContext context) {
    final urgente = restante < const Duration(minutes: 10);
    return Card(
      color: urgente ? AppColors.erro : AppColors.verde,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Text(
              'Tempo para retirar',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              Formatador.contador(restante),
              key: const Key('contador'),
              // O leitor de tela fala por extenso, não "quarenta e dois
              // dois-pontos dez".
              semanticsLabel:
                  'Faltam ${restante.inMinutes} minutos e '
                  '${restante.inSeconds % 60} segundos',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// RN26: o código de 4 dígitos, bem grande, para mostrar ao doador.
class CodigoDeRetirada extends StatelessWidget {
  const CodigoDeRetirada({super.key, required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Código de retirada', style: TextStyle(fontSize: 16)),
            Text(
              codigo.split('').join(' '),
              key: const Key('codigo_retirada'),
              // O leitor de tela fala os números um a um.
              semanticsLabel: 'Código ${codigo.split('').join(', ')}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const Text(
              'Mostre este código ao doador na hora da retirada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.cinza),
            ),
          ],
        ),
      ),
    );
  }
}

/// O que retirar e onde.
class EnderecoDaRetirada extends StatelessWidget {
  const EnderecoDaRetirada({super.key, required this.detalhe});

  final DetalheDoacao detalhe;

  @override
  Widget build(BuildContext context) {
    final doacao = detalhe.doacao;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.place, color: AppColors.verde),
      title: Text('${doacao.titulo} • ${doacao.quantidadeTexto}'),
      subtitle: Text(
        '${detalhe.doador?.nomeOrganizacao ?? doacao.nomeDoador ?? ''}\n'
        '${doacao.endereco ?? 'Endereço no perfil do doador'}',
      ),
      isThreeLine: true,
    );
  }
}

/// A retirada terminou: confirmada (com festa) ou não (com o motivo).
class RetiradaEncerrada extends StatelessWidget {
  const RetiradaEncerrada({
    super.key,
    required this.reserva,
    this.desistencia,
    this.aoContarNaComunidade,
  });

  final Reserva reserva;

  /// "Contar na Comunidade" (só para a retirada confirmada).
  final VoidCallback? aoContarNaComunidade;

  /// Preenchida se a ONG desistiu nesta tela.
  final RespostaDesistencia? desistencia;

  @override
  Widget build(BuildContext context) {
    final concluida = reserva.status == StatusReserva.concluida;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              concluida ? Icons.check_circle : Icons.info_outline,
              size: 96,
              color: concluida ? AppColors.verde : AppColors.cinza,
            ),
            const SizedBox(height: 16),
            Text(
              concluida ? 'Retirada confirmada!' : reserva.status.rotulo,
              key: const Key('retirada_encerrada'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_explicacao(), textAlign: TextAlign.center),
            if (concluida) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                key: const Key('contar_na_comunidade'),
                onPressed: aoContarNaComunidade,
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Contar na Comunidade'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _explicacao() {
    final suspensaAte = desistencia?.suspensaAte;
    if (suspensaAte != null) {
      return 'Isso contou como desistência e sua conta está suspensa até '
          '${Formatador.diaHora(suspensaAte)}.';
    }
    return switch (reserva.status) {
      StatusReserva.concluida => 'Obrigado por evitar o desperdício.',
      StatusReserva.expirada =>
        'O prazo acabou e a doação voltou para outras ONGs. '
            'Isso contou como desistência.',
      StatusReserva.canceladaOng =>
        reserva.contouDesistencia
            ? 'A doação voltou para outras ONGs. Isso contou como desistência.'
            : 'A doação voltou para outras ONGs. Foi dentro da tolerância: '
                  'não contou como desistência.',
      StatusReserva.canceladaDoador =>
        'O doador cancelou a doação.'
            '${reserva.motivo == null ? '' : ' Motivo: ${reserva.motivo}'}',
      StatusReserva.ativa => '',
    };
  }
}
