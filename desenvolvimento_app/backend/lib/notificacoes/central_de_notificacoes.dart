import 'package:shared_models/shared_models.dart';

import '../chat/chat_repository.dart';
import 'enviador_de_push.dart';
import 'notificacao_repository.dart';

/// O ÚNICO lugar que cria notificações (seção 9 da especificação).
///
/// Cada aviso é sempre GRAVADO na tabela `notificacoes` e depois entregue
/// ao [EnviadorDePush]. Os Services nunca falam com o enviador: falam com a
/// central, pelo nome do evento (`doacaoAceita`, `retiradaConfirmada`...).
/// Os textos ficam todos aqui.
///
/// Os eventos da retirada também viram MENSAGENS DO SISTEMA no chat
/// ("ONG Mãos Amigas aceitou a doação"), para a conversa contar a história
/// da retirada (T30). O texto não leva a hora: o app mostra a hora da
/// mensagem no fuso do celular, igual às outras mensagens.
class CentralDeNotificacoes {
  CentralDeNotificacoes({
    required NotificacaoRepository notificacoes,
    required EnviadorDePush enviador,
    required ChatRepository chat,
    required Relogio relogio,
    required int fusoHorarioUtc,
  }) : _notificacoes = notificacoes,
       _enviador = enviador,
       _chat = chat,
       _relogio = relogio,
       _fuso = fusoHorarioUtc;

  final NotificacaoRepository _notificacoes;
  final EnviadorDePush _enviador;
  final ChatRepository _chat;
  final Relogio _relogio;
  final int _fuso;

  /// Grava e entrega um aviso. Devolve `null` se a pessoa desligou esse
  /// tipo de aviso no Perfil (T50). Os avisos da retirada (aceite, prazo,
  /// confirmação, suspensão) não podem ser desligados: chegam sempre.
  Future<Notificacao?> avisar(
    int usuarioId,
    TipoNotificacao tipo, {
    required String titulo,
    required String corpo,
    int? doacaoId,
    int? reservaId,
  }) async {
    if (!await _querReceber(usuarioId, tipo)) return null;
    final notificacao = await _notificacoes.criar(
      NovaNotificacao(
        usuarioId: usuarioId,
        tipo: tipo,
        titulo: titulo,
        corpo: corpo,
        criadoEm: _relogio.agora(),
        doacaoId: doacaoId,
        reservaId: reservaId,
      ),
    );
    await _enviador.enviar(usuarioId, notificacao);
    return notificacao;
  }

  Future<bool> _querReceber(int usuarioId, TipoNotificacao tipo) async {
    final preferencias = switch (tipo) {
      TipoNotificacao.mensagemNova ||
      TipoNotificacao.apoioNovo ||
      TipoNotificacao.doacaoNova ||
      TipoNotificacao.doacaoDisponivelDeNovo =>
        await _notificacoes.preferencias(usuarioId),
      _ => null, // os importantes: sempre
    };
    if (preferencias == null) return true;
    return switch (tipo) {
      TipoNotificacao.mensagemNova => preferencias.mensagens,
      TipoNotificacao.apoioNovo => preferencias.comunidade,
      _ => preferencias.doacoes,
    };
  }

  /// RN11: avisa as ONGs com a busca ativa que têm a doação dentro do
  /// raio delas (sem as suspensas e as bloqueadas). [deNovo] = a doação
  /// voltou depois de uma retirada que não aconteceu. Devolve quantas.
  Future<int> avisarOngsProximas(Doacao doacao, {bool deNovo = false}) async {
    final ongs = await _notificacoes.ongsParaAvisar(
      doacao.id,
      _relogio.agora(),
    );
    var avisadas = 0;
    for (final ong in ongs) {
      final km = Geo.distanciaKm(ong.coordenadas, doacao.coordenadas);
      if (km > ong.raioKm) continue;
      await avisar(
        ong.usuarioId,
        deNovo
            ? TipoNotificacao.doacaoDisponivelDeNovo
            : TipoNotificacao.doacaoNova,
        titulo: deNovo
            ? 'Doação disponível de novo'
            : 'Doação nova perto de você',
        corpo:
            '${deNovo ? 'Disponível de novo' : 'Doação nova'} a ${_km(km)}: '
            '${doacao.quantidadeTexto} de ${doacao.titulo}'
            '${doacao.nomeDoador == null ? '' : ' — ${doacao.nomeDoador}'}. '
            'Retirar até ${_hora(doacao.janelaFim)}.',
        doacaoId: doacao.id,
      );
      avisadas++;
    }
    return avisadas;
  }

  /// Uma ONG aceitou: avisa o doador e abre o chat com a mensagem do
  /// sistema.
  Future<void> doacaoAceita(Doacao doacao, Reserva reserva) async {
    final ong = reserva.nomeOng ?? 'Uma ONG';
    await _noChat(reserva.id, '$ong aceitou a doação.');
    await avisar(
      doacao.doadorId,
      TipoNotificacao.doacaoAceita,
      titulo: 'Doação aceita',
      corpo:
          '$ong vai retirar "${doacao.titulo}". '
          'Prazo: ${_hora(reserva.expiraEm)}.',
      doacaoId: doacao.id,
      reservaId: reserva.id,
    );
  }

  /// Mensagem nova no chat: avisa a outra pessoa (T30).
  Future<void> mensagemNova(
    int destinatarioId, {
    required String de,
    required Mensagem mensagem,
    required int doacaoId,
  }) => avisar(
    destinatarioId,
    TipoNotificacao.mensagemNova,
    titulo: de,
    corpo: mensagem.texto,
    doacaoId: doacaoId,
    reservaId: mensagem.reservaId,
  );

  /// Faltam poucos minutos: avisa a ONG (uma vez só por retirada).
  Future<void> prazoAcabando(Reserva reserva) async {
    if (await _notificacoes.existe(TipoNotificacao.prazoAcabando, reserva.id)) {
      return;
    }
    final minutos = (reserva.tempoRestante(_relogio.agora()).inSeconds / 60)
        .ceil();
    await avisar(
      reserva.ongId,
      TipoNotificacao.prazoAcabando,
      titulo: 'O prazo está acabando',
      corpo:
          'Faltam $minutos minuto(s) para retirar '
          '"${reserva.tituloDoacao ?? 'a doação'}".',
      doacaoId: reserva.doacaoId,
      reservaId: reserva.id,
    );
  }

  /// A retirada terminou sem a comida sair do doador (prazo acabou, a ONG
  /// desistiu ou não compareceu). Avisa a ONG, o doador e, se a doação
  /// ainda dá tempo, as outras ONGs (RN22).
  Future<void> retiradaSemRetirar(
    Doacao doacao,
    Reserva reserva, {
    required bool expirou,
    required bool contouDesistencia,
  }) async {
    await _noChat(
      reserva.id,
      expirou
          ? 'O prazo da retirada acabou.'
          : '${reserva.nomeOng ?? 'A ONG'} desistiu da retirada.',
    );
    if (expirou) {
      await avisar(
        reserva.ongId,
        TipoNotificacao.prazoAcabouOng,
        titulo: 'O prazo acabou',
        corpo:
            'O prazo para retirar "${doacao.titulo}" acabou e a doação voltou '
            'para outras ONGs.'
            '${contouDesistencia ? ' Isso contou como desistência.' : ''}',
        doacaoId: doacao.id,
        reservaId: reserva.id,
      );
    }
    final volta = doacao.podeSerReservada(_relogio.agora());
    await avisar(
      doacao.doadorId,
      TipoNotificacao.prazoAcabouDoador,
      titulo: expirou ? 'A ONG não retirou a tempo' : 'A ONG desistiu',
      corpo:
          '${expirou ? 'A ONG não retirou a tempo' : '${reserva.nomeOng ?? 'A ONG'} desistiu da retirada'}. '
          '${volta ? 'Sua doação está disponível de novo e as ONGs próximas foram avisadas.' : 'O horário de retirada da sua doação já acabou.'}',
      doacaoId: doacao.id,
      reservaId: reserva.id,
    );
    if (volta) await avisarOngsProximas(doacao, deNovo: true);
  }

  /// RN27: o doador digitou o código certo. Avisa os dois.
  Future<void> retiradaConfirmada(Doacao doacao, Reserva reserva) async {
    await _noChat(reserva.id, 'Retirada confirmada. Obrigado!');
    for (final usuarioId in [doacao.doadorId, reserva.ongId]) {
      await avisar(
        usuarioId,
        TipoNotificacao.retiradaConfirmada,
        titulo: 'Retirada confirmada!',
        corpo:
            '"${doacao.titulo}" foi retirada. Obrigado por evitar o desperdício.',
        doacaoId: doacao.id,
        reservaId: reserva.id,
      );
    }
  }

  /// RN12: o doador cancelou uma doação reservada. Avisa a ONG.
  Future<void> doacaoCancelada(
    Doacao doacao,
    Reserva reserva,
    String? motivo,
  ) async {
    await _noChat(
      reserva.id,
      'O doador cancelou a doação.${motivo == null ? '' : ' Motivo: $motivo'}',
    );
    await avisar(
      reserva.ongId,
      TipoNotificacao.doacaoCancelada,
      titulo: 'Doação cancelada',
      corpo:
          'O doador cancelou a doação "${doacao.titulo}".'
          '${motivo == null ? '' : ' Motivo: $motivo'}',
      doacaoId: doacao.id,
      reservaId: reserva.id,
    );
  }

  /// Alguém apoiou uma publicação: avisa o autor (se ele quiser, T50).
  Future<void> apoioNovo(Publicacao publicacao) => avisar(
    publicacao.autorId,
    TipoNotificacao.apoioNovo,
    titulo: 'Apoio na Comunidade',
    corpo:
        'Sua publicação recebeu um apoio: '
        '"${_trecho(publicacao.texto)}"',
  );

  /// Os primeiros caracteres de um texto longo.
  static String _trecho(String texto) =>
      texto.length <= 60 ? texto : '${texto.substring(0, 57)}...';

  /// Uma mensagem do SISTEMA (sem autor) na conversa da retirada.
  Future<void> _noChat(int reservaId, String texto) => _chat.inserir(
    reservaId,
    autorId: null,
    texto: texto,
    agora: _relogio.agora(),
  );

  /// RN24: a ONG foi suspensa.
  Future<void> suspensao(int ongId, DateTime ate) => avisar(
    ongId,
    TipoNotificacao.suspensao,
    titulo: 'Conta suspensa',
    corpo:
        'Sua conta está suspensa até ${_diaHora(ate)} por desistências. '
        'Você ainda vê as doações, mas não pode aceitar.',
  );

  // ----------------------------------------------------------- formatos

  DateTime _local(DateTime instante) =>
      instante.toUtc().add(Duration(hours: _fuso));

  static String _dois(int n) => n.toString().padLeft(2, '0');

  /// "18:00", no fuso do `.env` (Brasília).
  String _hora(DateTime instante) {
    final local = _local(instante);
    return '${_dois(local.hour)}:${_dois(local.minute)}';
  }

  /// "12/11 às 14:00"
  String _diaHora(DateTime instante) {
    final local = _local(instante);
    return '${_dois(local.day)}/${_dois(local.month)} às ${_hora(instante)}';
  }

  /// "600 m" ou "1,2 km"
  static String _km(double km) => km < 1
      ? '${(km * 1000).round()} m'
      : '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}
