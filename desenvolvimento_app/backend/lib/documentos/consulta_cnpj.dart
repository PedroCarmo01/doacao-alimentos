import 'package:shared_models/shared_models.dart';

/// O que aconteceu ao consultar um CNPJ.
enum SituacaoDaConsulta {
  /// A Receita conhece o CNPJ: os dados estão em [ResultadoConsultaCnpj.info].
  encontrado,

  /// A consulta funcionou, mas o CNPJ não existe na Receita.
  naoEncontrado,

  /// Não deu para consultar agora (sem internet, BrasilAPI fora do ar ou
  /// demorou mais de 5 s). RN03: o cadastro NÃO é bloqueado por isso.
  indisponivel,
}

/// Resposta de [ConsultaCnpj.consultar].
///
/// Usamos uma classe com uma [situacao] em vez de lançar exceções porque
/// "API fora do ar" não é um erro do usuário: é um caso previsto pela RN03.
class ResultadoConsultaCnpj {
  const ResultadoConsultaCnpj.encontrado(InfoCnpj this.info)
    : situacao = SituacaoDaConsulta.encontrado;

  const ResultadoConsultaCnpj.naoEncontrado()
    : situacao = SituacaoDaConsulta.naoEncontrado,
      info = null;

  const ResultadoConsultaCnpj.indisponivel()
    : situacao = SituacaoDaConsulta.indisponivel,
      info = null;

  final SituacaoDaConsulta situacao;

  /// Preenchido só quando [situacao] é [SituacaoDaConsulta.encontrado].
  final InfoCnpj? info;
}

/// CONTRATO: consultar um CNPJ na Receita Federal (RN03).
///
/// ABSTRAÇÃO + POLIMORFISMO: o `DocumentoService` só conhece esta
/// interface. Em `main.dart` escolhemos a implementação:
/// - `ConsultaCnpjBrasilApi`: consulta de verdade, pela internet;
/// - `ConsultaCnpjFake`: sem internet (testes e `CONSULTAR_BRASILAPI=false`).
abstract interface class ConsultaCnpj {
  /// [cnpj] só com números. Nunca lança exceção por falha de rede: devolve
  /// [ResultadoConsultaCnpj.indisponivel].
  Future<ResultadoConsultaCnpj> consultar(String cnpj);
}
