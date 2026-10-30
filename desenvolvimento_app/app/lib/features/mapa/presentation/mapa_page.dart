import 'package:flutter/material.dart';

import '../../../core/sessao/sessao.dart';
import '../../../data/doacoes/doacao_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Mapa de doações próximas — provisória.
///
/// Provisória: a etapa indicada no EmConstrucao (05-PLANO-DE-CONSTRUCAO.md)
/// troca o conteúdo desta tela.
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class MapaPage extends StatelessWidget {
  const MapaPage({super.key, required this.doacoes, required this.sessao});

  final DoacaoRepository doacoes;
  final Sessao sessao;

  @override
  Widget build(BuildContext context) => const EmConstrucao(
    titulo: 'Mapa de doações',
    etapa: 3,
    descricao: 'Mapa com as doações dentro do seu raio de busca.',
  );
}
