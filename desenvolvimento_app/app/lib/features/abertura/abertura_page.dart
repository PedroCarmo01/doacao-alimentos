import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/preferencias/preferencias.dart';
import '../../core/routing/app_routes.dart';
import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth/auth_repository.dart';
import '../../shared/widgets/logo_do_app.dart';
import 'abertura_view_model.dart';

/// T1 — Abertura: logo no fundo verde enquanto o app decide para onde ir.
///
/// É também o EXEMPLO DE REFERÊNCIA de como uma página MVVM é montada:
/// 1. A página é um `StatefulWidget` que recebe as dependências.
/// 2. Cria o ViewModel no `initState` e o descarta no `dispose`.
/// 3. Usa `ListenableBuilder` para redesenhar quando o ViewModel muda.
/// 4. Navegação fica na página; a DECISÃO de para onde ir fica no ViewModel.
class AberturaPage extends StatefulWidget {
  const AberturaPage({
    super.key,
    required this.auth,
    required this.sessao,
    required this.preferencias,
  });

  final AuthRepository auth;
  final Sessao sessao;
  final Preferencias preferencias;

  @override
  State<AberturaPage> createState() => _AberturaPageState();
}

class _AberturaPageState extends State<AberturaPage> {
  late final AberturaViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AberturaViewModel(
      auth: widget.auth,
      sessao: widget.sessao,
      preferencias: widget.preferencias,
    );
    _iniciar();
  }

  Future<void> _iniciar() async {
    await _viewModel.iniciar();
    final destino = _viewModel.destino;
    if (destino == null || !mounted) return; // sem conexão: fica na tela
    final rota = switch (destino) {
      DestinoDaAbertura.inicio => AppRoutes.casca,
      DestinoDaAbertura.boasVindas => AppRoutes.boasVindas,
      DestinoDaAbertura.login => AppRoutes.login,
    };
    Navigator.pushReplacementNamed(context, rota, arguments: _viewModel.aviso);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verde,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoDoApp(tamanho: 140),
                const SizedBox(height: 24),
                Text(
                  AppConfig.nomeApp,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) => _Situacao(
                    erro: _viewModel.ocupado ? null : _viewModel.erro,
                    aoTentarDeNovo: _iniciar,
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

/// Carregando (indicador discreto) ou "Sem conexão" + "Tentar de novo".
class _Situacao extends StatelessWidget {
  const _Situacao({required this.erro, required this.aoTentarDeNovo});

  final String? erro;
  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final mensagem = erro;
    if (mensagem == null) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Colors.white,
          semanticsLabel: 'Carregando',
        ),
      );
    }
    return Column(
      children: [
        const Icon(Icons.cloud_off, color: Colors.white, size: 40),
        const SizedBox(height: 8),
        const Text(
          'Sem conexão com o servidor',
          key: Key('sem_conexao'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          mensagem,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: aoTentarDeNovo,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            minimumSize: const Size(200, 48),
          ),
          child: const Text('Tentar de novo'),
        ),
      ],
    );
  }
}
