import 'package:shared_models/shared_models.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/mvvm/view_model_base.dart';
import '../../../core/sessao/sessao.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../data/sistema/sistema_repository.dart';

/// ViewModel da tela inicial. É o EXEMPLO DE REFERÊNCIA do padrão MVVM no
/// projeto: todos os outros ViewModels seguem este formato.
///
/// 1. Recebe as dependências pelo construtor, tipadas pelas INTERFACES.
/// 2. Guarda o estado em campos privados e expõe getters (encapsulamento).
/// 3. As ações usam `executar(...)`, herdado da `ViewModelBase`, que cuida de
///    "carregando" e de erros.
class EscolhaPerfilViewModel extends ViewModelBase {
  EscolhaPerfilViewModel({
    required SistemaRepository sistema,
    required AuthRepository auth,
    required Sessao sessao,
  }) : _sistema = sistema,
       _auth = auth,
       _sessao = sessao;

  final SistemaRepository _sistema;
  final AuthRepository _auth;
  final Sessao _sessao;

  StatusSistema? _status;
  Conta? _contaRestaurada;

  /// Situação do servidor (`null` enquanto verifica).
  StatusSistema? get status => _status;

  /// Preenchida quando havia uma sessão válida salva: a View navega direto
  /// para a tela inicial do perfil.
  Conta? get contaRestaurada => _contaRestaurada;

  /// Verifica o servidor e tenta restaurar a sessão salva.
  Future<bool> iniciar() => executar(() async {
    final status = await _sistema.verificar();
    _status = status;
    if (!status.tudoCerto) return;
    try {
      final conta = await _auth.contaAtual();
      if (conta != null) {
        _sessao.restaurar(conta);
        _contaRestaurada = conta;
      }
    } on ApiException {
      // Sem sessão válida: o usuário escolhe o perfil e entra de novo.
    }
  });
}
