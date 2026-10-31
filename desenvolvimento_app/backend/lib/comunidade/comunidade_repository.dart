import 'package:shared_models/shared_models.dart';

/// CONTRATO das tabelas da Comunidade: `publicacoes`, `fotos_publicacao`,
/// `apoios` e `denuncias` (RN40–RN42).
abstract interface class ComunidadeRepository {
  /// O painel de impacto de todos (T40).
  Future<Impacto> impacto();

  /// Feed: as não ocultas com id menor que [antesDe] (0 = as mais novas),
  /// da mais nova para a mais antiga, no máximo [limite]. [leitorId] diz
  /// se cada uma já foi apoiada por quem está lendo.
  Future<List<Publicacao>> feed(
    int leitorId, {
    required int antesDe,
    required int limite,
  });

  /// Uma publicação (mesmo oculta), vista por [leitorId].
  Future<Publicacao?> buscar(int publicacaoId, int leitorId);

  Future<int> criar(int autorId, DadosPublicacao dados, DateTime agora);

  Future<void> adicionarFoto(int publicacaoId, String arquivo, int ordem);

  /// RN41: `false` se a conta já tinha apoiado (a chave composta impede
  /// o segundo apoio).
  Future<bool> apoiar(int publicacaoId, int usuarioId, DateTime agora);

  Future<void> desfazerApoio(int publicacaoId, int usuarioId);

  /// RN42: `false` se a conta já tinha denunciado.
  Future<bool> denunciar(
    int publicacaoId,
    int usuarioId,
    MotivoDenuncia motivo,
    DateTime agora,
  );

  /// RN42: quantas contas diferentes denunciaram.
  Future<int> denuncias(int publicacaoId);

  Future<void> ocultar(int publicacaoId);

  /// RN42: a publicação foi escondida por denúncias?
  Future<bool> estaOculta(int publicacaoId);

  /// RN40: a doação está concluída e o usuário participou dela (como o
  /// doador ou como a ONG que retirou)?
  Future<bool> participouDaDoacaoConcluida(int usuarioId, int doacaoId);
}
