import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/notificacoes/central_de_notificacoes.dart';
import 'package:summit_backend/notificacoes/enviador_de_push.dart';
import 'package:summit_backend/notificacoes/notificacao_repository.dart';

import 'chat_em_memoria.dart';
import 'doacoes_em_memoria.dart';
import 'em_memoria.dart';

/// [NotificacaoRepository] em memória. A escolha das ONGs (RN11) usa as
/// contas e os bloqueios dos outros repositórios em memória.
class NotificacoesEmMemoria implements NotificacaoRepository {
  NotificacoesEmMemoria(this._contas, this._doacoes);

  final ContasEmMemoria _contas;
  final DoacoesEmMemoria _doacoes;
  final List<Notificacao> _lista = [];

  /// O chat em memória (a central grava nele as mensagens do sistema).
  late final ChatEmMemoria chat = ChatEmMemoria(_contas, _doacoes);
  final Map<int, int> _dono = {};

  /// As notificações de um usuário (para os testes conferirem).
  List<Notificacao> de(int usuarioId) => [
    for (final n in _lista)
      if (_dono[n.id] == usuarioId) n,
  ];

  @override
  Future<Notificacao> criar(NovaNotificacao nova) async {
    final n = Notificacao(
      id: _lista.length + 1,
      tipo: nova.tipo,
      titulo: nova.titulo,
      corpo: nova.corpo,
      criadoEm: nova.criadoEm,
      doacaoId: nova.doacaoId,
      reservaId: nova.reservaId,
    );
    _lista.add(n);
    _dono[n.id] = nova.usuarioId;
    return n;
  }

  @override
  Future<List<Notificacao>> depoisDe(
    int usuarioId,
    int depoisDe, {
    required int limite,
  }) async => de(usuarioId).where((n) => n.id > depoisDe).take(limite).toList();

  @override
  Future<void> marcarLidas(int usuarioId, int ate) async {
    for (var i = 0; i < _lista.length; i++) {
      final n = _lista[i];
      if (_dono[n.id] == usuarioId && n.id <= ate) {
        _lista[i] = Notificacao.fromJson({...n.toJson(), 'lida': true});
      }
    }
  }

  @override
  Future<bool> existe(TipoNotificacao tipo, int reservaId) async =>
      _lista.any((n) => n.tipo == tipo && n.reservaId == reservaId);

  @override
  Future<List<OngParaAviso>> ongsParaAvisar(
    int doacaoId,
    DateTime agora,
  ) async => [
    for (final registro in _contas.registros)
      if (registro.conta.usuario.ehOng &&
          registro.conta.perfil.buscaAtiva &&
          !registro.conta.perfil.estaSuspensa(agora) &&
          !_doacoes.bloqueios.contains(
            '${registro.conta.usuario.id}-$doacaoId',
          ))
        OngParaAviso(
          usuarioId: registro.conta.usuario.id,
          coordenadas: registro.conta.perfil.coordenadas,
          raioKm: registro.conta.perfil.raioKm,
        ),
  ];

  /// A central já ligada a este repositório (enviador desligado).
  CentralDeNotificacoes central(Relogio relogio) => CentralDeNotificacoes(
    notificacoes: this,
    enviador: const EnviadorPushDesligado(),
    chat: chat,
    relogio: relogio,
    fusoHorarioUtc: -3,
  );
}
