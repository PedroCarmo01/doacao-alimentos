import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../data/perfil/perfil_repository.dart';

/// ViewModel do Perfil (T50): a conta, as estatísticas, a busca ativa e o
/// raio (ONG), os avisos e sair.
class PerfilViewModel extends ViewModelBase {
  PerfilViewModel({required Sessao sessao, required PerfilRepository perfis})
    : _sessao = sessao,
      _perfis = perfis;

  final Sessao _sessao;
  final PerfilRepository _perfis;

  /// As opções de raio da T50 (as mesmas do Início da ONG).
  static const raios = [2.0, 5.0, 10.0, 20.0];

  EstatisticasDoPerfil? _estatisticas;

  Conta? get conta => _sessao.conta;
  bool get ehOng => _sessao.usuario?.ehOng ?? false;
  EstatisticasDoPerfil? get estatisticas => _estatisticas;
  PreferenciasDeAviso get avisos =>
      conta?.perfil.avisos ?? const PreferenciasDeAviso();

  /// Os números do topo. Se falhar, a tela só não mostra o cartão.
  Future<void> carregarEstatisticas() async {
    try {
      _estatisticas = await _perfis.estatisticas();
      notificar();
    } catch (_) {
      // Sem os números por agora: o resto do Perfil funciona.
    }
  }

  /// T50: liga/desliga um tipo de aviso.
  Future<bool> mudarAvisos(PreferenciasDeAviso novos) => executar(() async {
    _sessao.restaurar(await _perfis.atualizarAvisos(novos));
  });

  /// ONG: busca ativa (T50, igual ao Início).
  Future<bool> mudarBuscaAtiva(bool ligada) =>
      _salvar((conta) => dadosDoPerfil(conta, buscaAtiva: ligada));

  /// ONG: raio de 2, 5, 10 ou 20 km.
  Future<bool> mudarRaio(double km) =>
      _salvar((conta) => dadosDoPerfil(conta, raioKm: km));

  /// Depois de editar os dados em outra tela, a conta da sessão mudou.
  void atualizar() => notificar();

  /// Apaga o token salvo e esquece a conta. Na próxima abertura, o app
  /// vai para o login (RN05: só sai quando a pessoa toca em Sair).
  Future<bool> sair() => executar(_sessao.encerrar);

  Future<bool> _salvar(DadosPerfil Function(Conta conta) montar) =>
      executar(() async {
        final atual = conta;
        if (atual == null) return;
        _sessao.restaurar(await _perfis.atualizar(montar(atual)));
      });
}
