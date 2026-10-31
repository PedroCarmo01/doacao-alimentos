import 'dart:math';

import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';
import 'chat_fake.dart';
import 'contas_fake.dart';
import 'doacoes_fake.dart';
import 'notificacoes_fake.dart';

/// As retiradas do modo Fake, com as MESMAS regras e códigos de erro do
/// `ReservaService` e do `ConfirmacaoService` do backend (RN20–RN29).
class RetiradasFake {
  RetiradasFake(
    this._relogio,
    this._contas,
    this._doacoes,
    this._avisos,
    this._chat,
    this.regras,
  );

  final Relogio _relogio;
  final ContasFake _contas;
  final DoacoesFake _doacoes;
  final NotificacoesFake _avisos;
  final ChatFake _chat;
  final RegrasDaRetirada regras;
  final _sorteio = Random();

  /// RN27: erros seguidos e bloqueio de cada retirada (só o "servidor" vê).
  final Map<int, int> _tentativas = {};
  final Map<int, DateTime> _bloqueadoAte = {};

  DateTime get _agora => _relogio.agora();

  static ApiException _conflito(String codigo, String mensagem) =>
      ApiException(codigo: codigo, mensagem: mensagem, status: 409);

  static const _naoEncontrada = ApiException(
    codigo: 'NAO_ENCONTRADO',
    mensagem: 'Retirada não encontrada.',
    status: 404,
  );
  static final _naoAtiva = _conflito(
    'RESERVA_NAO_ATIVA',
    'Esta retirada não está mais em andamento.',
  );

  // ---------------------------------------------------------------- ONG

  /// "Vou retirar" (RN20–RN26).
  Reserva aceitar(Conta ong, int doacaoId) {
    expirarVencidas(); // RN29
    if (ong.perfil.estaSuspensa(_agora)) {
      throw _conflito(
        'ONG_SUSPENSA',
        'Sua conta está suspensa por desistências. Você ainda vê as '
            'doações, mas não pode aceitar.',
      );
    }
    final doacao = _doacoes.porId(doacaoId);
    if (_doacoes.bloqueios.contains('${ong.usuario.id}-$doacaoId')) {
      throw _conflito(
        'ONG_BLOQUEADA_NESTA_DOACAO',
        'Você desistiu desta doação e não pode aceitá-la de novo.',
      );
    }
    if (!doacao.podeSerReservada(_agora)) {
      throw _conflito(
        'DOACAO_INDISPONIVEL',
        'Que pena! Outra ONG aceitou esta doação primeiro.',
      );
    }
    if (daOng(ong, SituacaoDaLista.ativas).length >=
        regras.retiradasSimultaneas) {
      throw _conflito(
        'LIMITE_DE_RETIRADAS',
        'Você já tem ${regras.retiradasSimultaneas} retiradas em andamento. '
            'Conclua uma antes de aceitar outra.',
      );
    }
    final reserva = Reserva(
      id: _doacoes.novoId(),
      doacaoId: doacaoId,
      ongId: ong.usuario.id,
      status: StatusReserva.ativa,
      reservadoEm: _agora,
      expiraEm: regras.prazoFinal(agora: _agora, janelaFim: doacao.janelaFim),
      codigoRetirada: _sorteio.nextInt(10000).toString().padLeft(4, '0'),
      tituloDoacao: doacao.titulo,
      nomeOng: ong.perfil.nomeOrganizacao,
    );
    _doacoes.reservas.add(reserva);
    _doacoes.salvar(doacao.copyWith(status: StatusDoacao.reservada));
    _chat.doSistema(
      reserva.id,
      '${ong.perfil.nomeOrganizacao} aceitou a doação.',
    );
    _avisos.avisar(
      doacao.doadorId,
      TipoNotificacao.doacaoAceita,
      titulo: 'Doação aceita',
      corpo: '${ong.perfil.nomeOrganizacao} vai retirar "${doacao.titulo}".',
      doacaoId: doacao.id,
      reservaId: reserva.id,
    );
    return reserva;
  }

  List<Reserva> daOng(Conta ong, SituacaoDaLista situacao) {
    expirarVencidas();
    final querAtivas = situacao == SituacaoDaLista.ativas;
    return [
      for (final r in _doacoes.reservas)
        if (r.ongId == ong.usuario.id && r.estaAtiva == querAtivas) r,
    ]..sort((a, b) => b.reservadoEm.compareTo(a.reservadoEm));
  }

  Reserva daOngPorId(Conta ong, int reservaId) {
    expirarVencidas();
    final reserva = _porId(reservaId);
    if (reserva.ongId != ong.usuario.id) throw _naoEncontrada;
    return reserva;
  }

  SituacaoDaOng situacao(Conta ong) {
    final ativas = daOng(ong, SituacaoDaLista.ativas);
    final perfil = _contas.porId(ong.usuario.id)!.perfil;
    return SituacaoDaOng(
      desistenciasRecentes: _desistenciasRecentes(ong.usuario.id),
      suspensaAte: perfil.estaSuspensa(_agora) ? perfil.suspensaAte : null,
      ativas: ativas,
      regras: regras,
    );
  }

  /// RN22–RN24: dentro da tolerância não conta; depois, conta e bloqueia.
  RespostaDesistencia desistir(Conta ong, int reservaId) {
    final reserva = daOngPorId(ong, reservaId);
    if (!reserva.estaAtiva) throw _naoAtiva;
    return _encerrar(
      reserva,
      StatusReserva.canceladaOng,
      contaDesistencia: !reserva.dentroDaTolerancia(_agora, regras.tolerancia),
    );
  }

  // ------------------------------------------------------------- doador

  /// RN27: código certo conclui; 5 erros seguidos bloqueiam por 10 min.
  Reserva confirmar(Conta doador, int reservaId, String codigo) {
    final erro = ValidadorReserva.codigo(codigo);
    if (erro != null) {
      throw ApiException(codigo: 'VALIDACAO', mensagem: erro, status: 400);
    }
    final reserva = _doDoador(doador, reservaId);
    if (!reserva.estaAtiva || reserva.estaVencida(_agora)) throw _naoAtiva;
    final bloqueio = _bloqueadoAte[reservaId];
    if (bloqueio != null && bloqueio.isAfter(_agora)) {
      throw _esgotadas(bloqueio);
    }
    if (reserva.codigoRetirada != codigo.trim()) {
      final erros = (_tentativas[reservaId] ?? 0) + 1;
      if (erros >= RegrasDaRetirada.tentativasDoCodigo) {
        _tentativas[reservaId] = 0;
        _bloqueadoAte[reservaId] = _agora.add(
          RegrasDaRetirada.bloqueioDoCodigo,
        );
        throw _esgotadas(_bloqueadoAte[reservaId]!);
      }
      _tentativas[reservaId] = erros;
      final restam = RegrasDaRetirada.tentativasDoCodigo - erros;
      throw ApiException(
        codigo: 'CODIGO_INCORRETO',
        mensagem:
            'Código incorreto. '
            '${restam == 1 ? 'Resta 1 tentativa' : 'Restam $restam tentativas'}'
            ' antes de bloquear por 10 minutos.',
        status: 400,
      );
    }
    _doacoes.trocarReserva(
      reserva,
      StatusReserva.concluida,
      encerradaEm: _agora,
    );
    final doacao = _doacoes.porId(reserva.doacaoId);
    _doacoes.salvar(doacao.copyWith(status: StatusDoacao.concluida));
    _chat.doSistema(reservaId, 'Retirada confirmada. Obrigado!');
    for (final id in [doacao.doadorId, reserva.ongId]) {
      _avisos.avisar(
        id,
        TipoNotificacao.retiradaConfirmada,
        titulo: 'Retirada confirmada!',
        corpo: '"${doacao.titulo}" foi retirada. Obrigado!',
        doacaoId: doacao.id,
        reservaId: reservaId,
      );
    }
    return _porId(reservaId).semCodigo();
  }

  /// RN28: depois do prazo, o mesmo efeito da expiração.
  void naoCompareceu(Conta doador, int reservaId) {
    final reserva = _doDoador(doador, reservaId);
    if (!reserva.estaAtiva) throw _naoAtiva;
    if (!reserva.estaVencida(_agora)) {
      throw _conflito(
        'PRAZO_NAO_ACABOU',
        'Só dá para marcar "A ONG não compareceu" depois que o prazo acabar.',
      );
    }
    _encerrar(reserva, StatusReserva.expirada, contaDesistencia: true);
  }

  // ----------------------------------------------------------- internos

  /// RN29: o "job" do Fake roda antes de cada consulta.
  void expirarVencidas() {
    for (final reserva in List.of(_doacoes.reservas)) {
      if (reserva.estaVencida(_agora)) {
        _encerrar(reserva, StatusReserva.expirada, contaDesistencia: true);
      }
    }
  }

  RespostaDesistencia _encerrar(
    Reserva reserva,
    StatusReserva status, {
    required bool contaDesistencia,
  }) {
    _doacoes.trocarReserva(
      reserva,
      status,
      encerradaEm: _agora,
      contouDesistencia: contaDesistencia,
    );
    final doacao = _doacoes.porId(reserva.doacaoId);
    _doacoes.salvar(doacao.copyWith(status: StatusDoacao.disponivel));
    DateTime? suspensaAte;
    final total = _desistenciasRecentes(reserva.ongId);
    if (contaDesistencia) {
      _doacoes.bloqueios.add('${reserva.ongId}-${reserva.doacaoId}'); // RN22
      final perfil = _contas.porId(reserva.ongId)!.perfil;
      if (total >= regras.desistenciasParaSuspender &&
          !perfil.estaSuspensa(_agora)) {
        suspensaAte = _agora.add(regras.suspensao); // RN24
        _contas.suspender(reserva.ongId, suspensaAte);
      }
    }
    _avisarSemRetirar(reserva, status == StatusReserva.expirada);
    return RespostaDesistencia(
      contouDesistencia: contaDesistencia,
      desistenciasRecentes: total,
      suspensaAte: suspensaAte,
    );
  }

  /// Os avisos de quando a comida não saiu (como no backend).
  void _avisarSemRetirar(Reserva reserva, bool expirou) {
    final doacao = _doacoes.porId(reserva.doacaoId);
    _chat.doSistema(
      reserva.id,
      expirou ? 'O prazo da retirada acabou.' : 'A ONG desistiu da retirada.',
    );
    if (expirou) {
      _avisos.avisar(
        reserva.ongId,
        TipoNotificacao.prazoAcabouOng,
        titulo: 'O prazo acabou',
        corpo: 'A doação "${doacao.titulo}" voltou para outras ONGs.',
        doacaoId: doacao.id,
        reservaId: reserva.id,
      );
    }
    _avisos.avisar(
      doacao.doadorId,
      TipoNotificacao.prazoAcabouDoador,
      titulo: expirou ? 'A ONG não retirou a tempo' : 'A ONG desistiu',
      corpo: 'Sua doação "${doacao.titulo}" está disponível de novo.',
      doacaoId: doacao.id,
      reservaId: reserva.id,
    );
    if (doacao.podeSerReservada(_agora)) {
      _avisos.avisarOngsProximas(doacao, deNovo: true);
    }
  }

  int _desistenciasRecentes(int ongId) {
    final desde = _agora.subtract(regras.janelaDesistencias);
    return _doacoes.reservas
        .where(
          (r) =>
              r.ongId == ongId &&
              r.contouDesistencia &&
              !r.encerradaEm!.isBefore(desde),
        )
        .length;
  }

  Reserva _porId(int id) =>
      _doacoes.reservas.where((r) => r.id == id).firstOrNull ??
      (throw _naoEncontrada);

  Reserva _doDoador(Conta doador, int reservaId) {
    final reserva = _porId(reservaId);
    if (_doacoes.porId(reserva.doacaoId).doadorId != doador.usuario.id) {
      throw _naoEncontrada;
    }
    return reserva;
  }

  static ApiException _esgotadas(DateTime ate) => ApiException(
    codigo: 'TENTATIVAS_ESGOTADAS',
    mensagem:
        'Muitos códigos errados. Tente de novo depois das '
        '${ate.toLocal().hour.toString().padLeft(2, '0')}:'
        '${ate.toLocal().minute.toString().padLeft(2, '0')}.',
    status: 429,
  );
}
