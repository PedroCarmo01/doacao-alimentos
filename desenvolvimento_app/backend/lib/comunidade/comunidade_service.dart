import 'package:shared_models/shared_models.dart';

import '../arquivos/armazenamento_de_fotos.dart';
import '../arquivos/conferencia_de_foto.dart';
import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import '../notificacoes/central_de_notificacoes.dart';
import 'comunidade_repository.dart';

/// A Comunidade (T40, T41): painel de impacto, feed, publicar, fotos,
/// apoiar (RN41) e denunciar (RN42).
class ComunidadeService {
  ComunidadeService({
    required ComunidadeRepository comunidade,
    required ArmazenamentoDeFotos armazenamento,
    required CentralDeNotificacoes avisos,
    required Relogio relogio,
    this.denunciasParaOcultar = 3,
  }) : _comunidade = comunidade,
       _armazenamento = armazenamento,
       _avisos = avisos,
       _relogio = relogio;

  final ComunidadeRepository _comunidade;
  final ArmazenamentoDeFotos _armazenamento;
  final CentralDeNotificacoes _avisos;
  final Relogio _relogio;

  /// RN42: com tantas denúncias de contas diferentes, a publicação some
  /// (DENUNCIAS_PARA_OCULTAR no `.env`).
  final int denunciasParaOcultar;

  /// Publicações por página do feed.
  static const porPagina = 20;

  static const _naoEncontrada = NaoEncontradoException(
    'Publicação não encontrada.',
  );

  /// `GET /comunidade/impacto`
  Future<Impacto> impacto() => _comunidade.impacto();

  /// `GET /comunidade/publicacoes?antesDe=` — 20 por vez, sem as ocultas.
  Future<List<Publicacao>> feed(UsuarioAutenticado usuario, int antesDe) =>
      _comunidade.feed(usuario.id, antesDe: antesDe, limite: porPagina);

  /// `POST /comunidade/publicacoes` — RN40: qualquer conta publica; texto
  /// obrigatório. A doação ligada precisa estar concluída e ter a
  /// participação de quem publica.
  Future<Publicacao> publicar(
    UsuarioAutenticado usuario,
    DadosPublicacao dados,
  ) async {
    final erros = dados.validar();
    if (erros.isNotEmpty) {
      throw ValidacaoException(erros.first, detalhes: erros);
    }
    final doacaoId = dados.doacaoId;
    if (doacaoId != null &&
        !await _comunidade.participouDaDoacaoConcluida(usuario.id, doacaoId)) {
      throw const ValidacaoException(
        'Só dá para ligar a publicação a uma doação concluída da qual você '
        'participou.',
      );
    }
    final id = await _comunidade.criar(usuario.id, dados, _relogio.agora());
    return (await _comunidade.buscar(id, usuario.id))!;
  }

  /// `POST /comunidade/publicacoes/{id}/fotos` — RN40: até 3, só o autor.
  Future<Publicacao> adicionarFoto(
    UsuarioAutenticado usuario,
    int publicacaoId,
    List<int> bytes,
  ) async {
    final publicacao = await _comunidade.buscar(publicacaoId, usuario.id);
    if (publicacao == null || publicacao.autorId != usuario.id) {
      throw _naoEncontrada;
    }
    if (publicacao.fotos.length >= Publicacao.maximoDeFotos) {
      throw const ConflitoException(
        'LIMITE_DE_FOTOS',
        'Cada publicação pode ter no máximo ${Publicacao.maximoDeFotos} fotos.',
      );
    }
    final formato = ConferenciaDeFoto.conferir(bytes);
    final arquivo = await _armazenamento.salvar(bytes, formato);
    await _comunidade.adicionarFoto(
      publicacaoId,
      arquivo,
      publicacao.fotos.length + 1,
    );
    return (await _comunidade.buscar(publicacaoId, usuario.id))!;
  }

  /// `POST /comunidade/publicacoes/{id}/apoio` — RN41: cada conta apoia
  /// uma vez (apoiar de novo não soma). O autor é avisado.
  Future<Publicacao> apoiar(UsuarioAutenticado usuario, int id) async {
    final publicacao = await _visivel(usuario, id);
    final novo = await _comunidade.apoiar(id, usuario.id, _relogio.agora());
    if (novo && publicacao.autorId != usuario.id) {
      await _avisos.apoioNovo(publicacao);
    }
    return (await _comunidade.buscar(id, usuario.id))!;
  }

  /// `DELETE /comunidade/publicacoes/{id}/apoio` — desfazer o apoio.
  Future<Publicacao> desfazerApoio(UsuarioAutenticado usuario, int id) async {
    await _visivel(usuario, id);
    await _comunidade.desfazerApoio(id, usuario.id);
    return (await _comunidade.buscar(id, usuario.id))!;
  }

  /// `POST /comunidade/publicacoes/{id}/denuncia` — RN42: uma por conta;
  /// com [denunciasParaOcultar] contas diferentes, a publicação fica
  /// oculta até alguém revisar.
  Future<void> denunciar(
    UsuarioAutenticado usuario,
    int id,
    MotivoDenuncia motivo,
  ) async {
    final publicacao = await _visivel(usuario, id);
    if (publicacao.autorId == usuario.id) {
      throw const ValidacaoException(
        'Você não pode denunciar a sua própria publicação.',
      );
    }
    await _comunidade.denunciar(id, usuario.id, motivo, _relogio.agora());
    if (await _comunidade.denuncias(id) >= denunciasParaOcultar) {
      await _comunidade.ocultar(id);
    }
  }

  /// A publicação, se existe e não está oculta (oculta = "não encontrada").
  Future<Publicacao> _visivel(UsuarioAutenticado usuario, int id) async {
    final publicacao = await _comunidade.buscar(id, usuario.id);
    if (publicacao == null || await _comunidade.estaOculta(id)) {
      throw _naoEncontrada;
    }
    return publicacao;
  }
}
