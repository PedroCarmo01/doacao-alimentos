import 'tipos_de_perfil.dart';
import 'usuario.dart';
import 'util/json.dart';

/// Motivos de denúncia de uma publicação (RN42). Mesmos nomes do ENUM da
/// coluna `denuncias.motivo`.
enum MotivoDenuncia {
  improprio('Conteúdo impróprio'),
  falso('Informação falsa'),
  outro('Outro motivo');

  const MotivoDenuncia(this.rotulo);

  final String rotulo;
}

/// Uma publicação do feed da Comunidade (T40).
///
/// [nomeAutor], [verificacaoAutor], [tipoAutor], [resumoDoacao], [apoios] e
/// [apoiadaPorMim] são de leitura: o servidor preenche para a tela.
class Publicacao {
  const Publicacao({
    required this.id,
    required this.autorId,
    required this.nomeAutor,
    required this.tipoAutor,
    required this.verificacaoAutor,
    required this.texto,
    required this.criadoEm,
    this.fotos = const [],
    this.doacaoId,
    this.resumoDoacao,
    this.familiasAjudadas,
    this.refeicoes,
    this.apoios = 0,
    this.apoiadaPorMim = false,
  });

  factory Publicacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Publicacao');
    final fotos = json['fotos'];
    return Publicacao(
      id: j.inteiro('id'),
      autorId: j.inteiro('autorId'),
      nomeAutor: j.texto('nomeAutor'),
      tipoAutor: j.enumerado('tipoAutor', TipoUsuario.values),
      verificacaoAutor: j.enumerado('verificacaoAutor', Verificacao.values),
      texto: j.texto('texto'),
      criadoEm: j.instante('criadoEm'),
      fotos: fotos is List ? [for (final f in fotos) '$f'] : const [],
      doacaoId: j.inteiroOpcional('doacaoId'),
      resumoDoacao: j.textoOpcional('resumoDoacao'),
      familiasAjudadas: j.inteiroOpcional('familiasAjudadas'),
      refeicoes: j.inteiroOpcional('refeicoes'),
      apoios: j.inteiroOpcional('apoios') ?? 0,
      apoiadaPorMim: json['apoiadaPorMim'] == true,
    );
  }

  /// RN40: até 3 fotos.
  static const maximoDeFotos = 3;

  final int id;
  final int autorId;
  final String nomeAutor;
  final TipoUsuario tipoAutor;
  final Verificacao verificacaoAutor;
  final String texto;
  final DateTime criadoEm;
  final List<String> fotos;

  /// A doação concluída de que a publicação fala (opcional).
  final int? doacaoId;

  /// "30 unidades de Pães do dia — Padaria Pão Quente → ONG Mãos Amigas".
  final String? resumoDoacao;
  final int? familiasAjudadas;
  final int? refeicoes;

  /// RN41: quantas contas apoiaram (cada uma, uma vez).
  final int apoios;
  final bool apoiadaPorMim;

  /// Cópia com o apoio do usuário trocado (o app atualiza na hora).
  Publicacao comApoio({required bool apoiada}) {
    if (apoiada == apoiadaPorMim) return this;
    final json = toJson()
      ..['apoiadaPorMim'] = apoiada
      ..['apoios'] = apoios + (apoiada ? 1 : -1);
    return Publicacao.fromJson(json);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'autorId': autorId,
    'nomeAutor': nomeAutor,
    'tipoAutor': tipoAutor.name,
    'verificacaoAutor': verificacaoAutor.name,
    'texto': texto,
    'criadoEm': formatarInstante(criadoEm),
    'fotos': fotos,
    'doacaoId': doacaoId,
    'resumoDoacao': resumoDoacao,
    'familiasAjudadas': familiasAjudadas,
    'refeicoes': refeicoes,
    'apoios': apoios,
    'apoiadaPorMim': apoiadaPorMim,
  };
}

/// Corpo de `POST /comunidade/publicacoes` (T41). As fotos vão depois, uma
/// por vez.
class DadosPublicacao {
  const DadosPublicacao({
    required this.texto,
    this.doacaoId,
    this.familiasAjudadas,
    this.refeicoes,
  });

  factory DadosPublicacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Publicação');
    return DadosPublicacao(
      texto: j.texto('texto'),
      doacaoId: j.inteiroOpcional('doacaoId'),
      familiasAjudadas: j.inteiroOpcional('familiasAjudadas'),
      refeicoes: j.inteiroOpcional('refeicoes'),
    );
  }

  static const tamanhoMaximoTexto = 1000;

  /// Um limite de bom senso para os números do painel de impacto.
  static const maximoPorPublicacao = 100000;

  final String texto;
  final int? doacaoId;
  final int? familiasAjudadas;
  final int? refeicoes;

  /// RN40: texto obrigatório (até 1000) e números não negativos. Devolve
  /// uma mensagem por problema (lista vazia = tudo certo).
  List<String> validar() {
    final erros = <String>[];
    final limpo = texto.trim();
    if (limpo.isEmpty) erros.add('Escreva o texto da publicação.');
    if (limpo.length > tamanhoMaximoTexto) {
      erros.add('O texto pode ter no máximo $tamanhoMaximoTexto caracteres.');
    }
    for (final numero in [familiasAjudadas, refeicoes]) {
      if (numero != null && (numero < 0 || numero > maximoPorPublicacao)) {
        erros.add('Use um número entre 0 e $maximoPorPublicacao.');
        break;
      }
    }
    return erros;
  }

  Map<String, dynamic> toJson() => {
    'texto': texto,
    'doacaoId': doacaoId,
    'familiasAjudadas': familiasAjudadas,
    'refeicoes': refeicoes,
  };
}

/// O painel de impacto do topo da Comunidade (T40): números de TODOS.
class Impacto {
  const Impacto({
    required this.kgSalvos,
    required this.doacoesConcluidas,
    required this.familiasAjudadas,
    required this.refeicoes,
  });

  factory Impacto.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Impacto');
    return Impacto(
      kgSalvos: j.decimal('kgSalvos'),
      doacoesConcluidas: j.inteiro('doacoesConcluidas'),
      familiasAjudadas: j.inteiro('familiasAjudadas'),
      refeicoes: j.inteiro('refeicoes'),
    );
  }

  /// Soma do peso das doações concluídas (ODS 12).
  final double kgSalvos;
  final int doacoesConcluidas;

  /// Somas informadas nas publicações (ODS 2).
  final int familiasAjudadas;
  final int refeicoes;

  Map<String, dynamic> toJson() => {
    'kgSalvos': kgSalvos,
    'doacoesConcluidas': doacoesConcluidas,
    'familiasAjudadas': familiasAjudadas,
    'refeicoes': refeicoes,
  };
}
