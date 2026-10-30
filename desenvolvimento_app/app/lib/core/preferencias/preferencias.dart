import 'package:shared_preferences/shared_preferences.dart';

/// Pequenas escolhas do aparelho que não são segredo (por enquanto, só se
/// a pessoa já viu as boas-vindas da T2).
///
/// Interface + duas implementações, como o `ArmazenamentoToken`: no
/// aparelho usamos o `shared_preferences`; nos testes e no modo Fake, a
/// memória.
abstract interface class Preferencias {
  Future<bool> jaViuBoasVindas();
  Future<void> marcarBoasVindasVistas();
}

/// Guarda no próprio aparelho (continua salvo ao fechar o app).
class PreferenciasDoAparelho implements Preferencias {
  static const _chaveBoasVindas = 'ja_viu_boas_vindas';

  @override
  Future<bool> jaViuBoasVindas() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getBool(_chaveBoasVindas) ?? false;
  }

  @override
  Future<void> marcarBoasVindasVistas() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setBool(_chaveBoasVindas, true);
  }
}

/// Guarda só na memória (some ao fechar o app).
class PreferenciasMemoria implements Preferencias {
  bool _viuBoasVindas = false;

  @override
  Future<bool> jaViuBoasVindas() async => _viuBoasVindas;

  @override
  Future<void> marcarBoasVindasVistas() async => _viuBoasVindas = true;
}
