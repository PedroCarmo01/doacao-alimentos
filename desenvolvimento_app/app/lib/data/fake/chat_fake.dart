import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';
import 'contas_fake.dart';
import 'doacoes_fake.dart';
import 'notificacoes_fake.dart';

/// O chat do modo Fake, com as MESMAS regras do `ChatService` do backend
/// (RN30: só os dois da retirada; RN31: só leitura depois do fim, por 7
/// dias).
class ChatFake {
  ChatFake(this._relogio, this._contas, this._doacoes, this._avisos);

  final Relogio _relogio;
  final ContasFake _contas;
  final DoacoesFake _doacoes;
  final NotificacoesFake _avisos;
  final List<Mensagem> _todas = [];

  static const _tempoDeLeitura = Duration(days: 7);
  static const _naoEncontrada = ApiException(
    codigo: 'NAO_ENCONTRADO',
    mensagem: 'Conversa não encontrada.',
    status: 404,
  );

  DateTime get _agora => _relogio.agora();

  /// Mensagem do sistema ("ONG Mãos Amigas aceitou a doação").
  void doSistema(int reservaId, String texto, {DateTime? em}) =>
      _inserir(reservaId, null, texto, em ?? _agora);

  /// Usada pelos exemplos (mensagens já trocadas antes). Como no seed,
  /// a mensagem de exemplo já foi lida, a não ser que [lida] seja `false`.
  void deExemplo(
    int reservaId,
    int autorId,
    String texto,
    DateTime em, {
    bool lida = true,
  }) => _inserir(reservaId, autorId, texto, em, lidaEm: lida ? em : null);

  List<ResumoConversa> conversasDe(Conta conta) {
    final eu = conta.usuario.id;
    final conversas = <ResumoConversa>[];
    for (final reserva in _doacoes.reservas) {
      final doacao = _doacoes.porId(reserva.doacaoId);
      if (reserva.ongId != eu && doacao.doadorId != eu) continue;
      if (!_visivel(reserva)) continue;
      final mensagens = _daConversa(reserva.id);
      final outro = eu == reserva.ongId ? doacao.doadorId : reserva.ongId;
      conversas.add(
        ResumoConversa(
          reservaId: reserva.id,
          doacaoId: doacao.id,
          tituloDoacao: doacao.titulo,
          nomeOutro: _contas.porId(outro)?.perfil.nomeOrganizacao ?? '',
          naoLidas: mensagens.where((m) => _naoLidaPor(m, eu)).length,
          somenteLeitura: !reserva.estaAtiva,
          fotoDoacao: doacao.fotos.firstOrNull,
          categoria: doacao.categoria.name,
          ultimaMensagem: mensagens.lastOrNull?.texto,
          ultimaEm: mensagens.lastOrNull?.criadoEm ?? reserva.reservadoEm,
        ),
      );
    }
    return conversas..sort((a, b) => b.ultimaEm!.compareTo(a.ultimaEm!));
  }

  RespostaMensagens mensagens(Conta conta, int reservaId, int depoisDe) {
    final reserva = _participante(conta, reservaId);
    final eu = conta.usuario.id;
    var lidasAte = 0;
    for (final m in _daConversa(reservaId)) {
      if (m.autorId == eu && m.lidaEm != null) lidasAte = m.id;
    }
    return RespostaMensagens(
      mensagens: [
        for (final m in _daConversa(reservaId))
          if (m.id > depoisDe) m,
      ],
      somenteLeitura: !reserva.estaAtiva,
      lidasAte: lidasAte,
    );
  }

  Mensagem enviar(Conta conta, int reservaId, String texto) {
    final erro = Mensagem.validar(texto);
    if (erro != null) {
      throw ApiException(codigo: 'VALIDACAO', mensagem: erro, status: 400);
    }
    final reserva = _participante(conta, reservaId);
    if (!reserva.estaAtiva) {
      throw const ApiException(
        codigo: 'CHAT_SOMENTE_LEITURA',
        mensagem: 'A retirada terminou: a conversa fica só para leitura.',
        status: 409,
      );
    }
    final mensagem = _inserir(
      reservaId,
      conta.usuario.id,
      texto.trim(),
      _agora,
    );
    final doacao = _doacoes.porId(reserva.doacaoId);
    final outro = conta.usuario.id == reserva.ongId
        ? doacao.doadorId
        : reserva.ongId;
    _avisos.avisar(
      outro,
      TipoNotificacao.mensagemNova,
      titulo: conta.perfil.nomeOrganizacao,
      corpo: mensagem.texto,
      doacaoId: doacao.id,
      reservaId: reservaId,
    );
    return mensagem;
  }

  void marcarLidas(Conta conta, int reservaId) {
    _participante(conta, reservaId);
    for (var i = 0; i < _todas.length; i++) {
      final m = _todas[i];
      if (m.reservaId == reservaId && _naoLidaPor(m, conta.usuario.id)) {
        _todas[i] = Mensagem.fromJson({
          ...m.toJson(),
          'lidaEm': _agora.toUtc().toIso8601String(),
        });
      }
    }
  }

  // ----------------------------------------------------------- internos

  Mensagem _inserir(
    int reservaId,
    int? autorId,
    String texto,
    DateTime em, {
    DateTime? lidaEm,
  }) {
    final m = Mensagem(
      id: _todas.length + 1,
      reservaId: reservaId,
      autorId: autorId,
      texto: texto,
      criadoEm: em,
      lidaEm: lidaEm,
    );
    _todas.add(m);
    return m;
  }

  List<Mensagem> _daConversa(int reservaId) => [
    for (final m in _todas)
      if (m.reservaId == reservaId) m,
  ];

  static bool _naoLidaPor(Mensagem m, int eu) =>
      !m.ehDoSistema && m.autorId != eu && m.lidaEm == null;

  /// RN31: ativa, ou encerrada há menos de 7 dias.
  bool _visivel(Reserva reserva) =>
      reserva.estaAtiva ||
      (reserva.encerradaEm?.isAfter(_agora.subtract(_tempoDeLeitura)) ?? false);

  /// RN30: só os dois da retirada (os outros: "não encontrada").
  Reserva _participante(Conta conta, int reservaId) {
    final reserva =
        _doacoes.reservas.where((r) => r.id == reservaId).firstOrNull ??
        (throw _naoEncontrada);
    final doacao = _doacoes.porId(reserva.doacaoId);
    final eu = conta.usuario.id;
    if (eu != reserva.ongId && eu != doacao.doadorId) throw _naoEncontrada;
    if (!_visivel(reserva)) throw _naoEncontrada;
    return reserva;
  }
}
