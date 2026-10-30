import '../contratos/doacoes.dart';
import '../tempo/relogio.dart';
import 'validador_usuario.dart';

/// Regras de validação de uma nova doação (app e backend).
///
/// Por que [agora] e [hoje] são parâmetros? Para que a regra não dependa do
/// relógio do computador: nos testes passamos datas fixas e o resultado é
/// sempre o mesmo.
abstract final class ValidadorDoacao {
  static String? titulo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe um título (ex.: Frutas do dia).';
    if (texto.length < 3) return 'O título deve ter pelo menos 3 letras.';
    if (texto.length > 120) {
      return 'O título deve ter no máximo 120 caracteres.';
    }
    return null;
  }

  static String? quantidade(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe a quantidade (ex.: 5 caixas).';
    if (texto.length > 60) {
      return 'A quantidade deve ter no máximo 60 caracteres.';
    }
    return null;
  }

  static String? descricao(String? valor) {
    if ((valor?.length ?? 0) > 500) {
      return 'A descrição deve ter no máximo 500 caracteres.';
    }
    return null;
  }

  /// [hoje] é a data de calendário atual do usuário (sem horário).
  static String? validade(DateTime? validade, {required DateTime hoje}) {
    if (validade == null) return 'Informe a data de validade.';
    final dia = Calendario.somenteData(validade);
    if (dia.isBefore(Calendario.somenteData(hoje))) {
      return 'Não é permitido doar alimentos vencidos.';
    }
    return null;
  }

  static String? janela(
    DateTime? inicio,
    DateTime? fim, {
    required DateTime agora,
  }) {
    if (inicio == null || fim == null) {
      return 'Informe o início e o fim da janela de retirada.';
    }
    if (!fim.isAfter(inicio)) {
      return 'O fim da retirada deve ser depois do início.';
    }
    if (!fim.isAfter(agora)) {
      return 'A janela de retirada não pode terminar no passado.';
    }
    return null;
  }

  static String? declaracao(bool aceita) =>
      aceita ? null : 'Confirme que os alimentos estão próprios para consumo.';

  /// Valida a doação inteira. Lista vazia significa "tudo certo".
  static List<String> validar(
    DadosNovaDoacao dados, {
    required DateTime agora,
    required DateTime hoje,
  }) => [
    titulo(dados.titulo),
    quantidade(dados.quantidade),
    descricao(dados.descricao),
    validade(dados.validade, hoje: hoje),
    janela(dados.janelaInicio, dados.janelaFim, agora: agora),
    declaracao(dados.declaracaoAlimentosProprios),
    if (dados.latitude != null || dados.longitude != null)
      ValidadorUsuario.coordenadas(dados.latitude, dados.longitude),
  ].whereType<String>().toList();
}
