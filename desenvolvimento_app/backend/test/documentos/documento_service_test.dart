import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/documentos/consulta_cnpj_fake.dart';
import 'package:summit_backend/documentos/documento_exceptions.dart';
import 'package:summit_backend/documentos/documento_service.dart';
import 'package:test/test.dart';

import '../apoio/em_memoria.dart';

/// Pré-consulta do CNPJ (`GET /documentos/{numero}`) e reverificação dos
/// perfis pendentes (RN03).
void main() {
  late ContasEmMemoria contas;
  late ConsultaCnpjFake receita;
  late DocumentoService service;

  setUp(() {
    contas = ContasEmMemoria();
    receita = ConsultaCnpjFake(cadastrados: CnpjsDeTeste.receita);
    service = DocumentoService(consulta: receita, perfis: contas);
  });

  Matcher recusadoCom(String codigo) => throwsA(
    isA<DocumentoRecusadoException>().having((e) => e.codigo, 'codigo', codigo),
  );

  group('preConsultar', () {
    test('devolve os dados da Receita para preencher o formulário', () async {
      final info = await service.preConsultar(
        ValidadorDocumento.formatar(CnpjsDeTeste.associacao),
        tipo: TipoUsuario.ong,
      );

      expect(info.cnpj, CnpjsDeTeste.associacao);
      expect(info.semFinsLucrativos, isTrue);
    });

    test('RN02: dígitos errados respondem DOCUMENTO_INVALIDO', () {
      expect(
        () => service.preConsultar('11222333000182'),
        recusadoCom('DOCUMENTO_INVALIDO'),
      );
    });

    test('RN03: empresa só é recusada quando a pergunta é para ONG', () async {
      expect(
        () => service.preConsultar(CnpjsDeTeste.empresa, tipo: TipoUsuario.ong),
        recusadoCom('CNPJ_NAO_E_ENTIDADE'),
      );
      final info = await service.preConsultar(
        CnpjsDeTeste.empresa,
        tipo: TipoUsuario.doador,
      );
      expect(info.ativa, isTrue);
    });

    test('RN03: CNPJ baixado responde CNPJ_INATIVO', () {
      expect(
        () => service.preConsultar(CnpjsDeTeste.baixada),
        recusadoCom('CNPJ_INATIVO'),
      );
    });

    test('BrasilAPI fora do ar vira aviso CONSULTA_INDISPONIVEL (503)', () {
      expect(
        () => service.preConsultar(CnpjsDeTeste.semResposta),
        throwsA(
          isA<ConsultaIndisponivelException>().having(
            (e) => e.statusHttp,
            'status',
            503,
          ),
        ),
      );
    });
  });

  group('reverificarPendentes', () {
    Future<void> cadastrarPendente(TipoUsuario tipo, String cnpj) =>
        contas.criar(
          DadosCadastro(
            tipo: tipo,
            tipoEstabelecimento: tipo == TipoUsuario.doador
                ? TipoEstabelecimento.padaria
                : null,
            nome: 'Responsável',
            email: '$cnpj@exemplo.com',
            senha: 'senha123',
            nomeOrganizacao: 'Organização',
            documento: cnpj,
            telefone: '(11) 99999-0000',
            latitude: 0,
            longitude: 0,
            aceitouTermos: true,
          ),
          senhaHash: 'x',
          criadoEm: DateTime.utc(2026),
          verificacao: Verificacao.pendente,
        );

    test(
      'RN03: quando a BrasilAPI volta, o perfil pendente vira verificado',
      () async {
        await cadastrarPendente(TipoUsuario.ong, CnpjsDeTeste.associacao);
        await cadastrarPendente(TipoUsuario.doador, CnpjsDeTeste.empresa);

        final verificados = await service.reverificarPendentes();

        expect(verificados, 2);
        expect(contas.verificados, [1, 2]);
      },
    );

    test('RN03: ONG com CNPJ de empresa continua pendente', () async {
      await cadastrarPendente(TipoUsuario.ong, CnpjsDeTeste.empresa);
      await cadastrarPendente(TipoUsuario.ong, CnpjsDeTeste.semResposta);

      expect(await service.reverificarPendentes(), 0);
      expect(contas.verificados, isEmpty);
    });
  });
}
