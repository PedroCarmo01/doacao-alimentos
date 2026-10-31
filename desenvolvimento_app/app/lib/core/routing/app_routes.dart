/// Nomes de todas as rotas do app, em um só lugar.
///
/// Use sempre as constantes (`AppRoutes.login`), nunca o texto solto: um erro
/// de digitação vira erro de compilação, e não uma tela em branco.
abstract final class AppRoutes {
  /// T1 — abertura: decide para onde ir (início, boas-vindas ou login).
  static const inicio = '/';

  /// T2 — boas-vindas (só na primeira vez).
  static const boasVindas = '/boas-vindas';

  /// T3 — login. Argumento opcional: `String` com um aviso para mostrar
  /// no topo (ex.: "Sua sessão expirou. Entre novamente.").
  static const login = '/login';

  /// T4 — cadastro em etapas.
  static const cadastro = '/cadastro';

  /// Texto dos Termos de Uso e da Política de Privacidade.
  static const termos = '/termos';

  /// Casca com a barra inferior de 5 itens (doador ou ONG).
  static const casca = '/inicio';

  static const novaDoacao = '/doador/nova-doacao';

  /// Argumento: `int` (id da doação).
  static const detalheDoacaoDoador = '/doador/doacao';

  /// Argumento: `int` (id da doação).
  static const detalheDoacaoOng = '/ong/doacao';

  /// Minhas retiradas (ONG): em andamento e histórico.
  static const minhasReservas = '/ong/reservas';

  /// T23 — retirada em andamento (ONG). Argumento: `int` (id da retirada).
  static const retirada = '/ong/retirada';

  /// T30 — chat da retirada. Argumento: `int` (id da retirada).
  static const chat = '/chat';

  /// T13 — o doador digita o código. Argumento: `int` (id da retirada).
  static const confirmarRetirada = '/doador/confirmar-retirada';
}
