import 'package:shared_models/shared_models.dart';

import '../auth/usuario_repository.dart';
import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import 'doacao_repository.dart';

/// Regras das doações do lado do doador (RN10, RN12, RN13; telas T10–T12).
///
/// Não conhece HTTP nem SQL: recebe dados, aplica regras, devolve modelos
/// ou lança exceções. As fotos ficam no `FotoDoacaoService`.
class DoacaoService {
  DoacaoService({
    required DoacaoRepository doacoes,
    required UsuarioRepository usuarios,
    required Relogio relogio,
    required int fusoHorarioUtc,
  }) : _doacoes = doacoes,
       _usuarios = usuarios,
       _relogio = relogio,
       _fuso = fusoHorarioUtc;

  final DoacaoRepository _doacoes;
  final UsuarioRepository _usuarios;
  final Relogio _relogio;
  final int _fuso;

  static const _naoEncontrada = NaoEncontradoException(
    'Doação não encontrada.',
  );

  /// `POST /doacoes` — RN10. Se o app não mandar localização, usa a do
  /// perfil do doador (o "endereço padrão de retirada" do cadastro).
  Future<RespostaPublicacao> publicar(
    UsuarioAutenticado usuario,
    DadosNovaDoacao recebidos,
  ) async {
    usuario.exigirTipo(TipoUsuario.doador); // RN10: só doador publica
    final dados = await _comLocalizacao(usuario.id, recebidos);
    _validar(dados);
    final doacao = await _doacoes.criar(
      dados,
      doadorId: usuario.id,
      criadoEm: _relogio.agora(),
    );
    // RN11: na etapa 5, a CentralDeNotificacoes avisa as ONGs próximas e
    // devolve quantas foram avisadas. Até lá, ninguém é avisado.
    return RespostaPublicacao(doacao: doacao, ongsAvisadas: 0);
  }

  /// `PUT /doacoes/{id}` — RN12: só enquanto ninguém aceitou.
  Future<Doacao> editar(
    UsuarioAutenticado usuario,
    int doacaoId,
    DadosNovaDoacao recebidos,
  ) async {
    final atual = await _doDono(usuario, doacaoId);
    if (!atual.podeSerEditada) {
      throw const ConflitoException(
        'DOACAO_NAO_EDITAVEL',
        'Só dá para editar enquanto nenhuma ONG aceitou a doação.',
      );
    }
    final dados = await _comLocalizacao(usuario.id, recebidos);
    _validar(dados);
    return _doacoes.atualizar(doacaoId, dados);
  }

  /// `DELETE /doacoes/{id}` — RN12. Doação reservada exige motivo; a ONG
  /// é avisada (etapa 5) e NÃO conta desistência.
  Future<void> cancelar(
    UsuarioAutenticado usuario,
    int doacaoId, {
    String? motivo,
  }) async {
    final doacao = await _doDono(usuario, doacaoId);
    if (!doacao.podeSerCancelada) {
      throw const ConflitoException(
        'DOACAO_NAO_CANCELAVEL',
        'Esta doação já foi concluída, cancelada ou expirou.',
      );
    }
    final motivoLimpo = motivo?.trim();
    if (doacao.cancelamentoExigeMotivo) {
      final erro = ValidadorDoacao.motivoCancelamento(motivoLimpo);
      if (erro != null) throw ValidacaoException(erro);
    }
    await _doacoes.cancelar(
      doacaoId,
      motivo: (motivoLimpo == null || motivoLimpo.isEmpty) ? null : motivoLimpo,
      agora: _relogio.agora(),
    );
  }

  /// `GET /doacoes?situacao=` — T10, abas Ativas e Histórico.
  Future<List<Doacao>> listarMinhas(
    UsuarioAutenticado usuario,
    SituacaoDaLista situacao,
  ) async {
    usuario.exigirTipo(TipoUsuario.doador);
    await expirarJanelasEncerradas();
    return _doacoes.doDoador(usuario.id, situacao);
  }

  /// `GET /doacoes/{id}` — o doador vê as próprias; a ONG vê as que pode
  /// aceitar (disponível, janela aberta, não bloqueada — RN22) e a que ela
  /// mesma está retirando. Para os outros, "não encontrada".
  Future<DetalheDoacao> detalhar(UsuarioAutenticado usuario, int id) async {
    await expirarJanelasEncerradas();
    final doacao = await _doacoes.buscar(id);
    if (doacao == null) throw _naoEncontrada;
    final reserva = await _doacoes.reservaAtiva(id);

    if (usuario.ehDoador) {
      if (doacao.doadorId != usuario.id) throw _naoEncontrada;
      return DetalheDoacao(
        doacao: doacao,
        // RN26: o código de retirada é só da ONG. O doador recebe a
        // reserva sem ele e PEDE o código à ONG na hora da retirada.
        reserva: reserva?.semCodigo(),
        ong: reserva == null ? null : await _doacoes.resumo(reserva.ongId),
      );
    }
    final ehDela = reserva != null && reserva.ongId == usuario.id;
    final podeVer =
        doacao.podeSerReservada(_relogio.agora()) &&
        !await _doacoes.ongBloqueada(usuario.id, id);
    if (!ehDela && !podeVer) throw _naoEncontrada;
    return DetalheDoacao(
      doacao: doacao,
      reserva: ehDela ? reserva : null,
      doador: await _doacoes.resumo(doacao.doadorId),
    );
  }

  /// RN13. Chamada antes das consultas (e, na etapa 4, também pelo
  /// `ExpiracaoJob` a cada 30 s).
  Future<int> expirarJanelasEncerradas() =>
      _doacoes.expirarJanelasEncerradas(_relogio.agora());

  /// A doação, se for do [usuario] (doador). Senão, "não encontrada": não
  /// contamos a ninguém que a doação de outra pessoa existe.
  Future<Doacao> _doDono(UsuarioAutenticado usuario, int doacaoId) async {
    usuario.exigirTipo(TipoUsuario.doador);
    final doacao = await _doacoes.buscar(doacaoId);
    if (doacao == null || doacao.doadorId != usuario.id) throw _naoEncontrada;
    return doacao;
  }

  void _validar(DadosNovaDoacao dados) {
    final agora = _relogio.agora();
    final erros = ValidadorDoacao.validar(
      dados,
      agora: agora,
      hoje: Calendario.dataNoFuso(agora, _fuso),
    );
    if (erros.isNotEmpty) {
      throw ValidacaoException(erros.first, detalhes: erros);
    }
  }

  /// Completa a localização e o endereço com os do perfil, se faltarem.
  Future<DadosNovaDoacao> _comLocalizacao(
    int doadorId,
    DadosNovaDoacao dados,
  ) async {
    final endereco = dados.endereco?.trim() ?? '';
    if (dados.possuiLocalizacao && endereco.isNotEmpty) return dados;
    final perfil = (await _usuarios.buscarConta(doadorId))?.perfil;
    if (perfil == null) throw const NaoAutenticadoException();
    return DadosNovaDoacao(
      titulo: dados.titulo.trim(),
      descricao: dados.descricao,
      categoria: dados.categoria,
      quantidade: dados.quantidade,
      unidade: dados.unidade,
      pesoKg: dados.pesoKg,
      conservacao: dados.conservacao,
      veiculo: dados.veiculo,
      validade: dados.validade,
      preparadoEm: dados.preparadoEm,
      janelaInicio: dados.janelaInicio,
      janelaFim: dados.janelaFim,
      endereco: endereco.isEmpty ? perfil.endereco : endereco,
      latitude: dados.latitude ?? perfil.latitude,
      longitude: dados.longitude ?? perfil.longitude,
      declaracaoAlimentosProprios: dados.declaracaoAlimentosProprios,
    );
  }
}
