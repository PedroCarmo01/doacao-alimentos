import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/features/auth/cadastro/cadastro_view_model.dart';
import 'package:summit_app/features/auth/cadastro/campos_do_cadastro.dart';

/// T4 — cadastro em etapas, no modo Fake (mesmas regras do backend).
///
/// CNPJs de teste (os mesmos do roteiro da etapa 1):
/// - 11.222.333/0001-81: associação ATIVA (pode ser ONG);
/// - 00.000.000/0001-91: empresa ATIVA (não pode ser ONG).
void main() {
  const cnpjDeAssociacao = '11222333000181';
  const cnpjDeEmpresa = '00000000000191';

  late Dependencias deps;
  late CadastroViewModel vm;

  setUp(() {
    deps = Dependencias.fake(
      banco: BancoFake(atrasoDeRede: Duration.zero, simularNovasDoacoes: false),
    );
    vm = CadastroViewModel(
      auth: deps.auth,
      sessao: deps.sessao,
      documentos: deps.documentos,
      localizacao: deps.localizacao,
      cep: deps.cep,
    );
  });

  CamposDoCadastro campos(String documento, {String email = 'nova@ex.com'}) =>
      CamposDoCadastro(
        documento: documento,
        nomeOrganizacao: 'Organização Nova',
        nomeResponsavel: 'Maria Silva',
        telefone: '11988887777',
        email: email,
        senha: 'senha123',
        endereco: 'Rua Nova, 10',
      );

  /// Faz os passos até a localização marcada e os termos aceitos.
  Future<void> prepararAteOsTermos() async {
    await vm.usarMinhaLocalizacao();
    vm.aceitarTermos(true);
  }

  test('a ONG pula o passo do tipo de estabelecimento', () {
    vm.escolherTipoConta(TipoUsuario.ong);

    expect(vm.passo, PassoCadastro.dados);
    expect(vm.passos, isNot(contains(PassoCadastro.tipoDoador)));
  });

  test('o doador passa pelo tipo de estabelecimento', () {
    vm.escolherTipoConta(TipoUsuario.doador);
    expect(vm.passo, PassoCadastro.tipoDoador);

    vm.escolherEstabelecimento(TipoEstabelecimento.feira);
    expect(vm.passo, PassoCadastro.dados);
    expect(vm.aceitaCpf, isTrue); // RN02
  });

  test('voltar no primeiro passo avisa a tela para fechar', () {
    expect(vm.voltar(), isFalse);
  });

  test('RN03: pré-consulta de CNPJ de associação preenche os dados', () async {
    vm.escolherTipoConta(TipoUsuario.ong);

    await vm.consultarCnpj(cnpjDeAssociacao);

    expect(vm.infoCnpj?.semFinsLucrativos, isTrue);
    expect(vm.documentoRecusado, isNull);
  });

  test(
    'RN03: CNPJ de empresa comum é recusado como ONG já na consulta',
    () async {
      vm.escolherTipoConta(TipoUsuario.ong);

      await vm.consultarCnpj(cnpjDeEmpresa);

      expect(vm.documentoRecusado, contains('entidade sem fins lucrativos'));
    },
  );

  test('RN03: Receita sem resposta só avisa (dá para continuar)', () async {
    vm.escolherTipoConta(TipoUsuario.ong);

    await vm.consultarCnpj(ValidadorDocumento.completarCnpj('123456780001'));

    expect(vm.avisoDocumento, isNotNull);
    expect(vm.documentoRecusado, isNull);
  });

  test(
    'RN01–RN03: ONG com CNPJ de associação cria a conta verificada',
    () async {
      vm.escolherTipoConta(TipoUsuario.ong);
      await prepararAteOsTermos();

      final criou = await vm.criarConta(campos(cnpjDeAssociacao));

      expect(criou, isTrue, reason: vm.erro);
      final perfil = deps.sessao.perfil!;
      expect(deps.sessao.usuario!.ehOng, isTrue);
      expect(perfil.verificacao, Verificacao.verificada);
    },
  );

  test('RN03: CNPJ de empresa comum é recusado como ONG no cadastro', () async {
    vm.escolherTipoConta(TipoUsuario.ong);
    await prepararAteOsTermos();

    final criou = await vm.criarConta(campos(cnpjDeEmpresa));

    expect(criou, isFalse);
    expect(vm.erro, contains('entidade sem fins lucrativos'));
  });

  test('RN02: feirante com CPF cria a conta (verificação pendente)', () async {
    vm.escolherTipoConta(TipoUsuario.doador);
    vm.escolherEstabelecimento(TipoEstabelecimento.feira);
    await prepararAteOsTermos();

    final criou = await vm.criarConta(campos('123.456.789-09'));

    expect(criou, isTrue, reason: vm.erro);
    expect(deps.sessao.perfil!.tipoDocumento, TipoDocumento.cpf);
    expect(deps.sessao.perfil!.verificacao, Verificacao.pendente);
  });

  test('RN04: e-mail que já existe é recusado', () async {
    vm.escolherTipoConta(TipoUsuario.ong);
    await prepararAteOsTermos();

    final criou = await vm.criarConta(
      campos(cnpjDeAssociacao, email: 'maosamigas@exemplo.com'),
    );

    expect(criou, isFalse);
    expect(vm.erro, contains('já está cadastrado'));
  });

  test('RN04: o mesmo CNPJ não pode ter duas contas', () async {
    vm.escolherTipoConta(TipoUsuario.ong);
    await prepararAteOsTermos();
    // CNPJ fictício da ONG Mãos Amigas, que já existe nos dados de exemplo.
    final cnpjDaMaosAmigas = ValidadorDocumento.completarCnpj('904600010001');

    final criou = await vm.criarConta(campos(cnpjDaMaosAmigas));

    expect(criou, isFalse);
    expect(vm.erro, 'Já existe uma conta com este CNPJ.');
  });

  test('sem marcar a localização, pede para voltar ao passo do mapa', () async {
    vm.escolherTipoConta(TipoUsuario.ong);
    vm.aceitarTermos(true);

    final criou = await vm.criarConta(campos(cnpjDeAssociacao));

    expect(criou, isFalse);
    expect(vm.erro, contains('localização'));
  });

  test('buscar o CEP preenche o endereço e o ponto do mapa', () async {
    final achou = await vm.buscarCep('08780-000');

    expect(achou, isTrue);
    expect(vm.enderecoDoCep?.cidade, 'Mogi das Cruzes');
    expect(vm.coordenadas, isNotNull);
  });
}
