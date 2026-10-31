import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/sessao/sessao.dart';
import '../../data/localizacao/cep_repository.dart';
import '../../data/localizacao/localizacao_service.dart';
import '../../data/perfil/perfil_repository.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/aviso.dart';
import '../../shared/widgets/primary_button.dart';
import 'editar_perfil_view_model.dart';

/// T50 — Editar dados e localização. CNPJ/CPF, tipo e e-mail não mudam.
class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({
    super.key,
    required this.sessao,
    required this.perfis,
    required this.cep,
    required this.localizacao,
  });

  final Sessao sessao;
  final PerfilRepository perfis;
  final CepRepository cep;
  final LocalizacaoService localizacao;

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  late final EditarPerfilViewModel _viewModel;
  late final TextEditingController _nome;
  late final TextEditingController _organizacao;
  late final TextEditingController _telefone;
  late final TextEditingController _endereco;
  late final TextEditingController _cep;
  late final TextEditingController _familias;

  @override
  void initState() {
    super.initState();
    _viewModel = EditarPerfilViewModel(
      sessao: widget.sessao,
      perfis: widget.perfis,
      cep: widget.cep,
      localizacao: widget.localizacao,
    );
    final conta = _viewModel.conta;
    final perfil = conta.perfil;
    _nome = TextEditingController(text: conta.usuario.nome);
    _organizacao = TextEditingController(text: perfil.nomeOrganizacao);
    _telefone = TextEditingController(text: perfil.telefone);
    _endereco = TextEditingController(text: perfil.endereco);
    _cep = TextEditingController(text: perfil.cep);
    _familias = TextEditingController(
      text: perfil.familiasAtendidas?.toString(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    for (final controle in [
      _nome,
      _organizacao,
      _telefone,
      _endereco,
      _cep,
      _familias,
    ]) {
      controle.dispose();
    }
    super.dispose();
  }

  void _avisar(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _buscarCep() async {
    final endereco = await _viewModel.buscarCep(_cep.text);
    if (!mounted) return;
    if (endereco == null) {
      _avisar(_viewModel.erro ?? 'CEP não encontrado.');
    } else {
      _endereco.text = '$endereco, ';
    }
  }

  Future<void> _usarGps() async {
    final deu = await _viewModel.usarLocalizacaoAtual();
    if (!mounted) return;
    _avisar(
      deu
          ? 'Localização atualizada. Toque em Salvar para gravar.'
          : (_viewModel.erro ?? 'Não foi possível usar o GPS.'),
    );
  }

  Future<void> _salvar() async {
    final salvou = await _viewModel.salvar(
      nome: _nome.text,
      nomeOrganizacao: _organizacao.text,
      telefone: _telefone.text,
      endereco: _endereco.text,
      cep: _cep.text,
      familias: _familias.text,
    );
    if (!mounted) return;
    if (salvou) {
      _avisar('Dados salvos.');
      Navigator.pop(context, true);
    } else {
      _avisar(_viewModel.erro ?? 'Não deu certo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar dados')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(label: 'Nome do responsável', controller: _nome),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Nome da organização',
              controller: _organizacao,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Telefone (com DDD)',
              controller: _telefone,
              keyboardType: TextInputType.phone,
              somenteNumeros: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'CEP',
                    controller: _cep,
                    somenteNumeros: true,
                    tamanhoMaximo: 8,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _viewModel.ocupado ? null : _buscarCep,
                  child: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Endereço (com número)', controller: _endereco),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _viewModel.ocupado ? null : _usarGps,
              icon: const Icon(Icons.my_location),
              label: const Text('Usar minha localização atual'),
            ),
            if (_viewModel.localizacaoMudou)
              const Aviso(
                texto:
                    'A localização no mapa vai mudar. Para uma ONG, isso '
                    'muda quais doações aparecem perto.',
              ),
            if (_viewModel.ehOng) ...[
              const SizedBox(height: 12),
              AppTextField(
                label: 'Famílias atendidas',
                controller: _familias,
                somenteNumeros: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Transporte?>(
                initialValue: _viewModel.transporte,
                decoration: const InputDecoration(
                  labelText: 'Como vocês buscam as doações',
                ),
                items: [
                  for (final t in Transporte.values)
                    DropdownMenuItem<Transporte?>(
                      value: t,
                      child: Text(t.rotulo),
                    ),
                ],
                onChanged: _viewModel.escolherTransporte,
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              key: const Key('salvar_perfil'),
              texto: 'Salvar',
              carregando: _viewModel.ocupado,
              onPressed: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}
