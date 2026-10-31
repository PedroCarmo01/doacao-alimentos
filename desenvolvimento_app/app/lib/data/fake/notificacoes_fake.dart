import 'package:shared_models/shared_models.dart';

import 'contas_fake.dart';

/// Os avisos do modo Fake: a mesma ideia da `CentralDeNotificacoes` do
/// backend, com os eventos principais (doação nova, aceite, prazo acabou,
/// retirada confirmada).
class NotificacoesFake {
  NotificacoesFake(this._relogio, this._contas);

  final Relogio _relogio;
  final ContasFake _contas;
  final List<Notificacao> _lista = [];
  final Map<int, int> _dono = {};

  /// RN22: "ong-doacao" bloqueados. Ligado pelo `BancoFake`.
  Set<String> bloqueios = {};

  void avisar(
    int usuarioId,
    TipoNotificacao tipo, {
    required String titulo,
    required String corpo,
    int? doacaoId,
    int? reservaId,
  }) {
    final n = Notificacao(
      id: _lista.length + 1,
      tipo: tipo,
      titulo: titulo,
      corpo: corpo,
      criadoEm: _relogio.agora(),
      doacaoId: doacaoId,
      reservaId: reservaId,
    );
    _lista.add(n);
    _dono[n.id] = usuarioId;
  }

  /// RN11: ONGs com a busca ativa, não suspensas, não bloqueadas e com a
  /// doação dentro do raio. Devolve quantas foram avisadas.
  int avisarOngsProximas(Doacao doacao, {bool deNovo = false}) {
    var avisadas = 0;
    for (final conta in _contas.todas) {
      final perfil = conta.perfil;
      if (!conta.usuario.ehOng || !perfil.buscaAtiva) continue;
      if (perfil.estaSuspensa(_relogio.agora())) continue;
      if (bloqueios.contains('${conta.usuario.id}-${doacao.id}')) continue;
      final km = Geo.distanciaKm(perfil.coordenadas, doacao.coordenadas);
      if (km > perfil.raioKm) continue;
      avisar(
        conta.usuario.id,
        deNovo
            ? TipoNotificacao.doacaoDisponivelDeNovo
            : TipoNotificacao.doacaoNova,
        titulo: deNovo
            ? 'Doação disponível de novo'
            : 'Doação nova perto de você',
        corpo:
            '${doacao.quantidadeTexto} de ${doacao.titulo}'
            '${doacao.nomeDoador == null ? '' : ' — ${doacao.nomeDoador}'}.',
        doacaoId: doacao.id,
      );
      avisadas++;
    }
    return avisadas;
  }

  List<Notificacao> doLogado(int? usuarioId, int depoisDe) => [
    for (final n in _lista)
      if (_dono[n.id] == usuarioId && n.id > depoisDe) n,
  ];

  void marcarLidas(int? usuarioId, int ate) {
    for (var i = 0; i < _lista.length; i++) {
      final n = _lista[i];
      if (_dono[n.id] == usuarioId && n.id <= ate && !n.lida) {
        _lista[i] = Notificacao.fromJson({...n.toJson(), 'lida': true});
      }
    }
  }
}
