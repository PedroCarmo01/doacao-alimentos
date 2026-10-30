import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/routing/app_routes.dart';
import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/selo_verificacao.dart';
import 'perfil_view_model.dart';

/// T50 — Perfil (versão da etapa 1): dados da conta, selo e **Sair**.
/// Edição, estatísticas, raio e preferências entram na etapa 7.
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key, required this.sessao});

  final Sessao sessao;

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late final PerfilViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PerfilViewModel(sessao: widget.sessao);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _sair() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Para voltar, você vai precisar da sua senha.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    final saiu = await _viewModel.sair();
    if (!saiu || !mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final conta = _viewModel.conta;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: conta == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _Cabecalho(conta: conta),
                const SizedBox(height: 24),
                ..._dados(conta),
                const SizedBox(height: 16),
                const Text(
                  'Editar dados, estatísticas e preferências: na etapa 7.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.cinza),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  key: const Key('botao_sair'),
                  onPressed: _sair,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _dados(Conta conta) {
    final perfil = conta.perfil;
    return [
      _Linha(
        Icons.badge_outlined,
        perfil.tipoDocumento.rotulo,
        ValidadorDocumento.formatar(perfil.documento),
      ),
      _Linha(Icons.person_outline, 'Responsável', conta.usuario.nome),
      _Linha(Icons.email_outlined, 'E-mail', conta.usuario.email),
      _Linha(Icons.phone_outlined, 'Telefone', perfil.telefone ?? '—'),
      _Linha(Icons.home_outlined, 'Endereço', perfil.endereco ?? '—'),
      if (conta.usuario.ehOng)
        _Linha(
          Icons.radar,
          'Busca ativa',
          '${perfil.buscaAtiva ? 'Ligada' : 'Desligada'} • até '
              '${perfil.raioKm.toStringAsFixed(0)} km',
        ),
    ];
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.conta});

  final Conta conta;

  @override
  Widget build(BuildContext context) {
    final perfil = conta.perfil;
    final estabelecimento = perfil.tipoEstabelecimento;
    final tipo = estabelecimento == null
        ? conta.usuario.tipo.rotulo
        : '${conta.usuario.tipo.rotulo} • ${estabelecimento.rotulo}';
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.verdeClaro,
          child: Icon(
            conta.usuario.ehOng ? Icons.groups : Icons.storefront,
            size: 40,
            color: AppColors.verde,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          perfil.nomeOrganizacao,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(tipo, style: const TextStyle(color: AppColors.cinza)),
        const SizedBox(height: 8),
        SeloVerificacao(verificacao: perfil.verificacao),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.icone, this.rotulo, this.valor);

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icone, color: AppColors.verde),
    title: Text(rotulo),
    subtitle: Text(valor),
  );
}
