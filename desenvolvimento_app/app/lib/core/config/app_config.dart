/// Configurações do app definidas NA COMPILAÇÃO com `--dart-define`.
///
/// Exemplos (o `.vscode/launch.json` já tem perfis prontos):
///
///     flutter run --dart-define=API_URL=http://10.0.2.2:8080
///     flutter run --dart-define=USAR_FAKE=true
///
/// O app não guarda segredos: só o endereço da API (docs/adr/ADR-012).
abstract final class AppConfig {
  /// Nome exibido no app.
  /// TODO(grupo): trocar quando o nome do aplicativo for definido.
  /// ("Summit" é o nome do EVENTO de entrega, não do app.)
  static const nomeApp = 'Doação de Alimentos';

  /// Endereço da API.
  /// - Emulador Android: `http://10.0.2.2:8080` (aponta para o seu PC).
  /// - Celular físico: `http://<IP do PC na rede>:8080`.
  /// - Chrome: `http://127.0.0.1:8080`.
  static const urlApi = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// `true` = usa repositórios Fake em memória (não precisa de backend).
  static const usarFake = bool.fromEnvironment('USAR_FAKE');

  /// De quanto em quanto tempo a tela da ONG procura doações novas
  /// (docs/adr/ADR-008).
  static const intervaloAtualizacao = Duration(seconds: 15);

  /// Identificador do app (o mesmo `applicationId` do Android). O servidor de
  /// mapas do OpenStreetMap pede que cada app se identifique.
  static const identificadorApp = 'br.edu.umc.summit_app';
}
