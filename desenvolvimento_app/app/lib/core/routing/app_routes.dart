import 'package:shared_models/shared_models.dart';

/// Nomes de todas as rotas do app, em um só lugar.
///
/// Use sempre as constantes (`AppRoutes.login`), nunca o texto solto: um erro
/// de digitação vira erro de compilação, e não uma tela em branco.
abstract final class AppRoutes {
  static const inicio = '/';

  /// Argumento: [TipoUsuario].
  static const login = '/login';

  /// Argumento: [TipoUsuario].
  static const cadastro = '/cadastro';

  static const inicioDoador = '/doador';
  static const novaDoacao = '/doador/nova-doacao';

  /// Argumento: `int` (id da doação).
  static const detalheDoacaoDoador = '/doador/doacao';

  static const inicioOng = '/ong';

  /// Argumento: `int` (id da doação).
  static const detalheDoacaoOng = '/ong/doacao';

  static const minhasReservas = '/ong/reservas';
  static const mapa = '/ong/mapa';

  /// Tela inicial de cada tipo de usuário, depois do login.
  static String inicioDoTipo(TipoUsuario tipo) => switch (tipo) {
        TipoUsuario.doador => inicioDoador,
        TipoUsuario.ong => inicioOng,
      };
}
