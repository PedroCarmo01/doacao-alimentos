import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/dependencias.dart';

/// Primeira função executada pelo app.
///
/// Escolhe as implementações (API real ou Fake em memória) e entrega tudo ao
/// [App]. Rode com `--dart-define=USAR_FAKE=true` para usar o modo Fake
/// (no VS Code: perfil "App — dados fictícios").
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencias =
      AppConfig.usarFake ? Dependencias.fake() : Dependencias.api();
  runApp(App(dependencias: dependencias));
}
