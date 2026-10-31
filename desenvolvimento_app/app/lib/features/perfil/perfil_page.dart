import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_routes.dart';
import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../data/perfil/perfil_repository.dart';
import '../../shared/widgets/selo_verificacao.dart';
import 'partes_do_perfil.dart';
import 'perfil_view_model.dart';

/// T50 — Perfil: a conta com o selo, as estatísticas, editar os dados, a
/// busca ativa e o raio (ONG), os avisos, termos, sobre e **Sair**.
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key, required this.sessao, required this.perfis});

  final Sessao sessao;
  final PerfilRepository perfis;

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late final PerfilViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PerfilViewModel(sessao: widget.sessao, perfis: widget.perfis)
      ..carregarEstatisticas();
  }

  Future<void> _editar() async {
    await Navigator.pushNamed(context, AppRoutes.editarPerfil);
    _viewModel.atualizar(); // a conta da sessão pode ter mudado
  }

  void _sobre() => showAboutDialog(
    context: context,
    applicationName: AppConfig.nomeApp,
    applicationVersion: '0.1.0',
    applicationLegalese:
        'Trabalho do 4º semestre de Engenharia de Software, apresentado no '
        'evento Summit. ODS 2 (fome zero) e ODS 12 (consumo responsável).',
  );

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
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _corpo(),
      ),
    );
  }

  Widget _corpo() {
    final conta = _viewModel.conta;
    if (conta == null) return const SizedBox.shrink();
    final estatisticas = _viewModel.estatisticas;
    return ListView(
      // Embaixo, espaço para a barra inferior (o corpo da casca
      // passa por trás dela) não cobrir o botão Sair.
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        _Cabecalho(conta: conta),
        const SizedBox(height: 16),
        if (estatisticas != null)
          CartaoDeEstatisticas(
            estatisticas: estatisticas,
            ehOng: _viewModel.ehOng,
          ),
        const SizedBox(height: 8),
        ..._dados(conta),
        OutlinedButton.icon(
          key: const Key('editar_perfil'),
          onPressed: _editar,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar dados e localização'),
        ),
        if (_viewModel.ehOng) ...[
          const _Titulo('Busca de doações'),
          CartaoDaBusca(viewModel: _viewModel),
        ],
        const _Titulo('Avisos'),
        CartaoDosAvisos(viewModel: _viewModel),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Termos de uso e privacidade'),
          onTap: () => Navigator.pushNamed(context, AppRoutes.termos),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Sobre o app'),
          onTap: _sobre,
        ),
        const SizedBox(height: 16),
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
    ];
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
    child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
  );
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
