import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

/// Mostra uma foto de doação, venha ela de onde vier:
/// - `assets/...`: foto de exemplo do modo Fake (dentro do app);
/// - caminho do celular (`/data/...`): foto escolhida, ainda não enviada
///   (ou guardada pelo modo Fake);
/// - só o nome (`3f2a...e1.jpg`): foto do servidor, em
///   `GET /arquivos/{nome}`.
///
/// Sem foto, mostra o ícone da categoria.
class FotoDaDoacao extends StatelessWidget {
  const FotoDaDoacao({
    super.key,
    required this.caminho,
    this.categoria,
    this.tamanho,
    this.raio = 12,
  });

  final String? caminho;

  /// Para escolher o ícone quando não há foto.
  final CategoriaAlimento? categoria;

  /// Lado do quadrado. `null` = ocupa o espaço disponível.
  final double? tamanho;
  final double raio;

  /// Endereço completo de uma foto do servidor.
  static String enderecoNoServidor(String nome) =>
      '${AppConfig.urlApi}/arquivos/$nome';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(raio),
      child: SizedBox(width: tamanho, height: tamanho, child: _imagem()),
    );
  }

  Widget _imagem() {
    final foto = caminho;
    if (foto == null || foto.isEmpty) return _semFoto();
    final Widget imagem;
    if (foto.startsWith('assets/')) {
      imagem = Image.asset(foto, fit: BoxFit.cover);
    } else if (foto.contains('/') || foto.contains(r'\')) {
      imagem = Image.file(File(foto), fit: BoxFit.cover);
    } else {
      imagem = Image.network(
        enderecoNoServidor(foto),
        fit: BoxFit.cover,
        // Sem internet ou servidor fora do ar: mostra o ícone no lugar.
        errorBuilder: (_, _, _) => _semFoto(),
      );
    }
    return Semantics(label: 'Foto da doação', image: true, child: imagem);
  }

  Widget _semFoto() => ColoredBox(
    color: AppColors.verdeClaro,
    child: Center(
      child: Icon(iconeDa(categoria), color: AppColors.verde, size: 32),
    ),
  );

  static IconData iconeDa(CategoriaAlimento? categoria) => switch (categoria) {
    CategoriaAlimento.hortifruti => Icons.eco,
    CategoriaAlimento.padaria => Icons.bakery_dining,
    CategoriaAlimento.laticinios => Icons.local_drink,
    CategoriaAlimento.mercearia => Icons.shopping_basket,
    CategoriaAlimento.refeicoesProntas => Icons.lunch_dining,
    CategoriaAlimento.carnesFrios => Icons.set_meal,
    CategoriaAlimento.bebidas => Icons.local_cafe,
    CategoriaAlimento.outros || null => Icons.inventory_2,
  };
}
