import 'package:shared_models/shared_models.dart';

import '../auth/usuario_repository.dart';
import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import '../doacoes/doacao_repository.dart';
import '../notificacoes/central_de_notificacoes.dart';
import 'gerador_de_codigo.dart';
import 'penalidades.dart';
import 'reserva_exceptions.dart';
import 'reserva_repository.dart';

/// Retiradas do lado da ONG: aceitar ("Vou retirar"), listar, ver a
/// situação e desistir (RN20–RN26, RN29). A confirmação com o código fica
/// no `ConfirmacaoService`.
class ReservaService {
  ReservaService({
    required ReservaRepository reservas,
    required DoacaoRepository doacoes,
    required UsuarioRepository usuarios,
    required Penalidades penalidades,
    required CentralDeNotificacoes avisos,
    required RegrasDaRetirada regras,
    required GeradorDeCodigo codigos,
    required Relogio relogio,
  }) : _reservas = reservas,
       _doacoes = doacoes,
       _usuarios = usuarios,
       _penalidades = penalidades,
       _avisos = avisos,
       _regras = regras,
       _codigos = codigos,
       _relogio = relogio;

  final ReservaRepository _reservas;
  final DoacaoRepository _doacoes;
  final UsuarioRepository _usuarios;
  final Penalidades _penalidades;
  final CentralDeNotificacoes _avisos;
  final RegrasDaRetirada _regras;
  final GeradorDeCodigo _codigos;
  final Relogio _relogio;

  /// `POST /reservas` — "Vou retirar". As conferências vão da mais simples
  /// para a mais cara; a última (e definitiva) é a trava no banco (RN20).
  Future<Reserva> aceitar(UsuarioAutenticado usuario, int doacaoId) async {
    usuario.exigirTipo(TipoUsuario.ong);
    final agora = _relogio.agora();
    await expirarVencidas(); // RN29: não espera o job

    final perfil = await _perfil(usuario.id);
    if (perfil.estaSuspensa(agora)) throw ErrosDaRetirada.suspensa; // RN24
    final doacao = await _doacoes.buscar(doacaoId);
    if (doacao == null) {
      throw const NaoEncontradoException('Doação não encontrada.');
    }
    if (await _doacoes.ongBloqueada(usuario.id, doacaoId)) {
      throw ErrosDaRetirada.bloqueada; // RN22
    }
    if (!doacao.podeSerReservada(agora)) throw ErrosDaRetirada.indisponivel;
    final ativas = await _reservas.daOng(usuario.id, SituacaoDaLista.ativas);
    if (ativas.length >= _regras.retiradasSimultaneas) {
      throw ErrosDaRetirada.limite(_regras.retiradasSimultaneas); // RN25
    }

    final reserva = await _reservas.criarSeDisponivel(
      NovaReserva(
        doacaoId: doacaoId,
        ongId: usuario.id,
        codigo: _codigos.novo(), // RN26
        reservadoEm: agora,
        expiraEm: _regras.prazoFinal(agora: agora, janelaFim: doacao.janelaFim),
      ),
    );
    if (reserva == null) throw ErrosDaRetirada.indisponivel;
    await _avisos.doacaoAceita(doacao, reserva); // avisa o doador
    return reserva;
  }

  /// `GET /reservas?situacao=` — minhas retiradas (as ativas com o código).
  Future<List<Reserva>> listarMinhas(
    UsuarioAutenticado usuario,
    SituacaoDaLista situacao,
  ) async {
    usuario.exigirTipo(TipoUsuario.ong);
    await expirarVencidas();
    return _reservas.daOng(usuario.id, situacao);
  }

  /// `GET /reservas/{id}` — T23. Só a ONG dona.
  Future<Reserva> buscar(UsuarioAutenticado usuario, int reservaId) async {
    usuario.exigirTipo(TipoUsuario.ong);
    await expirarVencidas();
    return _daOng(usuario, reservaId);
  }

  /// `GET /reservas/situacao-da-ong` — para os avisos e a faixa no app.
  Future<SituacaoDaOng> situacao(UsuarioAutenticado usuario) async {
    usuario.exigirTipo(TipoUsuario.ong);
    await expirarVencidas();
    final agora = _relogio.agora();
    final perfil = await _perfil(usuario.id);
    return SituacaoDaOng(
      desistenciasRecentes: await _penalidades.desistenciasRecentes(
        usuario.id,
        agora,
      ),
      suspensaAte: perfil.estaSuspensa(agora) ? perfil.suspensaAte : null,
      ativas: await _reservas.daOng(usuario.id, SituacaoDaLista.ativas),
      regras: _regras,
    );
  }

  /// `DELETE /reservas/{id}` — a ONG desiste. Dentro da tolerância (RN23)
  /// não conta nem bloqueia; depois dela, conta (RN22, RN24).
  Future<RespostaDesistencia> desistir(
    UsuarioAutenticado usuario,
    int reservaId,
  ) async {
    usuario.exigirTipo(TipoUsuario.ong);
    final reserva = await _daOng(usuario, reservaId);
    final agora = _relogio.agora();
    final resposta = await _penalidades.encerrar(
      reserva,
      status: StatusReserva.canceladaOng,
      agora: agora,
      contaDesistencia: !reserva.dentroDaTolerancia(agora, _regras.tolerancia),
    );
    return resposta ?? (throw ErrosDaRetirada.naoAtiva);
  }

  /// RN22 + RN29: retiradas com o prazo vencido expiram, contam como
  /// desistência e a doação volta. Chamado pelo `ExpiracaoJob` (a cada
  /// 30 s) e antes das consultas. Devolve as que expiraram.
  Future<List<Reserva>> expirarVencidas() async {
    final agora = _relogio.agora();
    final expiradas = <Reserva>[];
    for (final reserva in await _reservas.vencidas(agora)) {
      final resposta = await _penalidades.encerrar(
        reserva,
        status: StatusReserva.expirada,
        agora: agora,
        contaDesistencia: true,
      );
      if (resposta != null) expiradas.add(reserva);
    }
    return expiradas;
  }

  /// "Faltam 10 minutos" para as retiradas perto do fim do prazo (uma vez
  /// só por retirada). Chamado pelo `ExpiracaoJob`.
  Future<void> avisarPrazosAcabando() async {
    final limite = _relogio.agora().add(avisoAntesDoFim);
    for (final reserva in await _reservas.vencidas(limite)) {
      await _avisos.prazoAcabando(reserva);
    }
  }

  /// Quanto tempo antes do fim do prazo a ONG é lembrada.
  static const avisoAntesDoFim = Duration(minutes: 10);

  /// A retirada, se for da ONG logada. Senão, "não encontrada".
  Future<Reserva> _daOng(UsuarioAutenticado usuario, int reservaId) async {
    final reserva = await _reservas.buscar(reservaId);
    if (reserva == null || reserva.ongId != usuario.id) {
      throw const NaoEncontradoException('Retirada não encontrada.');
    }
    return reserva;
  }

  Future<Perfil> _perfil(int usuarioId) async =>
      (await _usuarios.buscarConta(usuarioId))?.perfil ??
      (throw const NaoAutenticadoException());
}
