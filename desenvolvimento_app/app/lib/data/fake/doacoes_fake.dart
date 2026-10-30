import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';
import 'contas_fake.dart';

/// As doações do modo Fake: as "tabelas" (doações, retiradas, bloqueios) e
/// as MESMAS regras do `DoacaoService` do backend (RN10, RN12, RN13), com os
/// mesmos códigos de erro.
class DoacoesFake {
  DoacoesFake(this._relogio, this._contas, {required this.fusoHorarioUtc});

  final Relogio _relogio;
  final ContasFake _contas;
  final int fusoHorarioUtc;

  final List<Doacao> doacoes = [];
  final List<Reserva> reservas = [];

  /// RN22: pares "ong-doacao" que não podem mais ser aceitos.
  final Set<String> bloqueios = {};
  int _proximoId = 1;

  static const naoEncontrada = ApiException(
    codigo: 'NAO_ENCONTRADO',
    mensagem: 'Doação não encontrada.',
    status: 404,
  );

  DateTime get _agora => _relogio.agora();
  int novoId() => _proximoId++;

  Doacao porId(int id) =>
      doacoes.where((d) => d.id == id).firstOrNull ?? (throw naoEncontrada);

  /// Guarda a nova versão da doação, já com os campos de leitura (nome do
  /// doador, nome da ONG e prazo) atualizados.
  void salvar(Doacao doacao) {
    final completa = _comLeitura(doacao);
    final i = doacoes.indexWhere((d) => d.id == doacao.id);
    if (i >= 0) {
      doacoes[i] = completa;
    } else {
      doacoes.add(completa);
    }
  }

  Reserva? reservaAtivaDa(int doacaoId) =>
      reservas.where((r) => r.doacaoId == doacaoId && r.estaAtiva).firstOrNull;

  // ------------------------------------------------------------- doador

  Doacao criar(Conta doador, DadosNovaDoacao dados) {
    final completos = _validar(_comLocalizacao(doador, dados));
    final doacao = _montar(novoId(), doador.usuario.id, completos, _agora);
    salvar(doacao);
    return porId(doacao.id);
  }

  Doacao editar(Conta doador, int id, DadosNovaDoacao dados) {
    final atual = _doDono(doador, id);
    if (!atual.podeSerEditada) throw _naoEditavel;
    final completos = _validar(_comLocalizacao(doador, dados));
    salvar(
      _montar(
        id,
        atual.doadorId,
        completos,
        atual.criadoEm,
      ).copyWith(fotos: atual.fotos),
    );
    return porId(id);
  }

  /// No modo Fake a "foto" é o caminho do arquivo no próprio celular.
  Doacao adicionarFoto(Conta doador, int id, String caminho) {
    final doacao = _doDono(doador, id);
    if (!doacao.podeSerEditada) throw _naoEditavel;
    if (doacao.fotos.length >= Doacao.maximoDeFotos) {
      throw const ApiException(
        codigo: 'LIMITE_DE_FOTOS',
        mensagem: 'Cada doação pode ter no máximo 3 fotos.',
        status: 409,
      );
    }
    salvar(doacao.copyWith(fotos: [...doacao.fotos, caminho]));
    return porId(id);
  }

  /// RN12: reservada exige motivo; a ONG não é penalizada.
  void cancelar(Conta doador, int id, {String? motivo}) {
    final doacao = _doDono(doador, id);
    if (!doacao.podeSerCancelada) {
      throw const ApiException(
        codigo: 'DOACAO_NAO_CANCELAVEL',
        mensagem: 'Esta doação já foi concluída, cancelada ou expirou.',
        status: 409,
      );
    }
    final limpo = motivo?.trim();
    if (doacao.cancelamentoExigeMotivo) {
      final erro = ValidadorDoacao.motivoCancelamento(limpo);
      if (erro != null) {
        throw ApiException(codigo: 'VALIDACAO', mensagem: erro, status: 400);
      }
    }
    final ativa = reservaAtivaDa(id);
    if (ativa != null) {
      trocarReserva(
        ativa,
        StatusReserva.canceladaDoador,
        encerradaEm: _agora,
        motivo: limpo,
      );
    }
    salvar(
      doacao.copyWith(
        status: StatusDoacao.cancelada,
        motivoCancelamento: (limpo == null || limpo.isEmpty) ? null : limpo,
      ),
    );
  }

  List<Doacao> doDoador(Conta doador, SituacaoDaLista situacao) {
    expirarJanelasEncerradas();
    final querAtivas = situacao == SituacaoDaLista.ativas;
    return [
      for (final d in doacoes)
        if (d.doadorId == doador.usuario.id && d.status.ativa == querAtivas) d,
    ]..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
  }

  /// Mesmas regras de acesso do backend (ver `DoacaoService.detalhar`).
  DetalheDoacao detalhar(Conta conta, int id) {
    expirarJanelasEncerradas();
    final doacao = porId(id);
    final reserva = reservaAtivaDa(id);
    final usuario = conta.usuario;
    if (usuario.ehDoador) {
      if (doacao.doadorId != usuario.id) throw naoEncontrada;
      return DetalheDoacao(
        doacao: doacao,
        reserva: reserva?.semCodigo(), // RN26: o código é só da ONG
        ong: reserva == null ? null : _resumo(reserva.ongId),
      );
    }
    final ehDela = reserva?.ongId == usuario.id;
    final podeVer =
        doacao.podeSerReservada(_agora) &&
        !bloqueios.contains('${usuario.id}-$id');
    if (!ehDela && !podeVer) throw naoEncontrada;
    return DetalheDoacao(
      doacao: doacao,
      reserva: ehDela ? reserva : null,
      doador: _resumo(doacao.doadorId),
    );
  }

  /// RN13: disponíveis com o horário de retirada encerrado viram expiradas.
  void expirarJanelasEncerradas() {
    for (final d in List.of(doacoes)) {
      if (d.estaDisponivel && d.janelaEncerrada(_agora)) {
        salvar(d.copyWith(status: StatusDoacao.expirada));
      }
    }
  }

  /// Troca o status de uma retirada, mantendo o resto.
  void trocarReserva(
    Reserva reserva,
    StatusReserva status, {
    DateTime? encerradaEm,
    String? motivo,
    bool? contouDesistencia,
  }) {
    reservas[reservas.indexOf(reserva)] = reserva.copyWith(
      status: status,
      encerradaEm: encerradaEm,
      motivo: motivo,
      contouDesistencia: contouDesistencia,
    );
    salvar(porId(reserva.doacaoId));
  }

  // ----------------------------------------------------------- internos

  static const _naoEditavel = ApiException(
    codigo: 'DOACAO_NAO_EDITAVEL',
    mensagem: 'Só dá para editar enquanto nenhuma ONG aceitou a doação.',
    status: 409,
  );

  Doacao _doDono(Conta doador, int id) {
    final doacao = porId(id);
    if (doacao.doadorId != doador.usuario.id) throw naoEncontrada;
    return doacao;
  }

  DadosNovaDoacao _validar(DadosNovaDoacao dados) {
    final erros = ValidadorDoacao.validar(
      dados,
      agora: _agora,
      hoje: Calendario.dataNoFuso(_agora, fusoHorarioUtc),
    );
    if (erros.isEmpty) return dados;
    throw ApiException(
      codigo: 'VALIDACAO',
      mensagem: erros.first,
      status: 400,
      detalhes: erros,
    );
  }

  DadosNovaDoacao _comLocalizacao(Conta doador, DadosNovaDoacao dados) {
    final json = dados.toJson();
    final endereco = (dados.endereco ?? '').trim();
    if (endereco.isEmpty) json['endereco'] = doador.perfil.endereco;
    json['latitude'] ??= doador.perfil.latitude;
    json['longitude'] ??= doador.perfil.longitude;
    return DadosNovaDoacao.fromJson(json);
  }

  ResumoOrganizacao? _resumo(int usuarioId) {
    final conta = _contas.porId(usuarioId);
    if (conta == null) return null;
    return ResumoOrganizacao(
      usuarioId: usuarioId,
      nomeOrganizacao: conta.perfil.nomeOrganizacao,
      verificacao: conta.perfil.verificacao,
      nomeResponsavel: conta.usuario.nome,
      telefone: conta.perfil.telefone,
      tipoEstabelecimento: conta.perfil.tipoEstabelecimento,
      transporte: conta.perfil.transporte,
    );
  }

  /// Os campos de leitura que o backend preenche com JOINs.
  Doacao _comLeitura(Doacao d) {
    final reserva = reservaAtivaDa(d.id);
    final json = d.toJson()
      ..['nomeDoador'] = _contas.porId(d.doadorId)?.perfil.nomeOrganizacao
      ..['nomeOng'] = reserva == null
          ? null
          : _contas.porId(reserva.ongId)?.perfil.nomeOrganizacao
      ..['prazoRetirada'] = reserva?.toJson()['expiraEm'];
    return Doacao.fromJson(json);
  }

  static Doacao _montar(
    int id,
    int doadorId,
    DadosNovaDoacao dados,
    DateTime criadoEm,
  ) => Doacao(
    id: id,
    doadorId: doadorId,
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
    endereco: dados.endereco,
    latitude: dados.latitude!,
    longitude: dados.longitude!,
    status: StatusDoacao.disponivel,
    criadoEm: criadoEm,
  );
}
