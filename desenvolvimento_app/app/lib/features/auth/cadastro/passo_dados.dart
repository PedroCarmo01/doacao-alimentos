import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/aviso.dart';
import 'cadastro_view_model.dart';
import 'controladores_do_cadastro.dart';

/// Cadastro, passo 3 — documento e dados (RN02, RN03).
///
/// Ao completar um CNPJ válido, a tela consulta a Receita (BrasilAPI) e
/// preenche o nome da organização.
class PassoDados extends StatefulWidget {
  const PassoDados({
    super.key,
    required this.viewModel,
    required this.campos,
    required this.formulario,
    required this.aoMudarDocumento,
  });

  final CadastroViewModel viewModel;
  final ControladoresDoCadastro campos;
  final GlobalKey<FormState> formulario;
  final ValueChanged<String> aoMudarDocumento;

  @override
  State<PassoDados> createState() => _PassoDadosState();
}

class _PassoDadosState extends State<PassoDados> {
  bool _senhaVisivel = false;

  CadastroViewModel get _vm => widget.viewModel;
  ControladoresDoCadastro get _campos => widget.campos;

  String? _validarDocumento(String? valor) => ValidadorUsuario.documento(
    valor,
    tipo: _vm.tipoConta!,
    estabelecimento: _vm.estabelecimento,
  );

  @override
  Widget build(BuildContext context) {
    final estab = _vm.estabelecimento;
    return Form(
      key: widget.formulario,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _vm.ehOng ? 'Dados da ONG' : 'Dados do estabelecimento',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          AppTextField(
            key: const Key('campo_documento'),
            label: _vm.aceitaCpf ? 'CNPJ ou CPF' : 'CNPJ',
            controller: _campos.documento,
            prefixIcon: Icons.badge_outlined,
            somenteNumeros: true,
            tamanhoMaximo: ValidadorDocumento.tamanhoCnpj,
            textoAjuda: _textoAjudaDocumento(),
            erro: _vm.documentoRecusado,
            validator: _validarDocumento,
            aoMudar: widget.aoMudarDocumento,
          ),
          _SituacaoDoDocumento(viewModel: _vm),
          AppTextField(
            key: const Key('campo_organizacao'),
            label: _vm.ehOng ? 'Nome da ONG' : 'Nome do estabelecimento',
            controller: _campos.nomeOrganizacao,
            prefixIcon: Icons.business,
            validator: ValidadorUsuario.nomeOrganizacao,
          ),
          AppTextField(
            key: const Key('campo_responsavel'),
            label: 'Nome do responsável',
            controller: _campos.nomeResponsavel,
            prefixIcon: Icons.person_outline,
            validator: ValidadorUsuario.nome,
          ),
          AppTextField(
            key: const Key('campo_telefone'),
            label: 'Telefone com DDD',
            controller: _campos.telefone,
            prefixIcon: Icons.phone_outlined,
            somenteNumeros: true,
            tamanhoMaximo: 11,
            validator: ValidadorUsuario.telefoneObrigatorio,
          ),
          if (_vm.ehOng) ..._camposDaOng(),
          if (estab == TipoEstabelecimento.feira)
            _infoExtra('Nome e dias da feira (opcional)'),
          if (estab == TipoEstabelecimento.outro) _infoExtra('Qual tipo?'),
          const Divider(height: 32),
          AppTextField(
            key: const Key('campo_email_cadastro'),
            label: 'E-mail',
            controller: _campos.email,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: ValidadorUsuario.email,
          ),
          AppTextField(
            key: const Key('campo_senha_cadastro'),
            label: 'Senha (mínimo 6 caracteres)',
            controller: _campos.senha,
            obscure: !_senhaVisivel,
            prefixIcon: Icons.lock_outline,
            acaoDoTeclado: TextInputAction.done,
            validator: ValidadorUsuario.senha,
            sufixo: IconButton(
              tooltip: _senhaVisivel ? 'Esconder a senha' : 'Mostrar a senha',
              icon: Icon(
                _senhaVisivel ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
            ),
          ),
        ],
      ),
    );
  }

  String? _textoAjudaDocumento() {
    final numero = _campos.documento.text;
    if (numero.length >= ValidadorDocumento.tamanhoCpf) {
      return ValidadorDocumento.formatar(numero);
    }
    return 'Só os números.';
  }

  Widget _infoExtra(String rotulo) => AppTextField(
    label: rotulo,
    controller: _campos.infoExtra,
    prefixIcon: Icons.notes,
    validator: ValidadorUsuario.textoLivre,
  );

  List<Widget> _camposDaOng() => [
    AppTextField(
      label: 'Quantas famílias atende? (opcional)',
      controller: _campos.familiasAtendidas,
      prefixIcon: Icons.family_restroom,
      somenteNumeros: true,
      tamanhoMaximo: 6,
      validator: (valor) =>
          ValidadorUsuario.familiasAtendidas(int.tryParse(valor ?? '')),
    ),
    _infoExtra('Dias e horários em que costuma retirar (opcional)'),
    const Text('Como vocês buscam as doações?'),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      children: [
        for (final opcao in Transporte.values)
          ChoiceChip(
            label: Text(opcao.rotulo),
            selected: _vm.transporte == opcao,
            onSelected: (marcado) =>
                _vm.escolherTransporte(marcado ? opcao : null),
          ),
      ],
    ),
    const SizedBox(height: 16),
  ];
}

/// Resultado da consulta do CNPJ: carregando, encontrado ou aviso.
class _SituacaoDoDocumento extends StatelessWidget {
  const _SituacaoDoDocumento({required this.viewModel});

  final CadastroViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final info = viewModel.infoCnpj;
    final aviso = viewModel.avisoDocumento;
    if (viewModel.ocupado) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Consultando o CNPJ na Receita Federal...'),
          ],
        ),
      );
    }
    if (info != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Aviso(
          key: const Key('cnpj_encontrado'),
          icone: Icons.verified,
          cor: AppColors.verde,
          texto: 'CNPJ ativo na Receita: ${info.razaoSocial}',
        ),
      );
    }
    if (aviso != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Aviso(texto: aviso),
      );
    }
    return const SizedBox.shrink();
  }
}
