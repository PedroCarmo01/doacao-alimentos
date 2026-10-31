import 'package:shared_models/shared_models.dart';

import '../arquivos/armazenamento_de_fotos.dart';
import '../arquivos/conferencia_de_foto.dart';
import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import 'doacao_repository.dart';

/// Envio de fotos das doações (`POST /doacoes/{id}/fotos`, uma por vez).
///
/// Regras: até 3 por doação, 2 MB cada, só JPEG ou PNG, só o doador dono e
/// só enquanto a doação pode ser editada.
class FotoDoacaoService {
  FotoDoacaoService({
    required DoacaoRepository doacoes,
    required ArmazenamentoDeFotos armazenamento,
  }) : _doacoes = doacoes,
       _armazenamento = armazenamento;

  final DoacaoRepository _doacoes;
  final ArmazenamentoDeFotos _armazenamento;

  Future<Doacao> adicionar(
    UsuarioAutenticado usuario,
    int doacaoId,
    List<int> bytes,
  ) async {
    usuario.exigirTipo(TipoUsuario.doador);
    final doacao = await _doacoes.buscar(doacaoId);
    if (doacao == null || doacao.doadorId != usuario.id) {
      throw const NaoEncontradoException('Doação não encontrada.');
    }
    if (!doacao.podeSerEditada) {
      throw const ConflitoException(
        'DOACAO_NAO_EDITAVEL',
        'Só dá para mudar as fotos enquanto nenhuma ONG aceitou a doação.',
      );
    }
    if (doacao.fotos.length >= Doacao.maximoDeFotos) {
      throw const ConflitoException(
        'LIMITE_DE_FOTOS',
        'Cada doação pode ter no máximo ${Doacao.maximoDeFotos} fotos.',
      );
    }
    final formato = ConferenciaDeFoto.conferir(bytes);
    final arquivo = await _armazenamento.salvar(bytes, formato);
    await _doacoes.adicionarFoto(doacaoId, arquivo, doacao.fotos.length + 1);
    return (await _doacoes.buscar(doacaoId))!;
  }
}
