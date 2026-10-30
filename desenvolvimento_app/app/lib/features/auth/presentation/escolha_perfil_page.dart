import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/sessao/sessao.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../data/sistema/sistema_repository.dart';
import 'escolha_perfil_view_model.dart';

/// TELA INICIAL (fundação, já implementada).
///
/// É também o EXEMPLO DE REFERÊNCIA de como uma página MVVM é montada:
/// 1. A página é um `StatefulWidget` que recebe as dependências.
/// 2. Cria o ViewModel no `initState` e o descarta no `dispose`.
/// 3. Usa `ListenableBuilder` para redesenhar quando o ViewModel muda.
class EscolhaPerfilPage extends StatefulWidget {
  const EscolhaPerfilPage({
    super.key,
    required this.sistema,
    required this.auth,
    required this.sessao,
  });

  final SistemaRepository sistema;
  final AuthRepository auth;
  final Sessao sessao;

  @override
  State<EscolhaPerfilPage> createState() => _EscolhaPerfilPageState();
}

class _EscolhaPerfilPageState extends State<EscolhaPerfilPage> {
  late final EscolhaPerfilViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EscolhaPerfilViewModel(
      sistema: widget.sistema,
      auth: widget.auth,
      sessao: widget.sessao,
    );
    _iniciar();
  }

  Future<void> _iniciar() async {
    await _viewModel.iniciar();
    final conta = _viewModel.contaRestaurada;
    if (conta == null || !mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.inicioDoTipo(conta.usuario.tipo),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _continuarComo(TipoUsuario tipo) =>
      Navigator.pushNamed(context, AppRoutes.login, arguments: tipo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.volunteer_activism,
                  size: 80,
                  color: AppColors.verde,
                ),
                const SizedBox(height: 16),
                Text(
                  AppConfig.nomeApp,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Conectando quem tem alimentos sobrando a quem precisa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.cinza),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  key: const Key('botao_doador'),
                  onPressed: () => _continuarComo(TipoUsuario.doador),
                  icon: const Icon(Icons.storefront),
                  label: const Text('Sou estabelecimento doador'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('botao_ong'),
                  onPressed: () => _continuarComo(TipoUsuario.ong),
                  icon: const Icon(Icons.groups),
                  label: const Text('Sou ONG'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.verde,
                    side: const BorderSide(color: AppColors.verde),
                  ),
                ),
                const SizedBox(height: 32),
                ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) => _StatusDoServidor(
                    verificando: _viewModel.ocupado,
                    status: _viewModel.status,
                    aoTentarDeNovo: _viewModel.iniciar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDoServidor extends StatelessWidget {
  const _StatusDoServidor({
    required this.verificando,
    required this.status,
    required this.aoTentarDeNovo,
  });

  final bool verificando;
  final StatusSistema? status;
  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final atual = status;
    if (verificando || atual == null) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Verificando o servidor...'),
        ],
      );
    }
    final cor = atual.tudoCerto ? AppColors.verde : AppColors.erro;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              atual.tudoCerto ? Icons.cloud_done : Icons.cloud_off,
              color: cor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                atual.descricao,
                key: const Key('status_servidor'),
                style: TextStyle(color: cor),
              ),
            ),
          ],
        ),
        if (!atual.tudoCerto)
          TextButton(
            onPressed: aoTentarDeNovo,
            child: const Text('Tentar de novo'),
          ),
      ],
    );
  }
}
