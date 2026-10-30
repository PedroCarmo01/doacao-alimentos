import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/perfil/perfil_service.dart';
import 'package:test/test.dart';

import '../apoio/em_memoria.dart';

/// `PUT /perfil`: editar dados, busca ativa e raio.
void main() {
  late ContasEmMemoria contas;
  late PerfilService service;

  setUp(() {
    contas = ContasEmMemoria();
    service = PerfilService(perfis: contas, usuarios: contas);
  });

  Future<UsuarioAutenticado> criarConta(TipoUsuario tipo) async {
    final conta = await contas.criar(
      DadosCadastro(
        tipo: tipo,
        tipoEstabelecimento: tipo == TipoUsuario.doador
            ? TipoEstabelecimento.padaria
            : null,
        nome: 'Responsável',
        email: '${tipo.name}@exemplo.com',
        senha: 'senha123',
        nomeOrganizacao: 'Organização',
        documento: CnpjsDeTeste.associacao,
        telefone: '(11) 99999-0000',
        latitude: -23.5,
        longitude: -46.1,
        aceitouTermos: true,
      ),
      senhaHash: 'x',
      criadoEm: DateTime.utc(2026),
      verificacao: Verificacao.verificada,
    );
    return UsuarioAutenticado(id: conta.usuario.id, tipo: tipo);
  }

  DadosPerfil edicao({double raioKm = 5, bool buscaAtiva = false}) =>
      DadosPerfil(
        nome: ' Nova Responsável ',
        nomeOrganizacao: 'ONG Renomeada',
        telefone: '(11) 98888-7777',
        latitude: -23.52,
        longitude: -46.18,
        familiasAtendidas: 80,
        transporte: Transporte.van,
        buscaAtiva: buscaAtiva,
        raioKm: raioKm,
      );

  test('ONG muda busca ativa e raio', () async {
    final ong = await criarConta(TipoUsuario.ong);

    final conta = await service.atualizar(ong, edicao());

    expect(conta.usuario.nome, 'Nova Responsável');
    expect(conta.perfil.nomeOrganizacao, 'ONG Renomeada');
    expect(conta.perfil.buscaAtiva, isFalse);
    expect(conta.perfil.raioKm, 5);
    expect(conta.perfil.transporte, Transporte.van);
  });

  test('raio fora das opções (2, 5, 10, 20 km) é recusado', () async {
    final ong = await criarConta(TipoUsuario.ong);

    expect(
      () => service.atualizar(ong, edicao(raioKm: 7)),
      throwsA(isA<ValidacaoException>()),
    );
  });

  test('RN01: doador não guarda campos que são só de ONG', () async {
    final doador = await criarConta(TipoUsuario.doador);

    final conta = await service.atualizar(doador, edicao());

    expect(conta.perfil.transporte, isNull);
    expect(conta.perfil.familiasAtendidas, isNull);
    expect(conta.perfil.buscaAtiva, isTrue);
    expect(conta.perfil.raioKm, 10);
  });
}
