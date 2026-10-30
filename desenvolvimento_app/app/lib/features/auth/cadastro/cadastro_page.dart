import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/sessao/sessao.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../data/documentos/documento_repository.dart';
import '../../../data/localizacao/cep_repository.dart';
import '../../../data/localizacao/localizacao_service.dart';
import '../../../shared/widgets/primary_button.dart';
import 'cadastro_view_model.dart';
import 'controladores_do_cadastro.dart';
import 'passo_dados.dart';
import 'passo_localizacao.dart';
import 'passo_termos.dart';
import 'passo_tipo_conta.dart';
import 'passo_tipo_doador.dart';

/// T4 — Cadastro em etapas, com barra de progresso.
///
/// Dividir em passos curtos é mais fácil de preencher no celular do que um
/// formulário enorme. Cada passo é um widget próprio (`passo_*.dart`).
class CadastroPage extends StatefulWidget {
  const CadastroPage({
    super.key,
    required this.auth,
    required this.sessao,
    required this.documentos,
    required this.localizacao,
    required this.cep,
  });

  final AuthRepository auth;
  final Sessao sessao;
  final DocumentoRepository documentos;
  final LocalizacaoService localizacao;
  final CepRepository cep;

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  late final CadastroViewModel _viewModel;
  final _campos = ControladoresDoCadastro();
  final _formularioDados = GlobalKey<FormState>();
  final _formularioLocal = GlobalKey<FormState>();
  final _mapa = MapController();

  @override
  void initState() {
    super.initState();
    _viewModel = CadastroViewModel(
      auth: widget.auth,
      sessao: widget.sessao,
      documentos: widget.documentos,
      localizacao: widget.localizacao,
      cep: widget.cep,
    );
  }

  @override
  void dispose() {
    _campos.dispose();
    _mapa.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  // ------------------------------------------------------- ações dos passos

  /// Com 14 números de um CNPJ válido, consulta a Receita sozinho.
  Future<void> _aoMudarDocumento(String texto) async {
    _viewModel.documentoAlterado();
    if (!ValidadorDocumento.cnpjValido(texto)) return;
    await _viewModel.consultarCnpj(texto);
    final info = _viewModel.infoCnpj;
    if (info != null && _campos.nomeOrganizacao.text.trim().isEmpty) {
      _campos.nomeOrganizacao.text = info.nomeSugerido;
    }
  }

  Future<void> _buscarCep() async {
    final achou = await _viewModel.buscarCep(_campos.cep.text);
    final endereco = _viewModel.enderecoDoCep;
    if (!achou || endereco == null) return;
    if (_campos.endereco.text.trim().isEmpty) {
      _campos.endereco.text = '${endereco.textoParaEndereco}, nº ';
    }
    _centralizarMapa();
  }

  Future<void> _usarGps() async {
    if (await _viewModel.usarMinhaLocalizacao()) _centralizarMapa();
  }

  void _centralizarMapa() {
    final ponto = _viewModel.coordenadas;
    if (ponto == null) return;
    _mapa.move(
      LatLng(ponto.latitude, ponto.longitude),
      PassoLocalizacao.zoomInicial,
    );
  }

  /// Botão fixo embaixo: confere o passo atual e segue (ou cria a conta).
  Future<void> _continuar() async {
    switch (_viewModel.passo) {
      case PassoCadastro.dados:
        final ok = _formularioDados.currentState!.validate();
        if (ok && _viewModel.documentoRecusado == null) _viewModel.avancar();
      case PassoCadastro.localizacao:
        if (!_formularioLocal.currentState!.validate()) return;
        if (_viewModel.coordenadas == null) {
          _mostrar(
            'Marque o local: busque o CEP, use o GPS ou arraste o mapa.',
          );
          return;
        }
        _viewModel.avancar();
      case PassoCadastro.termos:
        await _criarConta();
      case PassoCadastro.tipoConta:
      case PassoCadastro.tipoDoador:
        break; // estes passos avançam ao tocar no cartão
    }
  }

  Future<void> _criarConta() async {
    if (!_viewModel.aceitouTermos) {
      _mostrar('Marque a caixa dos Termos para criar a conta.');
      return;
    }
    final criou = await _viewModel.criarConta(_campos.campos());
    if (!criou || !mounted) return;
    // Já entra logado (T4, etapa 5) e o "voltar" não volta ao cadastro.
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.casca, (_) => false);
  }

  void _mostrar(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  void _voltar() {
    if (!_viewModel.voltar()) Navigator.pop(context);
  }

  // ------------------------------------------------------------------ tela

  @override
  Widget build(BuildContext context) {
    // PopScope: o "voltar" do Android volta UM passo, não sai do cadastro.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _voltar();
      },
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Criar conta'),
            leading: IconButton(
              tooltip: 'Voltar',
              icon: const Icon(Icons.arrow_back),
              onPressed: _voltar,
            ),
            bottom: _BarraDeProgresso(viewModel: _viewModel),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: _passoAtual()),
                _rodape(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passoAtual() => switch (_viewModel.passo) {
    PassoCadastro.tipoConta => PassoTipoConta(
      selecionado: _viewModel.tipoConta,
      aoEscolher: _viewModel.escolherTipoConta,
    ),
    PassoCadastro.tipoDoador => PassoTipoDoador(
      selecionado: _viewModel.estabelecimento,
      aoEscolher: _viewModel.escolherEstabelecimento,
    ),
    PassoCadastro.dados => PassoDados(
      viewModel: _viewModel,
      campos: _campos,
      formulario: _formularioDados,
      aoMudarDocumento: _aoMudarDocumento,
    ),
    PassoCadastro.localizacao => Form(
      key: _formularioLocal,
      child: PassoLocalizacao(
        viewModel: _viewModel,
        campos: _campos,
        mapa: _mapa,
        aoBuscarCep: _buscarCep,
        aoUsarGps: _usarGps,
      ),
    ),
    PassoCadastro.termos => PassoTermos(
      aceitou: _viewModel.aceitouTermos,
      aoMudar: _viewModel.aceitarTermos,
    ),
  };

  /// Erro (se houver) e o botão principal, fixos na parte de baixo.
  Widget _rodape() {
    final passo = _viewModel.passo;
    final temBotao =
        passo != PassoCadastro.tipoConta && passo != PassoCadastro.tipoDoador;
    final erro = _viewModel.erro;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (erro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                erro,
                key: const Key('erro_cadastro'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.erro),
              ),
            ),
          if (temBotao)
            PrimaryButton(
              key: const Key('botao_continuar'),
              texto: passo == PassoCadastro.termos
                  ? 'Criar conta'
                  : 'Continuar',
              carregando: _viewModel.ocupado,
              onPressed: _continuar,
            ),
        ],
      ),
    );
  }
}

class _BarraDeProgresso extends StatelessWidget implements PreferredSizeWidget {
  const _BarraDeProgresso({required this.viewModel});

  final CadastroViewModel viewModel;

  @override
  Size get preferredSize => const Size.fromHeight(6);

  @override
  Widget build(BuildContext context) {
    final passos = viewModel.passos;
    final atual = passos.indexOf(viewModel.passo) + 1;
    return Semantics(
      label: 'Passo $atual de ${passos.length}',
      child: LinearProgressIndicator(
        value: viewModel.progresso,
        minHeight: 6,
        backgroundColor: AppColors.verdeClaro,
        color: AppColors.laranja,
      ),
    );
  }
}
