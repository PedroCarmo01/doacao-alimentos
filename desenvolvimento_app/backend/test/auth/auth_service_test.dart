import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/auth/auth_service.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/token_service.dart';
import 'package:summit_backend/documentos/consulta_cnpj_fake.dart';
import 'package:summit_backend/documentos/documento_exceptions.dart';
import 'package:summit_backend/documentos/documento_service.dart';
import 'package:test/test.dart';

import '../apoio/em_memoria.dart';

/// Testes das regras de conta (RN01 a RN05) sem MySQL e sem internet.
void main() {
  late AuthService service;
  late TokenService tokens;
  late ContasEmMemoria contas;
  late ConsultaCnpjFake receita;

  setUp(() {
    contas = ContasEmMemoria();
    tokens = TokenService(segredo: 'segredo-de-teste-com-32-caracteres!!');
    receita = ConsultaCnpjFake(
      cadastrados: CnpjsDeTeste.receita,
      naoEncontrados: {CnpjsDeTeste.inexistente},
    );
    service = AuthService(
      usuarios: contas,
      documentos: DocumentoService(consulta: receita, perfis: contas),
      senhas: const SenhaServiceFake(),
      tokens: tokens,
      relogio: RelogioFixo(DateTime.utc(2026, 11, 1, 12)),
    );
  });

  DadosCadastro ong({String email = 'ana@exemplo.com', String? documento}) =>
      DadosCadastro(
        tipo: TipoUsuario.ong,
        nome: 'Ana Lima',
        email: email,
        senha: 'senha123',
        nomeOrganizacao: 'ONG Mãos Amigas',
        documento:
            documento ?? ValidadorDocumento.formatar(CnpjsDeTeste.associacao),
        telefone: '(11) 99999-0000',
        latitude: -23.52,
        longitude: -46.18,
        aceitouTermos: true,
      );

  DadosCadastro doador({
    required TipoEstabelecimento tipo,
    required String documento,
  }) => DadosCadastro(
    tipo: TipoUsuario.doador,
    tipoEstabelecimento: tipo,
    nome: 'José Souza',
    email: 'jose@exemplo.com',
    senha: 'senha123',
    nomeOrganizacao: 'Banca do José',
    documento: documento,
    telefone: '(11) 98888-0000',
    latitude: -23.52,
    longitude: -46.18,
    aceitouTermos: true,
  );

  Matcher recusadoCom(String codigo) => throwsA(
    isA<DocumentoRecusadoException>().having((e) => e.codigo, 'codigo', codigo),
  );

  group('cadastro', () {
    test(
      'RN01: a conta é criada com o tipo escolhido e um token válido',
      () async {
        final resposta = await service.cadastrar(
          ong(email: '  Ana@Exemplo.com '),
        );

        expect(resposta.conta.usuario.tipo, TipoUsuario.ong);
        expect(resposta.conta.usuario.email, 'ana@exemplo.com');
        final dono = tokens.validar(resposta.token);
        expect(dono.id, resposta.conta.usuario.id);
        expect(dono.tipo, TipoUsuario.ong);
      },
    );

    test('RN01: ONG não guarda tipo de estabelecimento', () async {
      final dados = DadosCadastro.fromJson({
        ...ong().toJson(),
        'tipoEstabelecimento': 'padaria',
      });

      final resposta = await service.cadastrar(dados);

      expect(resposta.conta.perfil.tipoEstabelecimento, isNull);
    });

    test('RN02: ONG com CPF é recusada', () {
      expect(
        () => service.cadastrar(ong(documento: '123.456.789-09')),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('RN02: feirante com CPF é aceito, sem consultar a Receita', () async {
      final resposta = await service.cadastrar(
        doador(tipo: TipoEstabelecimento.feira, documento: '123.456.789-09'),
      );

      expect(resposta.conta.perfil.tipoDocumento, TipoDocumento.cpf);
      expect(resposta.conta.perfil.documento, '12345678909');
      // CPF não tem consulta pública: fica pendente.
      expect(resposta.conta.perfil.verificacao, Verificacao.pendente);
      expect(receita.consultasFeitas, 0);
    });

    test(
      'RN03: ONG com CNPJ de entidade sem fins lucrativos fica verificada',
      () async {
        final resposta = await service.cadastrar(ong());

        expect(resposta.conta.perfil.verificacao, Verificacao.verificada);
        expect(resposta.conta.perfil.razaoSocial, contains('RAZAO SOCIAL'));
      },
    );

    test('RN03: CNPJ de empresa comum é recusado como ONG', () {
      expect(
        () => service.cadastrar(ong(documento: CnpjsDeTeste.empresa)),
        recusadoCom('CNPJ_NAO_E_ENTIDADE'),
      );
    });

    test('RN03: o mesmo CNPJ de empresa é aceito como doador', () async {
      final resposta = await service.cadastrar(
        doador(
          tipo: TipoEstabelecimento.supermercado,
          documento: CnpjsDeTeste.empresa,
        ),
      );

      expect(resposta.conta.perfil.ehVerificada, isTrue);
    });

    test('RN03: CNPJ que não está ATIVO é recusado', () {
      expect(
        () => service.cadastrar(
          doador(
            tipo: TipoEstabelecimento.padaria,
            documento: CnpjsDeTeste.baixada,
          ),
        ),
        recusadoCom('CNPJ_INATIVO'),
      );
    });

    test('RN03: CNPJ que não existe na Receita é recusado', () {
      expect(
        () => service.cadastrar(ong(documento: CnpjsDeTeste.inexistente)),
        recusadoCom('CNPJ_NAO_ENCONTRADO'),
      );
    });

    test(
      'RN03: BrasilAPI fora do ar não bloqueia: conta fica pendente',
      () async {
        final resposta = await service.cadastrar(
          ong(documento: CnpjsDeTeste.semResposta),
        );

        expect(resposta.conta.perfil.verificacao, Verificacao.pendente);
      },
    );

    test('RN04: e-mail repetido falha com EMAIL_EM_USO', () async {
      await service.cadastrar(ong());

      expect(
        () => service.cadastrar(ong(documento: CnpjsDeTeste.semResposta)),
        throwsA(
          isA<ConflitoException>().having(
            (e) => e.codigo,
            'codigo',
            'EMAIL_EM_USO',
          ),
        ),
      );
    });

    test('RN04: o mesmo CNPJ não pode ter duas contas', () async {
      await service.cadastrar(ong());

      expect(
        () => service.cadastrar(ong(email: 'outra@exemplo.com')),
        throwsA(
          isA<ConflitoException>().having(
            (e) => e.codigo,
            'codigo',
            'DOCUMENTO_EM_USO',
          ),
        ),
      );
    });

    test('sem aceitar os termos, o cadastro é recusado', () {
      final dados = DadosCadastro.fromJson({
        ...ong().toJson(),
        'aceitouTermos': false,
      });

      expect(
        () => service.cadastrar(dados),
        throwsA(isA<ValidacaoException>()),
      );
    });
  });

  group('login', () {
    test('RN05: login com a senha certa devolve um token válido', () async {
      await service.cadastrar(ong());

      final resposta = await service.entrar(
        const DadosLogin(email: 'ANA@exemplo.com', senha: 'senha123'),
      );

      expect(resposta.conta.usuario.nome, 'Ana Lima');
      expect(tokens.validar(resposta.token).id, resposta.conta.usuario.id);
    });

    test('senha errada e e-mail inexistente dão a MESMA mensagem', () async {
      await service.cadastrar(ong());
      final credenciaisInvalidas = throwsA(
        isA<NaoAutenticadoException>()
            .having((e) => e.codigo, 'codigo', 'CREDENCIAIS_INVALIDAS')
            .having(
              (e) => e.mensagem,
              'mensagem',
              'E-mail ou senha incorretos.',
            ),
      );

      expect(
        () => service.entrar(
          const DadosLogin(email: 'ana@exemplo.com', senha: 'errada'),
        ),
        credenciaisInvalidas,
      );
      expect(
        () => service.entrar(
          const DadosLogin(email: 'ninguem@exemplo.com', senha: 'senha123'),
        ),
        credenciaisInvalidas,
      );
    });
  });
}
