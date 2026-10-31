import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/chat/chat_repository.dart';

import 'doacoes_em_memoria.dart';
import 'em_memoria.dart';

/// [ChatRepository] em memória, sobre as retiradas e doações em memória.
class ChatEmMemoria implements ChatRepository {
  ChatEmMemoria(this._contas, this._doacoes);

  final ContasEmMemoria _contas;
  final DoacoesEmMemoria _doacoes;
  final List<Mensagem> todas = [];

  String _nome(int usuarioId) =>
      _contas.conta(usuarioId)?.perfil.nomeOrganizacao ?? '?';

  @override
  Future<List<ResumoConversa>> conversasDe(
    int usuarioId,
    DateTime desde,
  ) async {
    final conversas = <ResumoConversa>[];
    for (final reserva in _doacoes.reservas) {
      final info = (await this.info(reserva.id))!;
      if (!info.participa(usuarioId)) continue;
      if (!info.ativa && info.encerradaEm!.isBefore(desde)) continue; // RN31
      final mensagens = await this.mensagens(reserva.id, 0);
      conversas.add(
        ResumoConversa(
          reservaId: reserva.id,
          doacaoId: reserva.doacaoId,
          tituloDoacao: 'Doação ${reserva.doacaoId}',
          nomeOutro: _nome(info.outro(usuarioId)),
          naoLidas: mensagens
              .where(
                (m) =>
                    !m.ehDoSistema &&
                    m.autorId != usuarioId &&
                    m.lidaEm == null,
              )
              .length,
          somenteLeitura: !info.ativa,
          ultimaMensagem: mensagens.lastOrNull?.texto,
        ),
      );
    }
    return conversas;
  }

  @override
  Future<ConversaInfo?> info(int reservaId) async {
    final reserva = _doacoes.reservas
        .where((r) => r.id == reservaId)
        .firstOrNull;
    if (reserva == null) return null;
    final doacao = (await _doacoes.buscar(reserva.doacaoId))!;
    return ConversaInfo(
      reservaId: reservaId,
      doacaoId: doacao.id,
      ongId: reserva.ongId,
      doadorId: doacao.doadorId,
      nomeOng: _nome(reserva.ongId),
      nomeDoador: _nome(doacao.doadorId),
      ativa: reserva.estaAtiva,
      encerradaEm: reserva.encerradaEm,
    );
  }

  @override
  Future<List<Mensagem>> mensagens(int reservaId, int depoisDe) async => [
    for (final m in todas)
      if (m.reservaId == reservaId && m.id > depoisDe) m,
  ];

  @override
  Future<int> lidasAte(int reservaId, int autorId) async {
    var ate = 0;
    for (final m in todas) {
      if (m.reservaId == reservaId &&
          m.autorId == autorId &&
          m.lidaEm != null) {
        ate = m.id;
      }
    }
    return ate;
  }

  @override
  Future<Mensagem> inserir(
    int reservaId, {
    required int? autorId,
    required String texto,
    required DateTime agora,
  }) async {
    final m = Mensagem(
      id: todas.length + 1,
      reservaId: reservaId,
      autorId: autorId,
      texto: texto,
      criadoEm: agora,
    );
    todas.add(m);
    return m;
  }

  @override
  Future<void> marcarLidas(int reservaId, int leitorId, DateTime agora) async {
    for (var i = 0; i < todas.length; i++) {
      final m = todas[i];
      if (m.reservaId == reservaId &&
          !m.ehDoSistema &&
          m.autorId != leitorId &&
          m.lidaEm == null) {
        todas[i] = Mensagem.fromJson({
          ...m.toJson(),
          'lidaEm': agora.toUtc().toIso8601String(),
        });
      }
    }
  }
}
