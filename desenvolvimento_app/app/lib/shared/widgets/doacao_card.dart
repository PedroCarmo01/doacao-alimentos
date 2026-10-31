import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import 'etiqueta_status.dart';
import 'foto_da_doacao.dart';

/// Cartão de uma doação, usado nas listas do doador (T10) e da ONG (T20).
///
/// Mostra: foto, título, status COM TEXTO, quantidade e peso, horário
/// limite e, se reservada, a ONG e o tempo que falta.
/// [novidade] destaca a doação que acabou de aparecer (lista da ONG).
class DoacaoCard extends StatelessWidget {
  const DoacaoCard({
    super.key,
    required this.doacao,
    required this.agora,
    this.onTap,
    this.novidade = false,
  });

  final Doacao doacao;

  /// O "agora" de quando a lista foi carregada (vem do `Relogio`).
  final DateTime agora;
  final VoidCallback? onTap;
  final bool novidade;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: novidade
            ? const BorderSide(color: AppColors.laranja, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FotoDaDoacao(
                caminho: doacao.fotos.firstOrNull,
                categoria: doacao.categoria,
                tamanho: 76,
              ),
              const SizedBox(width: 12),
              Expanded(child: _textos(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textos(BuildContext context) {
    const cinza = TextStyle(color: AppColors.cinza);
    final distancia = doacao.distanciaKm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                doacao.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            novidade
                ? const Etiqueta(texto: 'NOVA', cor: AppColors.laranja)
                : Etiqueta.doStatus(doacao.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${Formatador.quantidadeEPeso(doacao)}'
          '${distancia == null ? '' : ' • ${Formatador.distancia(distancia)}'}',
          style: cinza,
        ),
        const SizedBox(height: 4),
        Text(_linhaDoHorario(), style: cinza),
      ],
    );
  }

  /// "Retirar até 18:00", "ONG X vem buscar • faltam 42 min" ou a data.
  String _linhaDoHorario() {
    final nomeOng = doacao.nomeOng;
    final prazo = doacao.prazoRetirada;
    if (doacao.status == StatusDoacao.reservada && nomeOng != null) {
      final restante = prazo == null ? '' : ' • ${_falta(prazo)}';
      return '$nomeOng vem buscar$restante';
    }
    if (doacao.status.ativa) {
      return 'Retirar até ${Formatador.diaHora(doacao.janelaFim)}';
    }
    return 'Publicada em ${Formatador.diaHora(doacao.criadoEm)}';
  }

  String _falta(DateTime prazo) {
    final restante = prazo.difference(agora);
    if (restante.isNegative) return 'prazo acabou';
    return 'faltam ${Formatador.duracaoCurta(restante)}';
  }
}
