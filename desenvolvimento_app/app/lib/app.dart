import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/dependencias.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';

/// Widget raiz: tema, título e sistema de rotas.
///
/// Arquivo de FUNDAÇÃO: altere só em PR combinado com o grupo.
class App extends StatefulWidget {
  const App({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Criado uma única vez, mesmo que o App seja redesenhado.
  late final AppRouter _roteador = AppRouter(widget.dependencias);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.nomeApp,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.inicio,
      onGenerateRoute: _roteador.gerar,
    );
  }
}
