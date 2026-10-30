import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';

/// Cartão de uma doação, usado nas listas do doador e da ONG.
///
/// [novidade] destaca a doação que acabou de aparecer (aviso da ONG).
class DoacaoCard extends StatelessWidget {
  const DoacaoCard({
    super.key,
    required this.doacao,
    this.onTap,
    this.novidade = false,
  });

  final Doacao doacao;
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant, color: AppColors.verde),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doacao.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (novidade) const _Etiqueta('NOVA', AppColors.laranja),
                  if (!novidade)
                    _Etiqueta(
                      doacao.status.rotulo,
                      _corDoStatus(doacao.status),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${doacao.categoria.rotulo}  •  ${doacao.quantidade}',
                style: const TextStyle(color: AppColors.cinza),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _Info(
                    Icons.schedule,
                    'Retirar até ${Formatador.diaHora(doacao.janelaFim)}',
                  ),
                  if (doacao.distanciaKm != null)
                    _Info(
                      Icons.place,
                      Formatador.distancia(doacao.distanciaKm!),
                    ),
                  if (doacao.nomeDoador != null)
                    _Info(Icons.storefront, doacao.nomeDoador!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _corDoStatus(StatusDoacao status) => switch (status) {
    StatusDoacao.disponivel => AppColors.verde,
    StatusDoacao.reservada => AppColors.laranja,
    StatusDoacao.concluida => AppColors.cinza,
    StatusDoacao.cancelada => AppColors.erro,
  };
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, this.cor);

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    // O texto acompanha a cor: informação não depende só da cor
    // (acessibilidade).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icone, this.texto);

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 16, color: AppColors.cinza),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
