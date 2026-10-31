import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_models/shared_models.dart';

import '../theme/app_theme.dart';

/// Mostra um aviso na barra de notificações do celular.
///
/// É uma interface para os testes usarem o [MostradorEmMemoria] (que só
/// guarda o que "mostraria").
abstract interface class MostradorDeNotificacoes {
  /// Prepara o mostrador. [aoTocar] recebe o texto guardado na notificação
  /// ([payload]) quando a pessoa toca nela.
  Future<void> preparar(void Function(String payload) aoTocar);

  /// Android 13+: pede a permissão de mostrar notificações.
  Future<void> pedirPermissao();

  Future<void> mostrar(Notificacao notificacao, {required String payload});

  /// Se o app foi ABERTO por um toque numa notificação, o payload dela.
  Future<String?> payloadQueAbriuOApp();
}

/// A versão de verdade, com o pacote `flutter_local_notifications`.
class MostradorAndroid implements MostradorDeNotificacoes {
  final _plugin = FlutterLocalNotificationsPlugin();

  /// O "canal" do Android: com importância alta, a notificação faz som e
  /// aparece no topo da tela (heads-up).
  static const _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'avisos',
      'Avisos das doações',
      channelDescription: 'Doações novas, retiradas e prazos.',
      importance: Importance.high,
      priority: Priority.high,
      // O Android pinta o ícone pequeno de uma cor só: por isso ele é a
      // folha e o coração em branco (res/drawable-*/ic_notificacao.png).
      icon: 'ic_notificacao',
      color: AppColors.verde,
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> preparar(void Function(String payload) aoTocar) async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notificacao'),
        ),
        onDidReceiveNotificationResponse: (resposta) {
          final payload = resposta.payload;
          if (payload != null) aoTocar(payload);
        },
      );
    } catch (erro) {
      // Sem o plugin (ex.: rodando no Chrome), o app segue sem avisos.
      debugPrint('Notificações indisponíveis: $erro');
    }
  }

  @override
  Future<void> pedirPermissao() async {
    try {
      await _android?.requestNotificationsPermission();
    } catch (erro) {
      debugPrint('Sem permissão de notificação: $erro');
    }
  }

  @override
  Future<void> mostrar(Notificacao notificacao, {required String payload}) =>
      _plugin.show(
        id: notificacao.id,
        title: notificacao.titulo,
        body: notificacao.corpo,
        notificationDetails: _detalhes,
        payload: payload,
      );

  @override
  Future<String?> payloadQueAbriuOApp() async {
    try {
      final detalhes = await _plugin.getNotificationAppLaunchDetails();
      if (detalhes == null || !detalhes.didNotificationLaunchApp) return null;
      return detalhes.notificationResponse?.payload;
    } catch (_) {
      return null;
    }
  }
}

/// Para os testes: guarda o que seria mostrado.
class MostradorEmMemoria implements MostradorDeNotificacoes {
  final List<Notificacao> mostradas = [];
  bool pediuPermissao = false;
  void Function(String payload)? _aoTocar;

  /// Simula o toque na notificação.
  void tocar(String payload) => _aoTocar?.call(payload);

  @override
  Future<void> preparar(void Function(String payload) aoTocar) async =>
      _aoTocar = aoTocar;

  @override
  Future<void> pedirPermissao() async => pediuPermissao = true;

  @override
  Future<void> mostrar(
    Notificacao notificacao, {
    required String payload,
  }) async => mostradas.add(notificacao);

  @override
  Future<String?> payloadQueAbriuOApp() async => null;
}
