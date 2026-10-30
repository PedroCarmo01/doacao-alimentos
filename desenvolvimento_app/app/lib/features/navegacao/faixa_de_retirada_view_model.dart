import 'dart:async';

import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../core/utils/formatador.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/reservas/reserva_repository.dart';

/// ViewModel da faixa laranja "retirada em andamento", fixa no topo da
/// casca (seção 2 da especificação).
///
/// - ONG: "Retirada em andamento • 42:10 restantes • Ver".
/// - Doador: "ONG Mãos Amigas a caminho • Ver".
///
/// Consulta o servidor a cada 15 s e redesenha o contador a cada 1 s.
class FaixaDeRetiradaViewModel extends ViewModelBase {
  FaixaDeRetiradaViewModel({
    required ReservaRepository reservas,
    required DoacaoRepository doacoes,
    required Sessao sessao,
    required Relogio relogio,
  }) : _reservas = reservas,
       _doacoes = doacoes,
       _sessao = sessao,
       _relogio = relogio;

  final ReservaRepository _reservas;
  final DoacaoRepository _doacoes;
  final Sessao _sessao;
  final Relogio _relogio;

  static const intervaloDeConsulta = Duration(seconds: 15);

  /// ONG: as retiradas dela em andamento, a que vence primeiro antes.
  List<Reserva> _retiradas = const [];

  /// Doador: as doações dele que uma ONG está vindo buscar.
  List<Doacao> _aCaminho = const [];
  Timer? _segundos;
  Timer? _consulta;

  bool get _ehOng => _sessao.usuario?.ehOng ?? false;

  bool get visivel => _ehOng ? _retiradas.isNotEmpty : _aCaminho.isNotEmpty;

  /// ONG com UMA retirada: abre a T23 dela. Com mais, abre a lista.
  Reserva? get retiradaUnica =>
      _retiradas.length == 1 ? _retiradas.first : null;

  /// Doador: a doação que a ONG vem buscar primeiro.
  Doacao? get doacaoACaminho => _aCaminho.firstOrNull;

  String get texto {
    if (_ehOng) {
      if (_retiradas.isEmpty) return '';
      final restante = Formatador.contador(
        _retiradas.first.tempoRestante(_relogio.agora()),
      );
      return _retiradas.length == 1
          ? 'Retirada em andamento • $restante restantes'
          : '${_retiradas.length} retiradas em andamento • a próxima '
                'vence em $restante';
    }
    if (_aCaminho.isEmpty) return '';
    return _aCaminho.length == 1
        ? '${_aCaminho.first.nomeOng ?? 'A ONG'} a caminho'
        : '${_aCaminho.length} ONGs a caminho';
  }

  /// Liga os despertadores e faz a primeira consulta.
  void iniciar() {
    _segundos ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (visivel) notificar(); // só o contador muda
    });
    _consulta ??= Timer.periodic(intervaloDeConsulta, (_) => atualizar());
    atualizar();
  }

  /// Consulta "em silêncio": se a rede falhar, a faixa só não muda.
  Future<void> atualizar() async {
    try {
      if (_ehOng) {
        _retiradas = [...(await _reservas.situacao()).ativas]
          ..sort((a, b) => a.expiraEm.compareTo(b.expiraEm));
      } else {
        final ativas = await _doacoes.listarMinhas(SituacaoDaLista.ativas);
        _aCaminho = [
          for (final doacao in ativas)
            if (doacao.status == StatusDoacao.reservada) doacao,
        ];
      }
      notificar();
    } catch (_) {
      // Sem internet por um instante: a próxima consulta resolve.
    }
  }

  @override
  void dispose() {
    _segundos?.cancel();
    _consulta?.cancel();
    super.dispose();
  }
}
