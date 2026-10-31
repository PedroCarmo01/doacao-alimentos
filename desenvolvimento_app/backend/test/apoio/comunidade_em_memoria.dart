import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/comunidade/comunidade_repository.dart';

import 'doacoes_em_memoria.dart';
import 'em_memoria.dart';

/// [ComunidadeRepository] em memória, sobre as contas e doações em memória.
class ComunidadeEmMemoria implements ComunidadeRepository {
  ComunidadeEmMemoria(this._contas, this._doacoes);

  final ContasEmMemoria _contas;
  final DoacoesEmMemoria _doacoes;

  final List<_Registro> _publicacoes = [];

  /// "publicação-usuário" (as chaves compostas das tabelas).
  final Set<String> _apoios = {};
  final Set<String> _denuncias = {};

  _Registro? _porId(int id) =>
      _publicacoes.where((r) => r.id == id).firstOrNull;

  Publicacao _montar(_Registro r, int leitorId) {
    final autor = _contas.conta(r.autorId)!;
    return Publicacao(
      id: r.id,
      autorId: r.autorId,
      nomeAutor: autor.perfil.nomeOrganizacao,
      tipoAutor: autor.usuario.tipo,
      verificacaoAutor: autor.perfil.verificacao,
      texto: r.dados.texto.trim(),
      criadoEm: r.criadoEm,
      fotos: List.of(r.fotos),
      doacaoId: r.dados.doacaoId,
      familiasAjudadas: r.dados.familiasAjudadas,
      refeicoes: r.dados.refeicoes,
      apoios: _apoios.where((a) => a.startsWith('${r.id}-')).length,
      apoiadaPorMim: _apoios.contains('${r.id}-$leitorId'),
    );
  }

  @override
  Future<Impacto> impacto() async {
    var kg = 0.0;
    var concluidas = 0;
    for (final d in _doacoes.doacoes) {
      if (d.status == StatusDoacao.concluida) {
        concluidas++;
        kg += d.pesoKg;
      }
    }
    var familias = 0;
    var refeicoes = 0;
    for (final r in _publicacoes) {
      if (r.oculta) continue;
      familias += r.dados.familiasAjudadas ?? 0;
      refeicoes += r.dados.refeicoes ?? 0;
    }
    return Impacto(
      kgSalvos: kg,
      doacoesConcluidas: concluidas,
      familiasAjudadas: familias,
      refeicoes: refeicoes,
    );
  }

  @override
  Future<List<Publicacao>> feed(
    int leitorId, {
    required int antesDe,
    required int limite,
  }) async => [
    for (final r in _publicacoes.reversed)
      if (!r.oculta && (antesDe == 0 || r.id < antesDe)) _montar(r, leitorId),
  ].take(limite).toList();

  @override
  Future<Publicacao?> buscar(int publicacaoId, int leitorId) async {
    final r = _porId(publicacaoId);
    return r == null ? null : _montar(r, leitorId);
  }

  @override
  Future<int> criar(int autorId, DadosPublicacao dados, DateTime agora) async {
    final r = _Registro(_publicacoes.length + 1, autorId, dados, agora);
    _publicacoes.add(r);
    return r.id;
  }

  @override
  Future<void> adicionarFoto(
    int publicacaoId,
    String arquivo,
    int ordem,
  ) async => _porId(publicacaoId)!.fotos.add(arquivo);

  @override
  Future<bool> apoiar(int publicacaoId, int usuarioId, DateTime agora) async =>
      _apoios.add('$publicacaoId-$usuarioId');

  @override
  Future<void> desfazerApoio(int publicacaoId, int usuarioId) async =>
      _apoios.remove('$publicacaoId-$usuarioId');

  @override
  Future<bool> denunciar(
    int publicacaoId,
    int usuarioId,
    MotivoDenuncia motivo,
    DateTime agora,
  ) async => _denuncias.add('$publicacaoId-$usuarioId');

  @override
  Future<int> denuncias(int publicacaoId) async =>
      _denuncias.where((d) => d.startsWith('$publicacaoId-')).length;

  @override
  Future<void> ocultar(int publicacaoId) async =>
      _porId(publicacaoId)!.oculta = true;

  @override
  Future<bool> estaOculta(int publicacaoId) async =>
      _porId(publicacaoId)?.oculta ?? false;

  @override
  Future<bool> participouDaDoacaoConcluida(int usuarioId, int doacaoId) async {
    final doacao = await _doacoes.buscar(doacaoId);
    if (doacao == null || doacao.status != StatusDoacao.concluida) {
      return false;
    }
    if (doacao.doadorId == usuarioId) return true;
    return _doacoes.reservas.any(
      (r) =>
          r.doacaoId == doacaoId &&
          r.ongId == usuarioId &&
          r.status == StatusReserva.concluida,
    );
  }
}

class _Registro {
  _Registro(this.id, this.autorId, this.dados, this.criadoEm);

  final int id;
  final int autorId;
  final DadosPublicacao dados;
  final DateTime criadoEm;
  final List<String> fotos = [];
  bool oculta = false;
}
