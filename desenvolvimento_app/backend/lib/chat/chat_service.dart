import 'package:shared_models/shared_models.dart';

import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import '../notificacoes/central_de_notificacoes.dart';
import 'chat_repository.dart';

/// O chat de cada retirada (T30, T31; RN30, RN31).
class ChatService {
  ChatService({
    required ChatRepository chat,
    required CentralDeNotificacoes avisos,
    required Relogio relogio,
  }) : _chat = chat,
       _avisos = avisos,
       _relogio = relogio;

  final ChatRepository _chat;
  final CentralDeNotificacoes _avisos;
  final Relogio _relogio;

  /// RN31: depois que a retirada termina, a conversa fica só de leitura
  /// por este tempo e depois some.
  static const tempoDeLeitura = Duration(days: 7);

  static const _naoEncontrada = NaoEncontradoException(
    'Conversa não encontrada.',
  );

  /// `GET /conversas` — T31.
  Future<List<ResumoConversa>> conversas(UsuarioAutenticado usuario) =>
      _chat.conversasDe(usuario.id, _relogio.agora().subtract(tempoDeLeitura));

  /// `GET /conversas/{reservaId}/mensagens?depois=`
  Future<RespostaMensagens> mensagens(
    UsuarioAutenticado usuario,
    int reservaId,
    int depoisDe,
  ) async {
    final info = await _daConversa(usuario, reservaId);
    return RespostaMensagens(
      mensagens: await _chat.mensagens(reservaId, depoisDe),
      somenteLeitura: !info.ativa,
      lidasAte: await _chat.lidasAte(reservaId, usuario.id),
    );
  }

  /// `POST /conversas/{reservaId}/mensagens` — envia e avisa a outra
  /// pessoa.
  Future<Mensagem> enviar(
    UsuarioAutenticado usuario,
    int reservaId,
    String texto,
  ) async {
    final erro = Mensagem.validar(texto);
    if (erro != null) throw ValidacaoException(erro);
    final info = await _daConversa(usuario, reservaId);
    if (!info.ativa) {
      throw const ConflitoException(
        'CHAT_SOMENTE_LEITURA',
        'A retirada terminou: a conversa fica só para leitura.',
      );
    }
    final mensagem = await _chat.inserir(
      reservaId,
      autorId: usuario.id,
      texto: texto.trim(),
      agora: _relogio.agora(),
    );
    final ehOng = usuario.id == info.ongId;
    await _avisos.mensagemNova(
      info.outro(usuario.id),
      de: ehOng ? info.nomeOng : info.nomeDoador,
      mensagem: mensagem,
      doacaoId: info.doacaoId,
    );
    return mensagem;
  }

  /// `POST /conversas/{reservaId}/lidas` — "✓ lida" para a outra pessoa.
  Future<void> marcarLidas(UsuarioAutenticado usuario, int reservaId) async {
    await _daConversa(usuario, reservaId);
    await _chat.marcarLidas(reservaId, usuario.id, _relogio.agora());
  }

  /// RN30: só os dois participantes. RN31: 7 dias depois do fim, some.
  /// Para os outros, "não encontrada" (nem contamos que existe).
  Future<ConversaInfo> _daConversa(
    UsuarioAutenticado usuario,
    int reservaId,
  ) async {
    final info = await _chat.info(reservaId);
    if (info == null || !info.participa(usuario.id)) throw _naoEncontrada;
    final fim = info.encerradaEm;
    if (!info.ativa &&
        fim != null &&
        fim.isBefore(_relogio.agora().subtract(tempoDeLeitura))) {
      throw _naoEncontrada;
    }
    return info;
  }
}
