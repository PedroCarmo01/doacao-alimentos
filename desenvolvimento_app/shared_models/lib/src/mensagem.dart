import 'util/json.dart';

/// Uma mensagem do chat de uma retirada (T30).
///
/// [autorId] `null` = mensagem do SISTEMA ("ONG Mãos Amigas aceitou a
/// doação às 14:10"), que aparece no meio da conversa.
class Mensagem {
  const Mensagem({
    required this.id,
    required this.reservaId,
    required this.texto,
    required this.criadoEm,
    this.autorId,
    this.lidaEm,
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Mensagem');
    return Mensagem(
      id: j.inteiro('id'),
      reservaId: j.inteiro('reservaId'),
      autorId: j.inteiroOpcional('autorId'),
      texto: j.texto('texto'),
      criadoEm: j.instante('criadoEm'),
      lidaEm: j.instanteOpcional('lidaEm'),
    );
  }

  /// Tamanho máximo do texto (coluna VARCHAR(1000)).
  static const tamanhoMaximo = 1000;

  final int id;
  final int reservaId;
  final int? autorId;
  final String texto;
  final DateTime criadoEm;

  /// Quando a outra pessoa leu ("✓ lida").
  final DateTime? lidaEm;

  bool get ehDoSistema => autorId == null;

  /// `null` se o texto pode ser enviado; senão, o motivo.
  static String? validar(String? texto) {
    final limpo = texto?.trim() ?? '';
    if (limpo.isEmpty) return 'Escreva uma mensagem.';
    if (limpo.length > tamanhoMaximo) {
      return 'A mensagem pode ter no máximo $tamanhoMaximo caracteres.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reservaId': reservaId,
    'autorId': autorId,
    'texto': texto,
    'criadoEm': formatarInstante(criadoEm),
    'lidaEm': lidaEm == null ? null : formatarInstante(lidaEm!),
  };
}

/// Resposta de `GET /conversas/{reservaId}/mensagens?depois=`.
class RespostaMensagens {
  const RespostaMensagens({
    required this.mensagens,
    required this.somenteLeitura,
    this.lidasAte = 0,
  });

  factory RespostaMensagens.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'RespostaMensagens');
    final lista = json['mensagens'];
    return RespostaMensagens(
      mensagens: [
        if (lista is List)
          for (final item in lista)
            Mensagem.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      somenteLeitura: j.booleano('somenteLeitura'),
      lidasAte: j.inteiroOpcional('lidasAte') ?? 0,
    );
  }

  /// As mensagens novas (id maior que o `depois` pedido).
  final List<Mensagem> mensagens;

  /// RN31: a retirada terminou; dá para ler, mas não para escrever.
  final bool somenteLeitura;

  /// Maior id das MINHAS mensagens que a outra pessoa já leu. O app marca
  /// "✓ lida" em todas as minhas até esse id (inclusive as antigas, que
  /// não vêm de novo na consulta).
  final int lidasAte;

  Map<String, dynamic> toJson() => {
    'mensagens': [for (final m in mensagens) m.toJson()],
    'somenteLeitura': somenteLeitura,
    'lidasAte': lidasAte,
  };
}

/// Uma linha da aba Mensagens (T31): uma conversa por retirada.
class ResumoConversa {
  const ResumoConversa({
    required this.reservaId,
    required this.doacaoId,
    required this.tituloDoacao,
    required this.nomeOutro,
    required this.naoLidas,
    required this.somenteLeitura,
    this.fotoDoacao,
    this.categoria,
    this.ultimaMensagem,
    this.ultimaEm,
  });

  factory ResumoConversa.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'ResumoConversa');
    return ResumoConversa(
      reservaId: j.inteiro('reservaId'),
      doacaoId: j.inteiro('doacaoId'),
      tituloDoacao: j.texto('tituloDoacao'),
      nomeOutro: j.texto('nomeOutro'),
      naoLidas: j.inteiro('naoLidas'),
      somenteLeitura: j.booleano('somenteLeitura'),
      fotoDoacao: j.textoOpcional('fotoDoacao'),
      categoria: j.textoOpcional('categoria'),
      ultimaMensagem: j.textoOpcional('ultimaMensagem'),
      ultimaEm: j.instanteOpcional('ultimaEm'),
    );
  }

  final int reservaId;
  final int doacaoId;
  final String tituloDoacao;

  /// A ONG (para o doador) ou o doador (para a ONG).
  final String nomeOutro;
  final int naoLidas;
  final bool somenteLeitura;
  final String? fotoDoacao;

  /// Nome do enum `CategoriaAlimento` (ícone quando não há foto).
  final String? categoria;
  final String? ultimaMensagem;
  final DateTime? ultimaEm;

  Map<String, dynamic> toJson() => {
    'reservaId': reservaId,
    'doacaoId': doacaoId,
    'tituloDoacao': tituloDoacao,
    'nomeOutro': nomeOutro,
    'naoLidas': naoLidas,
    'somenteLeitura': somenteLeitura,
    'fotoDoacao': fotoDoacao,
    'categoria': categoria,
    'ultimaMensagem': ultimaMensagem,
    'ultimaEm': ultimaEm == null ? null : formatarInstante(ultimaEm!),
  };
}
