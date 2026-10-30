import '../../core/api/api_exception.dart';
import '../../core/mvvm/view_model_base.dart';
import '../../core/preferencias/preferencias.dart';
import '../../core/sessao/sessao.dart';
import '../../data/auth/auth_repository.dart';

/// Para onde a tela de abertura manda a pessoa.
enum DestinoDaAbertura {
  /// Já estava logada: vai direto para o início do doador ou da ONG.
  inicio,

  /// Primeira vez no app: telas de boas-vindas (T2).
  boasVindas,

  /// Precisa entrar (T3).
  login,
}

/// ViewModel da abertura (T1). É o EXEMPLO DE REFERÊNCIA do padrão MVVM no
/// projeto: todos os outros ViewModels seguem este formato.
///
/// 1. Recebe as dependências pelo construtor, tipadas pelas INTERFACES.
/// 2. Guarda o estado em campos privados e expõe getters (encapsulamento).
/// 3. As ações usam `executar(...)`, herdado da `ViewModelBase`, que cuida de
///    "carregando" e de erros (HERANÇA).
class AberturaViewModel extends ViewModelBase {
  AberturaViewModel({
    required AuthRepository auth,
    required Sessao sessao,
    required Preferencias preferencias,
    this.tempoMinimo = const Duration(milliseconds: 1500),
  }) : _auth = auth,
       _sessao = sessao,
       _preferencias = preferencias;

  final AuthRepository _auth;
  final Sessao _sessao;
  final Preferencias _preferencias;

  /// A logo aparece por pelo menos este tempo (T1), mesmo que o servidor
  /// responda antes. Nos testes usamos `Duration.zero`.
  final Duration tempoMinimo;

  /// Mensagem que o login mostra quando o token passou dos 30 dias (RN05).
  static const avisoSessaoExpirada = 'Sua sessão expirou. Entre novamente.';

  DestinoDaAbertura? _destino;
  String? _aviso;

  /// `null` enquanto decide ou quando deu erro (sem conexão).
  DestinoDaAbertura? get destino => _destino;

  /// Aviso para mostrar no login (ou `null`).
  String? get aviso => _aviso;

  /// Lê o token salvo, pergunta ao servidor quem é (`GET /auth/me`) e
  /// decide o destino. Sem servidor, [erro] fica preenchido e a tela mostra
  /// "Tentar de novo".
  Future<void> iniciar() async {
    _destino = null;
    _aviso = null;
    final esperaMinima = Future<void>.delayed(tempoMinimo);
    await executar(() async {
      _destino = await _decidir();
    });
    await esperaMinima;
    notificar();
  }

  Future<DestinoDaAbertura> _decidir() async {
    try {
      final conta = await _auth.contaAtual();
      if (conta != null) {
        _sessao.restaurar(conta);
        return DestinoDaAbertura.inicio;
      }
    } on ApiException catch (e) {
      // RN05: o login venceu. Qualquer outro erro (ex.: sem conexão) sobe
      // para o executar(), que mostra a mensagem.
      if (e.codigo != codigoTokenExpirado) rethrow;
      _aviso = avisoSessaoExpirada;
      return DestinoDaAbertura.login;
    }
    final jaViu = await _preferencias.jaViuBoasVindas();
    return jaViu ? DestinoDaAbertura.login : DestinoDaAbertura.boasVindas;
  }
}
