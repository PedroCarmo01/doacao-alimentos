import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/arquivos/armazenamento_de_fotos.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/doacoes/foto_doacao_service.dart';
import 'package:test/test.dart';

import '../apoio/doacoes_em_memoria.dart';
import '../apoio/em_memoria.dart';

/// Envio de fotos: até 3, 2 MB, só JPEG/PNG, só o doador dono.
void main() {
  final agora = DateTime.utc(2026, 9, 15, 12);
  // Os primeiros bytes de um JPEG e de um PNG de verdade.
  final jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3];
  final png = [0x89, 0x50, 0x4E, 0x47, 1, 2, 3];
  const doador = UsuarioAutenticado(id: 1, tipo: TipoUsuario.doador);

  late DoacoesEmMemoria doacoes;
  late FotosEmMemoria fotos;
  late FotoDoacaoService service;
  late int doacaoId;

  setUp(() async {
    doacoes = DoacoesEmMemoria(ContasEmMemoria());
    fotos = FotosEmMemoria();
    service = FotoDoacaoService(doacoes: doacoes, armazenamento: fotos);
    final doacao = await doacoes.criar(
      DadosNovaDoacao(
        titulo: 'Pães',
        categoria: CategoriaAlimento.padaria,
        quantidade: 1,
        unidade: Unidade.caixas,
        pesoKg: 1,
        conservacao: Conservacao.ambiente,
        validade: agora,
        janelaInicio: agora,
        janelaFim: agora.add(const Duration(hours: 2)),
        latitude: 0,
        longitude: 0,
        declaracaoAlimentosProprios: true,
      ),
      doadorId: doador.id,
      criadoEm: agora,
    );
    doacaoId = doacao.id;
  });

  test('aceita JPEG e PNG, na ordem em que chegam', () async {
    await service.adicionar(doador, doacaoId, jpeg);
    final doacao = await service.adicionar(doador, doacaoId, png);

    expect(doacao.fotos, hasLength(2));
    expect(doacao.fotos.first, endsWith('.jpg'));
    expect(doacao.fotos.last, endsWith('.png'));
  });

  test('reconhece extensões de foto em maiúsculas', () {
    expect(FormatoDeFoto.doNome('imagem.JPG'), FormatoDeFoto.jpg);
    expect(FormatoDeFoto.doNome('imagem.PNG'), FormatoDeFoto.png);
  });

  test('recusa arquivo que não é foto (pelos bytes, não pelo nome)', () {
    expect(
      () => service.adicionar(doador, doacaoId, 'texto'.codeUnits),
      throwsA(isA<ValidacaoException>()),
    );
  });

  test('recusa foto com mais de 2 MB', () {
    final grande = [...jpeg, ...List.filled(2 * 1024 * 1024, 0)];

    expect(
      () => service.adicionar(doador, doacaoId, grande),
      throwsA(isA<ValidacaoException>()),
    );
  });

  test('no máximo 3 fotos por doação', () async {
    for (var i = 0; i < 3; i++) {
      await service.adicionar(doador, doacaoId, jpeg);
    }

    expect(
      () => service.adicionar(doador, doacaoId, jpeg),
      throwsA(
        isA<ConflitoException>().having(
          (e) => e.codigo,
          'codigo',
          'LIMITE_DE_FOTOS',
        ),
      ),
    );
  });

  test('outro doador não envia foto para a doação', () {
    const intruso = UsuarioAutenticado(id: 99, tipo: TipoUsuario.doador);

    expect(
      () => service.adicionar(intruso, doacaoId, jpeg),
      throwsA(isA<NaoEncontradoException>()),
    );
  });

  test('o nome salvo só aceita o formato gerado (sem "../")', () {
    expect(ArmazenamentoEmPasta.formatoDoNome.hasMatch('../.env'), isFalse);
    expect(
      ArmazenamentoEmPasta.formatoDoNome.hasMatch('${'a' * 32}.jpg'),
      isTrue,
    );
  });
}
