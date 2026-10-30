import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';
import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../core/utils/formatador.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/reservas/reserva_repository.dart';

/// ViewModel do detalhe da doação, lado da ONG (T22), com o aceite
/// ("Vou retirar", RN20–RN25).
class DetalheDoacaoOngViewModel extends ViewModelBase {
  DetalheDoacaoOngViewModel({
    required DoacaoRepository doacoes,
    required ReservaRepository reservas,
    required Sessao sessao,
    required Relogio relogio,
    required this.doacaoId,
  }) : _doacoes = doacoes,
       _reservas = reservas,
       _sessao = sessao,
       _relogio = relogio;

  final DoacaoRepository _doacoes;
  final ReservaRepository _reservas;
  final Sessao _sessao;
  final Relogio _relogio;
  final int doacaoId;

  DetalheDoacao? _detalhe;
  SituacaoDaOng? _situacao;
  bool _outraOngAceitou = false;

  DetalheDoacao? get detalhe => _detalhe;

  /// Se esta ONG já está retirando a doação, a retirada dela.
  Reserva? get minhaRetirada => _detalhe?.reserva;

  /// RN20: o aceite falhou porque outra ONG chegou antes.
  bool get outraOngAceitou => _outraOngAceitou;

  DateTime get _agora => _relogio.agora();

  /// Distância do ponto da ONG até a doação.
  double? get distanciaKm {
    final perfil = _sessao.perfil;
    final doacao = _detalhe?.doacao;
    if (perfil == null || doacao == null) return null;
    return Geo.distanciaKm(perfil.coordenadas, doacao.coordenadas);
  }

  /// RN24: suspensa vê, mas não aceita. A situação vem do servidor (mais
  /// atual que a sessão: a suspensão pode ter começado agora).
  bool get suspensa =>
      _situacao?.estaSuspensa(_agora) ??
      _sessao.perfil?.estaSuspensa(_agora) ??
      false;

  /// Por que o botão "Vou retirar" está desativado (`null` = pode aceitar).
  String? get motivoParaNaoAceitar {
    final situacao = _situacao;
    if (suspensa) {
      final ate = situacao?.suspensaAte ?? _sessao.perfil?.suspensaAte;
      return 'Você está suspensa${ate == null ? '' : ' até ${Formatador.diaHora(ate)}'} '
          'por desistências e não pode aceitar agora.';
    }
    if (situacao != null && situacao.atingiuLimite) {
      return 'Você já tem ${situacao.regras.retiradasSimultaneas} retiradas '
          'em andamento. Conclua uma antes de aceitar outra.';
    }
    return null;
  }

  /// O aviso antes de confirmar o aceite (T22), com os números do servidor.
  String get avisoDoAceite {
    final regras = _situacao?.regras ?? const RegrasDaRetirada();
    final doacao = _detalhe!.doacao;
    // Lê o relógio UMA vez: duas leituras dariam 1:59,999 → "1 min".
    final agora = _agora;
    final prazo = regras
        .prazoFinal(agora: agora, janelaFim: doacao.janelaFim)
        .difference(agora);
    final aviso =
        'Você terá ${Formatador.duracaoCurta(prazo)} para retirar. Se não '
        'retirar, a doação volta para outras ONGs e conta como desistência. '
        '${regras.desistenciasParaSuspender} desistências em '
        '${regras.janelaDesistencias.inDays} dias suspendem sua conta por '
        '${regras.suspensao.inHours} h.';
    if (_situacao?.proximaDesistenciaSuspende ?? false) {
      return '$aviso\n\nAtenção: mais uma desistência e sua conta será '
          'suspensa por ${regras.suspensao.inHours} h.';
    }
    return aviso;
  }

  Future<bool> carregar() => executar(() async {
    _detalhe = await _doacoes.detalhar(doacaoId);
    _situacao = await _reservas.situacao();
  });

  /// "Vou retirar". Devolve a retirada criada, ou `null` se não deu (o
  /// motivo fica em [erro] e, se outra ONG chegou antes, em
  /// [outraOngAceitou]).
  Future<Reserva?> aceitar() async {
    Reserva? aceita;
    await executar(() async {
      try {
        aceita = await _reservas.aceitar(doacaoId);
      } on ApiException catch (e) {
        _outraOngAceitou = e.codigo == 'DOACAO_INDISPONIVEL';
        rethrow; // o executar() transforma em mensagem de erro
      }
    });
    return aceita;
  }
}
