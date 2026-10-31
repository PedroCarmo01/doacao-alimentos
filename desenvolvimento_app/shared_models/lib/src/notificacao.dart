import 'util/json.dart';

/// Os eventos que geram notificação (seção 9 da especificação). Os nomes
/// são os mesmos do ENUM da coluna `notificacoes.tipo` no banco.
enum TipoNotificacao {
  doacaoNova,
  doacaoAceita,
  prazoAcabando,
  prazoAcabouOng,
  prazoAcabouDoador,
  doacaoDisponivelDeNovo,
  retiradaConfirmada,
  mensagemNova,
  doacaoCancelada,
  suspensao,
}

/// Um aviso para um usuário. O servidor SEMPRE grava o aviso na tabela;
/// o app busca os novos (`GET /notificacoes?depois=`) e mostra como
/// notificação do Android.
class Notificacao {
  const Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    required this.criadoEm,
    this.doacaoId,
    this.reservaId,
    this.lida = false,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    final j = LeitorJson(json, contexto: 'Notificacao');
    return Notificacao(
      id: j.inteiro('id'),
      tipo: j.enumerado('tipo', TipoNotificacao.values),
      titulo: j.texto('titulo'),
      corpo: j.texto('corpo'),
      criadoEm: j.instante('criadoEm'),
      doacaoId: j.inteiroOpcional('doacaoId'),
      reservaId: j.inteiroOpcional('reservaId'),
      lida: json['lida'] == true,
    );
  }

  final int id;
  final TipoNotificacao tipo;
  final String titulo;
  final String corpo;
  final DateTime criadoEm;

  /// Para abrir a tela certa ao tocar (detalhe da doação ou retirada).
  final int? doacaoId;
  final int? reservaId;
  final bool lida;

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo.name,
    'titulo': titulo,
    'corpo': corpo,
    'criadoEm': formatarInstante(criadoEm),
    'doacaoId': doacaoId,
    'reservaId': reservaId,
    'lida': lida,
  };
}
