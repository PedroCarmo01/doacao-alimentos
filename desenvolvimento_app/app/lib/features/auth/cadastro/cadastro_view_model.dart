import 'package:shared_models/shared_models.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/mvvm/view_model_base.dart';
import '../../../core/sessao/sessao.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../data/documentos/documento_repository.dart';
import '../../../data/localizacao/cep_repository.dart';
import '../../../data/localizacao/localizacao_service.dart';
import 'campos_do_cadastro.dart';

/// Os passos do cadastro (T4), na ordem.
enum PassoCadastro { tipoConta, tipoDoador, dados, localizacao, termos }

/// ViewModel do cadastro em etapas (T4).
///
/// Guarda as ESCOLHAS (tipo de conta, estabelecimento, transporte,
/// localização, termos) e faz as consultas (CNPJ, CEP, GPS). Os textos
/// digitados ficam nos campos da tela e chegam aqui em [criarConta].
class CadastroViewModel extends ViewModelBase {
  CadastroViewModel({
    required AuthRepository auth,
    required Sessao sessao,
    required DocumentoRepository documentos,
    required LocalizacaoService localizacao,
    required CepRepository cep,
  }) : _auth = auth,
       _sessao = sessao,
       _documentos = documentos,
       _localizacao = localizacao,
       _cep = cep;

  final AuthRepository _auth;
  final Sessao _sessao;
  final DocumentoRepository _documentos;
  final LocalizacaoService _localizacao;
  final CepRepository _cep;

  PassoCadastro _passo = PassoCadastro.tipoConta;
  TipoUsuario? _tipoConta;
  TipoEstabelecimento? _estabelecimento;
  Transporte? _transporte;
  InfoCnpj? _infoCnpj;
  String? _avisoDocumento;
  String? _documentoRecusado;
  Coordenadas? _coordenadas;
  EnderecoDoCep? _enderecoDoCep;
  bool _aceitouTermos = false;

  PassoCadastro get passo => _passo;
  TipoUsuario? get tipoConta => _tipoConta;
  TipoEstabelecimento? get estabelecimento => _estabelecimento;
  Transporte? get transporte => _transporte;

  /// Dados da Receita, depois da pré-consulta do CNPJ.
  InfoCnpj? get infoCnpj => _infoCnpj;

  /// Ex.: "Não foi possível consultar agora; você pode continuar".
  String? get avisoDocumento => _avisoDocumento;

  /// O servidor recusou o documento (RN03): impede de continuar.
  String? get documentoRecusado => _documentoRecusado;
  Coordenadas? get coordenadas => _coordenadas;
  EnderecoDoCep? get enderecoDoCep => _enderecoDoCep;
  bool get aceitouTermos => _aceitouTermos;
  bool get ehOng => _tipoConta == TipoUsuario.ong;

  /// RN02: só feirante, produtor rural e "outro" podem usar CPF.
  bool get aceitaCpf => !ehOng && (_estabelecimento?.aceitaCpf ?? false);

  /// A ONG pula o passo "tipo de estabelecimento".
  List<PassoCadastro> get passos => [
    for (final passo in PassoCadastro.values)
      if (!(ehOng && passo == PassoCadastro.tipoDoador)) passo,
  ];

  /// De 0 a 1, para a barra de progresso.
  double get progresso => (passos.indexOf(_passo) + 1) / passos.length;

  // ------------------------------------------------------------ navegação

  void escolherTipoConta(TipoUsuario tipo) {
    if (tipo != _tipoConta) _limparDocumento();
    _tipoConta = tipo;
    _irPara(1);
  }

  void escolherEstabelecimento(TipoEstabelecimento tipo) {
    if (tipo != _estabelecimento) _limparDocumento();
    _estabelecimento = tipo;
    _irPara(1);
  }

  /// Vai para o próximo passo (a tela já validou os campos do atual).
  void avancar() => _irPara(1);

  /// Volta um passo. Devolve `false` se já está no primeiro (a tela fecha).
  bool voltar() {
    if (passos.indexOf(_passo) == 0) return false;
    _irPara(-1);
    return true;
  }

  void _irPara(int deslocamento) {
    final indice = passos.indexOf(_passo) + deslocamento;
    _passo = passos[indice.clamp(0, passos.length - 1)];
    limparErro();
    notificar();
  }

  // ------------------------------------------------------------- escolhas

  void escolherTransporte(Transporte? transporte) {
    _transporte = transporte;
    notificar();
  }

  void aceitarTermos(bool aceitou) {
    _aceitouTermos = aceitou;
    notificar();
  }

  /// O alfinete do mapa foi arrastado (o mapa se moveu).
  void moverAlfinete(Coordenadas ponto) {
    _coordenadas = ponto;
    notificar();
  }

  /// A pessoa mudou o documento: a consulta anterior não vale mais.
  void documentoAlterado() {
    final haviaConsulta =
        _infoCnpj != null ||
        _avisoDocumento != null ||
        _documentoRecusado != null;
    if (!haviaConsulta) return;
    _limparDocumento();
    notificar();
  }

  void _limparDocumento() {
    _infoCnpj = null;
    _avisoDocumento = null;
    _documentoRecusado = null;
  }

  // ------------------------------------------------------------- consultas

  /// RN03: pré-consulta do CNPJ, para preencher o nome e já avisar se ele
  /// será recusado. "BrasilAPI fora do ar" NÃO impede de continuar.
  Future<bool> consultarCnpj(String documento) => executar(() async {
    _limparDocumento();
    try {
      _infoCnpj = await _documentos.consultarCnpj(documento, _tipoConta!);
    } on ApiException catch (e) {
      if (e.codigo == 'CONSULTA_INDISPONIVEL') {
        _avisoDocumento = e.mensagem;
      } else if (e.status == 422) {
        _documentoRecusado = e.mensagem;
      } else {
        rethrow;
      }
    }
  });

  Future<bool> buscarCep(String cep) => executar(() async {
    final endereco = await _cep.buscar(cep);
    _enderecoDoCep = endereco;
    if (endereco.coordenadas != null) _coordenadas = endereco.coordenadas;
  });

  Future<bool> usarMinhaLocalizacao() => executar(() async {
    _coordenadas = await _localizacao.obterAtual();
  });

  // ---------------------------------------------------------------- final

  /// Monta o cadastro (escolhas daqui + textos da tela) e cria a conta.
  /// Se der certo, a pessoa já fica logada.
  Future<bool> criarConta(CamposDoCadastro campos) => executar(() async {
    final ponto = _coordenadas;
    if (ponto == null) {
      throw const ApiException(
        codigo: 'VALIDACAO',
        mensagem: 'Volte ao passo da localização e marque o endereço.',
      );
    }
    final resposta = await _auth.cadastrar(
      campos.paraCadastro(
        tipo: _tipoConta!,
        estabelecimento: _estabelecimento,
        transporte: _transporte,
        coordenadas: ponto,
        aceitouTermos: _aceitouTermos,
      ),
    );
    await _sessao.iniciar(resposta);
  });
}
