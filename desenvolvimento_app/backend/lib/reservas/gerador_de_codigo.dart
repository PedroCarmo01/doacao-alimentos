import 'dart:math';

/// RN26: cria o código de retirada de 4 dígitos.
///
/// É uma interface para os testes poderem usar um código conhecido
/// ([GeradorDeCodigoFixo]) em vez de um sorteio.
abstract interface class GeradorDeCodigo {
  String novo();
}

/// Sorteio de verdade. `Random.secure()` usa o gerador do sistema
/// operacional, que não dá para prever (o `Random()` comum dá).
class GeradorDeCodigoAleatorio implements GeradorDeCodigo {
  final _sorteio = Random.secure();

  @override
  String novo() => _sorteio.nextInt(10000).toString().padLeft(4, '0');
}

/// Sempre o mesmo código (testes).
class GeradorDeCodigoFixo implements GeradorDeCodigo {
  const GeradorDeCodigoFixo(this.codigo);

  final String codigo;

  @override
  String novo() => codigo;
}
