import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/theme/app_theme.dart';

/// Etiqueta colorida COM TEXTO (acessibilidade: a cor é só um reforço).
class Etiqueta extends StatelessWidget {
  const Etiqueta({super.key, required this.texto, required this.cor});

  /// A etiqueta do status de uma doação.
  factory Etiqueta.doStatus(StatusDoacao status) =>
      Etiqueta(texto: status.rotulo, cor: corDoStatus(status));

  final String texto;
  final Color cor;

  static Color corDoStatus(StatusDoacao status) => switch (status) {
    StatusDoacao.disponivel => AppColors.verde,
    StatusDoacao.reservada => AppColors.laranja,
    StatusDoacao.concluida => AppColors.azul,
    StatusDoacao.cancelada => AppColors.erro,
    StatusDoacao.expirada => AppColors.cinza,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
