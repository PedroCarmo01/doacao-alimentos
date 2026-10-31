import 'package:shared_models/shared_models.dart';

import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import '../doacoes/doacao_repository.dart';
import '../notificacoes/central_de_notificacoes.dart';
import 'penalidades.dart';
import 'reserva_exceptions.dart';
import 'reserva_repository.dart';

/// O fim da retirada do lado do DOADOR: confirmar com o código (RN27, T13)
/// ou marcar "A ONG não compareceu" (RN28).
class ConfirmacaoService {
  ConfirmacaoService({
    required ReservaRepository reservas,
    required DoacaoRepository doacoes,
    required Penalidades penalidades,
    required CentralDeNotificacoes avisos,
    required Relogio relogio,
  }) : _reservas = reservas,
       _doacoes = doacoes,
       _penalidades = penalidades,
       _avisos = avisos,
       _relogio = relogio;

  final ReservaRepository _reservas;
  final DoacaoRepository _doacoes;
  final Penalidades _penalidades;
  final CentralDeNotificacoes _avisos;
  final Relogio _relogio;

  /// `POST /reservas/{id}/confirmar` — RN27: o doador digita o código que a
  /// ONG mostra. Certo → retirada e doação concluídas. Errado 5 vezes
  /// seguidas → 10 minutos sem poder tentar.
  Future<Reserva> confirmar(
    UsuarioAutenticado usuario,
    int reservaId,
    String codigo,
  ) async {
    final erro = ValidadorReserva.codigo(codigo);
    if (erro != null) throw ValidacaoException(erro);
    final reserva = await _doDoador(usuario, reservaId);
    final agora = _relogio.agora();
    if (!reserva.estaAtiva || reserva.estaVencida(agora)) {
      throw ErrosDaRetirada.naoAtiva;
    }

    final controle = (await _reservas.controleDoCodigo(reservaId))!;
    final bloqueio = controle.bloqueadoAte;
    if (bloqueio != null && bloqueio.isAfter(agora)) {
      throw TentativasEsgotadasException(bloqueio.difference(agora));
    }
    if (controle.codigo != codigo.trim()) {
      await _registrarErro(reservaId, controle.tentativas + 1, agora);
    }

    if (!await _reservas.concluir(reservaId, agora)) {
      throw ErrosDaRetirada.naoAtiva;
    }
    final doacao = await _doacoes.buscar(reserva.doacaoId);
    if (doacao != null) await _avisos.retiradaConfirmada(doacao, reserva);
    return (await _reservas.buscar(reservaId))!.semCodigo(); // RN26
  }

  /// `POST /reservas/{id}/nao-compareceu` — RN28: depois do prazo, o
  /// doador encerra na hora, com o mesmo efeito da expiração (RN22).
  Future<void> naoCompareceu(UsuarioAutenticado usuario, int reservaId) async {
    final reserva = await _doDoador(usuario, reservaId);
    final agora = _relogio.agora();
    if (!reserva.estaAtiva) throw ErrosDaRetirada.naoAtiva;
    if (!reserva.estaVencida(agora)) throw ErrosDaRetirada.prazoNaoAcabou;
    final resposta = await _penalidades.encerrar(
      reserva,
      status: StatusReserva.expirada,
      agora: agora,
      contaDesistencia: true,
    );
    if (resposta == null) throw ErrosDaRetirada.naoAtiva;
  }

  /// Guarda o erro e SEMPRE lança: "código incorreto" ou, no 5º erro
  /// seguido, "tentativas esgotadas" (e zera a contagem para depois).
  Future<Never> _registrarErro(int reservaId, int erros, DateTime agora) async {
    if (erros >= RegrasDaRetirada.tentativasDoCodigo) {
      await _reservas.salvarTentativas(
        reservaId,
        tentativas: 0,
        bloqueadoAte: agora.add(RegrasDaRetirada.bloqueioDoCodigo),
      );
      throw TentativasEsgotadasException(RegrasDaRetirada.bloqueioDoCodigo);
    }
    await _reservas.salvarTentativas(reservaId, tentativas: erros);
    throw CodigoIncorretoException(RegrasDaRetirada.tentativasDoCodigo - erros);
  }

  /// A retirada, se a doação for do doador logado. Senão, "não encontrada".
  Future<Reserva> _doDoador(UsuarioAutenticado usuario, int reservaId) async {
    usuario.exigirTipo(TipoUsuario.doador);
    final reserva = await _reservas.buscar(reservaId);
    final doacao = reserva == null
        ? null
        : await _doacoes.buscar(reserva.doacaoId);
    if (reserva == null || doacao == null || doacao.doadorId != usuario.id) {
      throw const NaoEncontradoException('Retirada não encontrada.');
    }
    return reserva;
  }
}
