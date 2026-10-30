import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/arquivos/armazenamento_de_fotos.dart';
import 'package:summit_backend/doacoes/doacao_repository.dart';

import 'em_memoria.dart';

/// [DoacaoRepository] em memória, para testar o `DoacaoService` sem MySQL.
class DoacoesEmMemoria implements DoacaoRepository {
  DoacoesEmMemoria(this._contas);

  final ContasEmMemoria _contas;
  final List<Doacao> doacoes = [];
  final List<Reserva> reservas = [];

  /// Pares "ong-doacao" bloqueados (RN22).
  final Set<String> bloqueios = {};

  Doacao? _porId(int id) => doacoes.where((d) => d.id == id).firstOrNull;

  void _trocar(Doacao nova) =>
      doacoes[doacoes.indexWhere((d) => d.id == nova.id)] = nova;

  /// Ajuda dos testes: coloca uma retirada em andamento na doação.
  void reservar(int doacaoId, int ongId, DateTime agora) {
    _trocar(_porId(doacaoId)!.copyWith(status: StatusDoacao.reservada));
    reservas.add(
      Reserva(
        id: reservas.length + 1,
        doacaoId: doacaoId,
        ongId: ongId,
        status: StatusReserva.ativa,
        reservadoEm: agora,
        expiraEm: agora.add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<Doacao> criar(
    DadosNovaDoacao dados, {
    required int doadorId,
    required DateTime criadoEm,
  }) async {
    final doacao = _montar(doacoes.length + 1, doadorId, dados, criadoEm);
    doacoes.add(doacao);
    return doacao;
  }

  @override
  Future<Doacao> atualizar(int doacaoId, DadosNovaDoacao dados) async {
    final antiga = _porId(doacaoId)!;
    final nova = _montar(doacaoId, antiga.doadorId, dados, antiga.criadoEm);
    _trocar(nova);
    return nova;
  }

  @override
  Future<Doacao?> buscar(int doacaoId) async => _porId(doacaoId);

  @override
  Future<List<Doacao>> doDoador(int doadorId, SituacaoDaLista situacao) async {
    final querAtivas = situacao == SituacaoDaLista.ativas;
    return [
      for (final d in doacoes.reversed)
        if (d.doadorId == doadorId && d.status.ativa == querAtivas) d,
    ];
  }

  @override
  Future<Reserva?> reservaAtiva(int doacaoId) async =>
      reservas.where((r) => r.doacaoId == doacaoId && r.estaAtiva).firstOrNull;

  @override
  Future<ResumoOrganizacao?> resumo(int usuarioId) async {
    final conta = _contas.conta(usuarioId);
    if (conta == null) return null;
    return ResumoOrganizacao(
      usuarioId: usuarioId,
      nomeOrganizacao: conta.perfil.nomeOrganizacao,
      verificacao: conta.perfil.verificacao,
      telefone: conta.perfil.telefone,
    );
  }

  @override
  Future<bool> ongBloqueada(int ongId, int doacaoId) async =>
      bloqueios.contains('$ongId-$doacaoId');

  @override
  Future<void> cancelar(
    int doacaoId, {
    required String? motivo,
    required DateTime agora,
  }) async {
    final ativa = await reservaAtiva(doacaoId);
    if (ativa != null) {
      reservas[reservas.indexOf(ativa)] = Reserva(
        id: ativa.id,
        doacaoId: ativa.doacaoId,
        ongId: ativa.ongId,
        status: StatusReserva.canceladaDoador,
        reservadoEm: ativa.reservadoEm,
        expiraEm: ativa.expiraEm,
        encerradaEm: agora,
        motivo: motivo,
      );
    }
    _trocar(
      _porId(
        doacaoId,
      )!.copyWith(status: StatusDoacao.cancelada, motivoCancelamento: motivo),
    );
  }

  @override
  Future<int> expirarJanelasEncerradas(DateTime agora) async {
    var quantas = 0;
    for (final d in List.of(doacoes)) {
      if (d.estaDisponivel && d.janelaEncerrada(agora)) {
        _trocar(d.copyWith(status: StatusDoacao.expirada));
        quantas++;
      }
    }
    return quantas;
  }

  @override
  Future<void> adicionarFoto(int doacaoId, String arquivo, int ordem) async {
    final doacao = _porId(doacaoId)!;
    _trocar(doacao.copyWith(fotos: [...doacao.fotos, arquivo]));
  }

  static Doacao _montar(
    int id,
    int doadorId,
    DadosNovaDoacao dados,
    DateTime criadoEm,
  ) => Doacao(
    id: id,
    doadorId: doadorId,
    titulo: dados.titulo,
    categoria: dados.categoria,
    quantidade: dados.quantidade,
    unidade: dados.unidade,
    pesoKg: dados.pesoKg,
    conservacao: dados.conservacao,
    validade: dados.validade,
    janelaInicio: dados.janelaInicio,
    janelaFim: dados.janelaFim,
    endereco: dados.endereco,
    latitude: dados.latitude!,
    longitude: dados.longitude!,
    status: StatusDoacao.disponivel,
    criadoEm: criadoEm,
  );
}

/// Fotos guardadas num mapa (sem disco).
class FotosEmMemoria implements ArmazenamentoDeFotos {
  final Map<String, List<int>> arquivos = {};

  @override
  Future<String> salvar(List<int> bytes, FormatoDeFoto formato) async {
    final nome = '${arquivos.length}'.padLeft(32, '0');
    arquivos['$nome.${formato.name}'] = bytes;
    return '$nome.${formato.name}';
  }

  @override
  Future<List<int>?> ler(String nome) async => arquivos[nome];
}
