import 'package:flutter/material.dart';

/// Botão principal do app. Mostra um spinner enquanto [carregando] é true
/// e fica desabilitado nesse período.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.carregando = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: carregando ? null : onPressed,
      child: carregando
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(texto),
    );
  }
}
