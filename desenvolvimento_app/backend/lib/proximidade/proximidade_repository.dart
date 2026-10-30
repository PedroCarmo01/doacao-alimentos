import 'package:shared_models/shared_models.dart';

import 'area_de_busca.dart';

/// CONTRATO: doações disponíveis dentro de uma área (filtro "grosso").
abstract interface class ProximidadeRepository {
  /// Disponíveis, com a janela de retirada ainda aberta em [agora], dentro
  /// da [area] e que NÃO estão bloqueadas para a ONG [ongId] (RN22).
  Future<List<Doacao>> disponiveisNaArea(
    AreaDeBusca area, {
    required int ongId,
    required DateTime agora,
  });
}
