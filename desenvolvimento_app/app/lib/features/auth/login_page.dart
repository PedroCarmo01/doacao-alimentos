import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/routing/app_routes.dart';
import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth/auth_repository.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/aviso.dart';
import '../../shared/widgets/logo_do_app.dart';
import '../../shared/widgets/primary_button.dart';
import 'login_view_model.dart';

/// T3 — Login: e-mail, senha e o link para criar conta.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.auth,
    required this.sessao,
    this.aviso,
  });

  final AuthRepository auth;
  final Sessao sessao;

  /// Ex.: "Sua sessão expirou. Entre novamente." (vem da abertura).
  final String? aviso;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginViewModel _viewModel;
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  /// Mostrar ou esconder a senha (o "olho"). Estado só da tela.
  bool _senhaVisivel = false;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(auth: widget.auth, sessao: widget.sessao);
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formulario.currentState!.validate()) return;
    final entrou = await _viewModel.entrar(
      email: _email.text,
      senha: _senha.text,
    );
    if (!entrou || !mounted) return;
    // Remove o login da pilha: o "voltar" do Android não volta para cá.
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.casca, (_) => false);
  }

  void _esqueciASenha() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Em breve. Por enquanto, fale com a equipe do app.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: SingleChildScrollView(child: _conteudo())),
            // Ação principal fixa embaixo; sobe junto com o teclado.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) => PrimaryButton(
                  key: const Key('botao_entrar'),
                  texto: 'Entrar',
                  carregando: _viewModel.ocupado,
                  onPressed: _entrar,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cadastro),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text('Ainda não tem conta? Criar conta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    final aviso = widget.aviso;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: LogoDoApp(tamanho: 88)),
            const SizedBox(height: 16),
            Text(
              'Entrar',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (aviso != null) ...[
              Aviso(texto: aviso, icone: Icons.lock_clock),
              const SizedBox(height: 16),
            ],
            AppTextField(
              key: const Key('campo_email'),
              label: 'E-mail',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              preenchimentoAutomatico: const [AutofillHints.email],
              validator: ValidadorUsuario.email,
            ),
            AppTextField(
              key: const Key('campo_senha'),
              label: 'Senha',
              controller: _senha,
              obscure: !_senhaVisivel,
              prefixIcon: Icons.lock_outline,
              acaoDoTeclado: TextInputAction.done,
              preenchimentoAutomatico: const [AutofillHints.password],
              validator: (valor) =>
                  (valor ?? '').isEmpty ? 'Informe a senha.' : null,
              sufixo: IconButton(
                tooltip: _senhaVisivel ? 'Esconder a senha' : 'Mostrar a senha',
                icon: Icon(
                  _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
              ),
            ),
            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                final erro = _viewModel.erro;
                if (erro == null) return const SizedBox.shrink();
                return Text(
                  erro,
                  key: const Key('erro_login'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.erro),
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _esqueciASenha,
                style: TextButton.styleFrom(foregroundColor: AppColors.cinza),
                child: const Text('Esqueci minha senha'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
