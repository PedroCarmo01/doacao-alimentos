import '../contratos/doacoes.dart';
import '../tempo/relogio.dart';
import '../tipos_de_doacao.dart';
import 'validador_usuario.dart';

/// Regras de validação de uma doação (app e backend) — RN10 e RN12.
///
/// Por que [agora] e [hoje] são parâmetros? Para que a regra não dependa do
/// relógio do computador: nos testes passamos datas fixas e o resultado é
/// sempre o mesmo.
abstract final class ValidadorDoacao {
  static const quantidadeMaxima = 100000.0;
  static const pesoMaximoKg = 10000.0;
  static const tamanhoMaximoMotivo = 255;

  /// Refeição pronta precisa ser retirada em até 4 h depois do preparo.
  static const limiteRefeicaoPronta = Duration(hours: 4);

  static String? titulo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o que é (ex.: Pães do dia).';
    if (texto.length < 3) return 'O título deve ter pelo menos 3 letras.';
    if (texto.length > 120) {
      return 'O título deve ter no máximo 120 caracteres.';
    }
    return null;
  }

  static String? descricao(String? valor) {
    if ((valor?.length ?? 0) > 500) {
      return 'A descrição deve ter no máximo 500 caracteres.';
    }
    return null;
  }

  static String? quantidade(double? valor) {
    if (valor == null || valor <= 0) return 'Informe a quantidade.';
    if (valor > quantidadeMaxima) return 'Quantidade grande demais.';
    return null;
  }

  static String? pesoKg(double? valor) {
    if (valor == null || valor <= 0) return 'Informe o peso aproximado em kg.';
    if (valor > pesoMaximoKg) return 'Peso grande demais.';
    return null;
  }

  /// Converte o texto do formulário ("2,5") em número. `null` se inválido.
  static double? lerNumero(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  /// RN10: validade não pode ser anterior a hoje. [hoje] é a data de
  /// calendário atual do usuário (sem horário).
  static String? validade(DateTime? validade, {required DateTime hoje}) {
    if (validade == null) return 'Informe a data de validade.';
    final dia = Calendario.somenteData(validade);
    if (dia.isBefore(Calendario.somenteData(hoje))) {
      return 'Não é permitido doar alimentos vencidos.';
    }
    return null;
  }

  /// RN10: o fim da retirada precisa ser no futuro e depois do início.
  static String? janela(
    DateTime? inicio,
    DateTime? fim, {
    required DateTime agora,
  }) {
    if (inicio == null || fim == null) {
      return 'Informe o início e o fim do horário de retirada.';
    }
    if (!fim.isAfter(inicio)) {
      return 'O fim da retirada deve ser depois do início.';
    }
    if (!fim.isAfter(agora)) {
      return 'O horário de retirada não pode terminar no passado.';
    }
    return null;
  }

  /// Refeições prontas: precisa do horário de preparo, que não pode estar
  /// no futuro, e a retirada termina no máximo 4 h depois dele.
  static String? refeicaoPronta(
    CategoriaAlimento categoria, {
    required DateTime? preparadoEm,
    required DateTime? fimDaRetirada,
    required DateTime agora,
  }) {
    if (categoria != CategoriaAlimento.refeicoesProntas) return null;
    if (preparadoEm == null) return 'Informe o horário de preparo.';
    if (preparadoEm.isAfter(agora)) {
      return 'O horário de preparo não pode estar no futuro.';
    }
    final limite = preparadoEm.add(limiteRefeicaoPronta);
    if (fimDaRetirada != null && fimDaRetirada.isAfter(limite)) {
      return 'Refeições prontas devem ser retiradas em até 4 h depois do '
          'preparo. Diminua o fim do horário de retirada.';
    }
    return null;
  }

  /// RN10: a declaração é obrigatória.
  static String? declaracao(bool aceita) => aceita
      ? null
      : 'Confirme que os alimentos estão dentro da validade e próprios '
            'para consumo.';

  /// RN12: motivo do cancelamento de uma doação reservada.
  static String? motivoCancelamento(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.length < 3) return 'Conte à ONG o motivo do cancelamento.';
    if (texto.length > tamanhoMaximoMotivo) {
      return 'Use no máximo $tamanhoMaximoMotivo caracteres.';
    }
    return null;
  }

  /// Valida a doação inteira. Lista vazia significa "tudo certo".
  static List<String> validar(
    DadosNovaDoacao dados, {
    required DateTime agora,
    required DateTime hoje,
  }) => [
    titulo(dados.titulo),
    descricao(dados.descricao),
    quantidade(dados.quantidade),
    pesoKg(dados.pesoKg),
    validade(dados.validade, hoje: hoje),
    janela(dados.janelaInicio, dados.janelaFim, agora: agora),
    refeicaoPronta(
      dados.categoria,
      preparadoEm: dados.preparadoEm,
      fimDaRetirada: dados.janelaFim,
      agora: agora,
    ),
    ValidadorUsuario.textoLivre(dados.endereco),
    declaracao(dados.declaracaoAlimentosProprios),
    if (dados.latitude != null || dados.longitude != null)
      ValidadorUsuario.coordenadas(dados.latitude, dados.longitude),
  ].whereType<String>().toList();
}
