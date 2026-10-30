import 'package:flutter/foundation.dart';

import '../erros/erro_amigavel.dart';

/// Classe-mãe de TODOS os ViewModels do app (padrão MVVM, docs/adr/ADR-005).
///
/// Por que existe (HERANÇA bem usada): toda tela precisa de "carregando",
/// "erro" e de não avisar a View depois que ela foi fechada. Em vez de repetir
/// isso em cada ViewModel, escrevemos uma vez aqui.
///
/// Padrão Observer: `ChangeNotifier` mantém uma lista de "ouvintes" (a View,
/// via `ListenableBuilder`). Quando o estado muda, chamamos [notificar] e a
/// View se redesenha.
abstract class ViewModelBase extends ChangeNotifier {
  bool _ocupado = false;
  String? _erro;
  bool _descartado = false;

  /// `true` enquanto uma ação de [executar] está em andamento.
  bool get ocupado => _ocupado;

  /// Mensagem do último erro, pronta para exibir (ou `null`).
  String? get erro => _erro;

  /// Executa [acao] controlando [ocupado] e [erro] automaticamente.
  ///
  /// Devolve `true` se deu certo. Erros "amigáveis" (API, GPS, regras) viram
  /// a mensagem de [erro]; qualquer outro erro é registrado no console e
  /// mostra uma mensagem genérica.
  @protected
  Future<bool> executar(Future<void> Function() acao) async {
    if (_ocupado) return false; // evita clique duplo
    _ocupado = true;
    _erro = null;
    notificar();
    try {
      await acao();
      return true;
    } on ErroAmigavel catch (e) {
      _erro = e.mensagem;
      return false;
    } catch (e, pilha) {
      debugPrint('Erro inesperado em $runtimeType: $e\n$pilha');
      _erro = 'Algo deu errado. Tente novamente.';
      return false;
    } finally {
      _ocupado = false;
      notificar();
    }
  }

  /// Apaga a mensagem de erro (ex.: depois de mostrá-la num SnackBar).
  void limparErro() {
    if (_erro == null) return;
    _erro = null;
    notificar();
  }

  /// Define um erro sem passar por [executar] (ex.: validação local).
  @protected
  void definirErro(String? mensagem) {
    _erro = mensagem;
    notificar();
  }

  /// Avisa a View, mas só se o ViewModel ainda estiver em uso.
  /// (Uma resposta da API pode chegar depois que o usuário saiu da tela.)
  @protected
  void notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
