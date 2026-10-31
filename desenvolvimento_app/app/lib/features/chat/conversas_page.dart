import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../shared/widgets/estados.dart';
import '../../shared/widgets/foto_da_doacao.dart';
import 'conversas_view_model.dart';

/// T31 — Mensagens (aba): uma conversa por retirada, com a foto da doação,
/// o nome da outra pessoa, a última mensagem e as não lidas.
///
/// O [viewModel] vem da casca (ele também conta as não lidas da barra).
class ConversasPage extends StatelessWidget {
  const ConversasPage({super.key, required this.viewModel});

  final ConversasViewModel viewModel;

  Future<void> _abrir(BuildContext context, ResumoConversa conversa) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: conversa.reservaId,
    );
    viewModel.atualizar(); // as não lidas mudaram
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (!viewModel.carregou) {
            final erro = viewModel.erro;
            return erro == null
                ? const CarregandoWidget()
                : ErroWidget(mensagem: erro, onTentar: viewModel.carregar);
          }
          if (viewModel.conversas.isEmpty) {
            return const VazioWidget(
              icone: Icons.chat_bubble_outline,
              texto:
                  'Nenhuma conversa ainda.\nA conversa abre quando uma ONG '
                  'aceita uma doação.',
            );
          }
          return RefreshIndicator(
            onRefresh: viewModel.carregar,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                for (final conversa in viewModel.conversas)
                  _Linha(
                    conversa: conversa,
                    agora: viewModel.agora,
                    aoTocar: () => _abrir(context, conversa),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.conversa,
    required this.agora,
    required this.aoTocar,
  });

  final ResumoConversa conversa;
  final DateTime agora;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final naoLidas = conversa.naoLidas;
    final categoria = CategoriaAlimento.values
        .where((c) => c.name == conversa.categoria)
        .firstOrNull;
    final quando = conversa.ultimaEm;
    return ListTile(
      onTap: aoTocar,
      leading: FotoDaDoacao(
        caminho: conversa.fotoDoacao,
        categoria: categoria,
        tamanho: 48,
      ),
      title: Text(
        conversa.nomeOutro,
        style: TextStyle(
          fontWeight: naoLidas > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${conversa.tituloDoacao}'
        '${conversa.ultimaMensagem == null ? '' : '\n${conversa.ultimaMensagem}'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: conversa.ultimaMensagem != null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (quando != null)
            Text(
              Formatador.horaOuDia(quando, agora: agora),
              style: const TextStyle(fontSize: 12, color: AppColors.cinza),
            ),
          if (naoLidas > 0)
            Badge(label: Text('$naoLidas'))
          else if (conversa.somenteLeitura)
            const Icon(Icons.lock_outline, size: 16, color: AppColors.cinza),
        ],
      ),
    );
  }
}
