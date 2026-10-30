import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../data/fotos/seletor_de_fotos.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/estados.dart';
import '../../shared/widgets/primary_button.dart';
import 'campos_da_doacao.dart';
import 'campos_de_horario.dart';
import 'doacao_publicada.dart';
import 'nova_doacao_view_model.dart';
import 'secao_fotos.dart';

/// T11 — Nova doação (botão central "Doar") e edição de uma doação.
///
/// Formulário rolável com o botão **Publicar doação** fixo embaixo. Devolve
/// `true` ao fechar se algo foi salvo (a lista "Minhas doações" recarrega).
class NovaDoacaoPage extends StatefulWidget {
  const NovaDoacaoPage({
    super.key,
    required this.doacoes,
    required this.seletor,
    required this.sessao,
    required this.relogio,
    this.doacaoId,
  });

  final DoacaoRepository doacoes;
  final SeletorDeFotos seletor;
  final Sessao sessao;
  final Relogio relogio;

  /// Preenchido = editar esta doação.
  final int? doacaoId;

  @override
  State<NovaDoacaoPage> createState() => _NovaDoacaoPageState();
}

class _NovaDoacaoPageState extends State<NovaDoacaoPage> {
  late final NovaDoacaoViewModel _viewModel;
  final _formulario = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _quantidade = TextEditingController();
  final _peso = TextEditingController();
  final _descricao = TextEditingController();
  final _endereco = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = NovaDoacaoViewModel(
      doacoes: widget.doacoes,
      seletor: widget.seletor,
      relogio: widget.relogio,
      doacaoId: widget.doacaoId,
    );
    _endereco.text = widget.sessao.perfil?.endereco ?? '';
    if (_viewModel.editando) _carregarParaEditar();
  }

  Future<void> _carregarParaEditar() async {
    await _viewModel.carregarParaEditar();
    final doacao = _viewModel.original;
    if (doacao == null) return;
    _titulo.text = doacao.titulo;
    _quantidade.text = doacao.quantidadeTexto.split(' ').first;
    _peso.text = _numero(doacao.pesoKg);
    _descricao.text = doacao.descricao ?? '';
    _endereco.text = doacao.endereco ?? '';
  }

  /// 6.0 → "6"; 4.8 → "4,8" (como a pessoa digitaria).
  static String _numero(double valor) => valor == valor.truncateToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toString().replaceAll('.', ',');

  @override
  void dispose() {
    for (final campo in [_titulo, _quantidade, _peso, _descricao, _endereco]) {
      campo.dispose();
    }
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) return;
    final salvou = await _viewModel.salvar(
      CamposDaDoacao(
        titulo: _titulo.text,
        quantidade: _quantidade.text,
        pesoKg: _peso.text,
        descricao: _descricao.text,
        endereco: _endereco.text,
      ),
    );
    if (!salvou || !mounted || !_viewModel.editando) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Doação atualizada.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        // Publicou: mostra a tela de sucesso no lugar do formulário.
        if (_viewModel.resultado != null && !_viewModel.editando) {
          return DoacaoPublicada(
            ongsAvisadas: _viewModel.ongsAvisadas,
            fotosQueFalharam: _viewModel.fotosQueFalharam,
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(_viewModel.editando ? 'Editar doação' : 'Nova doação'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: _conteudo()),
                _rodape(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _conteudo() {
    final vm = _viewModel;
    if (vm.editando && vm.original == null) {
      final erro = vm.erro;
      return erro == null
          ? const CarregandoWidget()
          : ErroWidget(mensagem: erro, onTentar: _carregarParaEditar);
    }
    return Form(
      key: _formulario,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SecaoFotos(viewModel: vm),
          const SizedBox(height: 24),
          AppTextField(
            key: const Key('campo_titulo'),
            label: 'O que é? (ex.: Pães do dia)',
            controller: _titulo,
            prefixIcon: Icons.fastfood_outlined,
            validator: ValidadorDoacao.titulo,
          ),
          CamposDaEscolha(viewModel: vm, quantidade: _quantidade, peso: _peso),
          CamposDeHorario(viewModel: vm),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Endereço de retirada',
            controller: _endereco,
            prefixIcon: Icons.place_outlined,
            textoAjuda: 'Já vem o do cadastro. Pode trocar.',
            validator: ValidadorUsuario.textoLivre,
          ),
          AppTextField(
            label: 'Observações (opcional)',
            controller: _descricao,
            prefixIcon: Icons.notes,
            textoAjuda: 'Ex.: retirar pela porta lateral.',
            validator: ValidadorDoacao.descricao,
          ),
          FileiraDeEscolhas(
            titulo: 'Precisa de veículo? (opcional)',
            rotulos: [
              for (final opcao in VeiculoNecessario.values) opcao.rotulo,
            ],
            selecionada: vm.veiculo == null
                ? null
                : VeiculoNecessario.values.indexOf(vm.veiculo!),
            aoEscolher: (indice) => vm.escolherVeiculo(
              indice == null ? null : VeiculoNecessario.values[indice],
            ),
          ),
          CheckboxListTile(
            key: const Key('declaracao'),
            value: vm.declaracao,
            onChanged: (marcada) => vm.marcarDeclaracao(marcada ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Declaro que os alimentos estão dentro da validade e próprios '
              'para consumo.',
            ),
          ),
        ],
      ),
    );
  }

  /// Erro (se houver) e o botão principal, fixos embaixo.
  Widget _rodape() {
    final erro = _viewModel.erro;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (erro != null &&
              (_viewModel.original != null || !_viewModel.editando))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                erro,
                key: const Key('erro_doacao'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.erro),
              ),
            ),
          PrimaryButton(
            key: const Key('botao_publicar'),
            texto: _viewModel.editando
                ? 'Salvar alterações'
                : 'Publicar doação',
            carregando: _viewModel.ocupado,
            onPressed: _salvar,
          ),
        ],
      ),
    );
  }
}
