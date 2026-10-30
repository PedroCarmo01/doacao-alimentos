import 'package:flutter/material.dart';

/// A logo do app dentro de um círculo branco (abertura, boas-vindas, login).
///
/// A imagem fica em `assets/imagens/logo.png`. É provisória: quando o grupo
/// tiver a logo definitiva, basta trocar o arquivo (etapa 8).
class LogoDoApp extends StatelessWidget {
  const LogoDoApp({super.key, this.tamanho = 96});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo do app',
      image: true,
      child: Container(
        width: tamanho,
        height: tamanho,
        padding: EdgeInsets.all(tamanho * 0.08),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          'assets/imagens/logo.png',
          // Se a imagem faltar, mostra um ícone no lugar (não quebra a tela).
          errorBuilder: (context, erro, pilha) =>
              const Icon(Icons.volunteer_activism, color: Colors.green),
        ),
      ),
    );
  }
}
