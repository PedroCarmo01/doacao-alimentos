import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';
import 'receita_fake.dart';

/// As contas do modo Fake: os MESMOS 7 usuários do seed do backend
/// (`backend/tool/seed/contas_de_exemplo.dart`) e as MESMAS regras do
/// `AuthService` (RN01 a RN04), com os mesmos códigos de erro.
///
/// Fica separada do `BancoFake` para cada classe ter uma responsabilidade.
class ContasFake {
  ContasFake(this._relogio) {
    _popular();
  }

  static const senhaPadrao = 'senha123';

  final Relogio _relogio;
  final Map<int, _ContaComSenha> _registros = {};
  int _proximoId = 1;

  Conta? porId(int? id) => _registros[id]?.conta;

  /// Usada pelo BancoFake para ligar as doações de exemplo aos doadores.
  Conta porEmail(String email) => _registros.values
      .firstWhere((registro) => registro.conta.usuario.email == email)
      .conta;

  Conta get primeiroDoador => _registros.values
      .firstWhere((registro) => registro.conta.usuario.ehDoador)
      .conta;

  /// Mesmas regras do `AuthService.cadastrar` no backend.
  Conta cadastrar(DadosCadastro recebidos) {
    final dados = recebidos.normalizado();
    final erros = ValidadorUsuario.validarCadastro(dados);
    if (erros.isNotEmpty) {
      throw ApiException(
        codigo: 'VALIDACAO',
        mensagem: erros.first,
        status: 400,
        detalhes: erros,
      );
    }
    if (_existe((conta) => conta.usuario.email == dados.email)) {
      throw const ApiException(
        codigo: 'EMAIL_EM_USO',
        mensagem: 'Este e-mail já está cadastrado. Entre com ele ou use outro.',
        status: 409,
      );
    }
    if (_existe((conta) => conta.perfil.documento == dados.documento)) {
      throw ApiException(
        codigo: 'DOCUMENTO_EM_USO',
        mensagem: 'Já existe uma conta com este ${dados.tipoDocumento.rotulo}.',
        status: 409,
      );
    }
    // RN03: CPF e CNPJ que a "Receita" não conhece ficam pendentes.
    InfoCnpj? info;
    if (dados.tipoDocumento == TipoDocumento.cnpj) {
      final encontrado = ReceitaFake.consultar(dados.documento);
      if (encontrado != null) {
        info = ReceitaFake.conferir(encontrado, dados.tipo);
      }
    }
    return _adicionar(dados, info);
  }

  Conta autenticar(String email, String senha) {
    final procurado = email.trim().toLowerCase();
    for (final registro in _registros.values) {
      if (registro.conta.usuario.email == procurado &&
          registro.senha == senha) {
        return registro.conta;
      }
    }
    throw const ApiException(
      codigo: 'CREDENCIAIS_INVALIDAS',
      mensagem: 'E-mail ou senha incorretos.',
      status: 401,
    );
  }

  bool _existe(bool Function(Conta conta) teste) =>
      _registros.values.any((registro) => teste(registro.conta));

  Conta _adicionar(
    DadosCadastro dados,
    InfoCnpj? info, {
    DateTime? suspensaAte,
    Verificacao? verificacao,
  }) {
    final id = _proximoId++;
    final conta = Conta(
      usuario: Usuario(
        id: id,
        nome: dados.nome,
        email: dados.email,
        tipo: dados.tipo,
      ),
      perfil: Perfil(
        usuarioId: id,
        nomeOrganizacao: dados.nomeOrganizacao,
        tipoEstabelecimento: dados.tipoEstabelecimento,
        tipoDocumento: dados.tipoDocumento,
        documento: dados.documento,
        razaoSocial: info?.razaoSocial,
        verificacao:
            verificacao ??
            (info == null ? Verificacao.pendente : Verificacao.verificada),
        telefone: dados.telefone,
        endereco: dados.endereco,
        cep: dados.cep,
        latitude: dados.latitude,
        longitude: dados.longitude,
        familiasAtendidas: dados.familiasAtendidas,
        transporte: dados.transporte,
        suspensaAte: suspensaAte,
        infoExtra: dados.infoExtra,
      ),
    );
    _registros[id] = _ContaComSenha(conta, dados.senha);
    return conta;
  }

  /// Os 7 usuários do seed (mesmos e-mails, documentos e lugares).
  void _popular() {
    void criar(
      TipoUsuario tipo,
      String email,
      String responsavel,
      String organizacao,
      String documento,
      double latitude,
      double longitude, {
      TipoEstabelecimento? estabelecimento,
      Transporte? transporte,
      int? familias,
      String? infoExtra,
      DateTime? suspensaAte,
    }) {
      final dados = DadosCadastro(
        tipo: tipo,
        tipoEstabelecimento: estabelecimento,
        nome: responsavel,
        email: email,
        senha: senhaPadrao,
        nomeOrganizacao: organizacao,
        documento: documento,
        telefone: '(11) 4799-0000',
        cep: '08780000',
        latitude: latitude,
        longitude: longitude,
        transporte: transporte,
        familiasAtendidas: familias,
        infoExtra: infoExtra,
        aceitouTermos: true,
      );
      // CPF não tem consulta: pendente. CNPJs do seed: verificados.
      final ehCpf = dados.tipoDocumento == TipoDocumento.cpf;
      _adicionar(
        dados,
        null,
        suspensaAte: suspensaAte,
        verificacao: ehCpf ? Verificacao.pendente : Verificacao.verificada,
      );
    }

    String cnpj(String doze) => ValidadorDocumento.completarCnpj(doze);
    const doador = TipoUsuario.doador;
    const ong = TipoUsuario.ong;

    criar(
      doador,
      'mercado@exemplo.com',
      'Gerente do Mercado',
      'Mercado Bom Preço',
      cnpj('904500010001'),
      -23.5229,
      -46.1880,
      estabelecimento: TipoEstabelecimento.supermercado,
    );
    criar(
      doador,
      'padaria@exemplo.com',
      'Dono da Padaria',
      'Padaria Pão Quente',
      cnpj('904500020001'),
      -23.5262,
      -46.1932,
      estabelecimento: TipoEstabelecimento.padaria,
    );
    criar(
      doador,
      'feirante@exemplo.com',
      'Seu Zé da Feira',
      'Banca do Zé',
      ValidadorDocumento.completarCpf('904500030'),
      -23.5205,
      -46.1902,
      estabelecimento: TipoEstabelecimento.feira,
      infoExtra: 'Feira do Mercadão — terças e sábados',
    );
    criar(
      ong,
      'maosamigas@exemplo.com',
      'Coordenação Mãos Amigas',
      'ONG Mãos Amigas',
      cnpj('904600010001'),
      -23.5180,
      -46.1850,
      transporte: Transporte.carro,
      familias: 120,
    );
    criar(
      ong,
      'pratocheio@exemplo.com',
      'Coordenação Prato Cheio',
      'Instituto Prato Cheio',
      cnpj('904600020001'),
      -23.5400,
      -46.2100,
      transporte: Transporte.van,
      familias: 60,
    );
    criar(
      ong,
      'suspensa@exemplo.com',
      'Coordenação Esperança',
      'Casa Esperança',
      cnpj('904600030001'),
      -23.5300,
      -46.1950,
      transporte: Transporte.aPe,
      // RN24: suspensa por 48 h; faltam 30 h.
      suspensaAte: _relogio.agora().add(const Duration(hours: 30)),
    );
    criar(
      ong,
      'distante@exemplo.com',
      'Coordenação Distante',
      'Associação Distante',
      cnpj('904600040001'),
      -23.5505,
      -46.6333,
    );
  }
}

class _ContaComSenha {
  _ContaComSenha(this.conta, this.senha);

  final Conta conta;
  final String senha;
}
