import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/doacoes/doacao_service.dart';
import 'package:test/test.dart';

import '../apoio/doacoes_em_memoria.dart';
import '../apoio/em_memoria.dart';
import '../apoio/notificacoes_em_memoria.dart';

/// Regras das doações do doador: RN10, RN12, RN13 (e o acesso ao detalhe).
void main() {
  // 15/09/2026 12:00 UTC = 09:00 em Brasília.
  final agora = DateTime.utc(2026, 9, 15, 12);
  late RelogioFixo relogio;
  late ContasEmMemoria contas;
  late DoacoesEmMemoria doacoes;
  late DoacaoService service;
  late UsuarioAutenticado doador;
  late UsuarioAutenticado outroDoador;
  late UsuarioAutenticado ong;

  Future<UsuarioAutenticado> criarConta(TipoUsuario tipo, String email) async {
    final conta = await contas.criar(
      DadosCadastro(
        tipo: tipo,
        tipoEstabelecimento: tipo == TipoUsuario.doador
            ? TipoEstabelecimento.padaria
            : null,
        nome: 'Responsável',
        email: email,
        senha: 'senha123',
        nomeOrganizacao: 'Org $email',
        documento: '${contas.registros.length}',
        latitude: -23.52,
        longitude: -46.18,
        aceitouTermos: true,
      ),
      senhaHash: 'x',
      criadoEm: agora,
      verificacao: Verificacao.verificada,
    );
    return UsuarioAutenticado(id: conta.usuario.id, tipo: tipo);
  }

  setUp(() async {
    relogio = RelogioFixo(agora);
    contas = ContasEmMemoria();
    doacoes = DoacoesEmMemoria(contas);
    service = DoacaoService(
      doacoes: doacoes,
      usuarios: contas,
      avisos: NotificacoesEmMemoria(contas, doacoes).central(relogio),
      relogio: relogio,
      fusoHorarioUtc: -3,
    );
    doador = await criarConta(TipoUsuario.doador, 'padaria@ex.com');
    outroDoador = await criarConta(TipoUsuario.doador, 'mercado@ex.com');
    ong = await criarConta(TipoUsuario.ong, 'ong@ex.com');
  });

  DadosNovaDoacao dados({DateTime? validade, DateTime? fim}) => DadosNovaDoacao(
    titulo: 'Pães do dia',
    categoria: CategoriaAlimento.padaria,
    quantidade: 30,
    unidade: Unidade.unidades,
    pesoKg: 6,
    conservacao: Conservacao.ambiente,
    validade: validade ?? DateTime.utc(2026, 9, 16),
    janelaInicio: agora,
    janelaFim: fim ?? agora.add(const Duration(hours: 4)),
    declaracaoAlimentosProprios: true,
  );

  Future<Doacao> publicar() async =>
      (await service.publicar(doador, dados())).doacao;

  Matcher conflito(String codigo) => throwsA(
    isA<ConflitoException>().having((e) => e.codigo, 'codigo', codigo),
  );

  group('publicar', () {
    test('RN10: só doador publica', () {
      expect(
        () => service.publicar(ong, dados()),
        throwsA(isA<SemPermissaoException>()),
      );
    });

    test('RN10: validade de ontem é recusada', () {
      expect(
        () => service.publicar(
          doador,
          dados(validade: DateTime.utc(2026, 9, 14)),
        ),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('sem localização, usa a do perfil do doador', () async {
      final resposta = await service.publicar(doador, dados());

      expect(resposta.doacao.latitude, -23.52);
      expect(resposta.doacao.status, StatusDoacao.disponivel);
      expect(resposta.ongsAvisadas, 1); // a ONG do teste fica no mesmo lugar
    });
  });

  group('editar', () {
    test('RN12: edita enquanto está disponível', () async {
      final doacao = await publicar();
      final novos = DadosNovaDoacao.fromJson({
        ...dados().toJson(),
        'titulo': 'Pães e bolos',
      });

      final editada = await service.editar(doador, doacao.id, novos);

      expect(editada.titulo, 'Pães e bolos');
    });

    test('RN12: reservada não pode ser editada', () async {
      final doacao = await publicar();
      doacoes.reservar(doacao.id, ong.id, agora);

      expect(
        () => service.editar(doador, doacao.id, dados()),
        conflito('DOACAO_NAO_EDITAVEL'),
      );
    });

    test('doação de outro doador parece não existir (404)', () async {
      final doacao = await publicar();

      expect(
        () => service.editar(outroDoador, doacao.id, dados()),
        throwsA(isA<NaoEncontradoException>()),
      );
    });
  });

  group('cancelar', () {
    test('RN12: disponível cancela sem motivo', () async {
      final doacao = await publicar();

      await service.cancelar(doador, doacao.id);

      expect((await doacoes.buscar(doacao.id))!.status, StatusDoacao.cancelada);
    });

    test('RN12: reservada exige motivo', () async {
      final doacao = await publicar();
      doacoes.reservar(doacao.id, ong.id, agora);

      expect(
        () => service.cancelar(doador, doacao.id),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('RN12: reservada com motivo cancela e não penaliza a ONG', () async {
      final doacao = await publicar();
      doacoes.reservar(doacao.id, ong.id, agora);

      await service.cancelar(doador, doacao.id, motivo: 'A geladeira quebrou');

      final reserva = doacoes.reservas.single;
      expect(reserva.status, StatusReserva.canceladaDoador);
      expect(reserva.motivo, 'A geladeira quebrou');
      final cancelada = (await doacoes.buscar(doacao.id))!;
      expect(cancelada.motivoCancelamento, 'A geladeira quebrou');
    });

    test('RN12: concluída ou já cancelada não cancela de novo', () async {
      final doacao = await publicar();
      await service.cancelar(doador, doacao.id);

      expect(
        () => service.cancelar(doador, doacao.id),
        conflito('DOACAO_NAO_CANCELAVEL'),
      );
    });
  });

  group('listar e expirar', () {
    test(
      'RN13: janela encerrada vira expirada e vai para o histórico',
      () async {
        final doacao = await publicar();
        relogio.avancar(const Duration(hours: 5)); // passou do fim (4 h)

        final ativas = await service.listarMinhas(
          doador,
          SituacaoDaLista.ativas,
        );
        final historico = await service.listarMinhas(
          doador,
          SituacaoDaLista.historico,
        );

        expect(ativas, isEmpty);
        expect(historico.single.id, doacao.id);
        expect(historico.single.status, StatusDoacao.expirada);
      },
    );

    test('cada doador vê só as próprias doações', () async {
      await publicar();

      expect(
        await service.listarMinhas(outroDoador, SituacaoDaLista.ativas),
        isEmpty,
      );
    });
  });

  group('detalhar', () {
    test('a ONG vê uma doação disponível, com os dados do doador', () async {
      final doacao = await publicar();

      final detalhe = await service.detalhar(ong, doacao.id);

      expect(detalhe.doador?.nomeOrganizacao, 'Org padaria@ex.com');
      expect(detalhe.reserva, isNull);
    });

    test('RN22: ONG bloqueada para a doação não a vê', () async {
      final doacao = await publicar();
      doacoes.bloqueios.add('${ong.id}-${doacao.id}');

      expect(
        () => service.detalhar(ong, doacao.id),
        throwsA(isA<NaoEncontradoException>()),
      );
    });

    test('reservada: o doador vê a ONG; outra ONG não vê a doação', () async {
      final doacao = await publicar();
      doacoes.reservar(doacao.id, ong.id, agora);
      final outraOng = await criarConta(TipoUsuario.ong, 'outra@ex.com');

      final doDoador = await service.detalhar(doador, doacao.id);
      expect(doDoador.ong?.nomeOrganizacao, 'Org ong@ex.com');
      expect((await service.detalhar(ong, doacao.id)).reserva, isNotNull);
      expect(
        () => service.detalhar(outraOng, doacao.id),
        throwsA(isA<NaoEncontradoException>()),
      );
    });
  });
}
