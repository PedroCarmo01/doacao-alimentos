import 'package:shared_models/shared_models.dart';

/// CONTRATO de acesso às doações e às suas fotos.
///
/// O `DoacaoService` depende desta interface, não do MySQL: nos testes usamos
/// uma versão em memória.
abstract interface class DoacaoRepository {
  /// Grava uma doação nova (status `disponivel`). [dados] já vem com a
  /// localização e o endereço completos.
  Future<Doacao> criar(
    DadosNovaDoacao dados, {
    required int doadorId,
    required DateTime criadoEm,
  });

  /// Troca os dados de uma doação (só usada enquanto está disponível).
  Future<Doacao> atualizar(int doacaoId, DadosNovaDoacao dados);

  /// A doação com fotos, nome do doador e, se reservada, nome da ONG e
  /// prazo. `null` se não existir.
  Future<Doacao?> buscar(int doacaoId);

  /// Doações do doador, da mais nova para a mais antiga (T10).
  Future<List<Doacao>> doDoador(int doadorId, SituacaoDaLista situacao);

  /// A retirada em andamento da doação, se houver.
  Future<Reserva?> reservaAtiva(int doacaoId);

  /// Dados resumidos de uma organização (doador ou ONG).
  Future<ResumoOrganizacao?> resumo(int usuarioId);

  /// RN22: a ONG está bloqueada para esta doação?
  Future<bool> ongBloqueada(int ongId, int doacaoId);

  /// RN12: cancela a doação. Se houver retirada em andamento, ela vira
  /// `canceladaDoador` com o mesmo [motivo] (sem contar desistência).
  Future<void> cancelar(
    int doacaoId, {
    required String? motivo,
    required DateTime agora,
  });

  /// RN13: doações disponíveis cujo horário de retirada já acabou viram
  /// `expirada`. Devolve quantas mudaram.
  Future<int> expirarJanelasEncerradas(DateTime agora);

  /// Liga uma foto (já salva no armazenamento) à doação, na [ordem] dada.
  Future<void> adicionarFoto(int doacaoId, String arquivo, int ordem);
}
