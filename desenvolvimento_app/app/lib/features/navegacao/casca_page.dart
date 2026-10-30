import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../core/routing/app_routes.dart';
import '../../shared/widgets/barra_inferior.dart';
import '../../shared/widgets/em_construcao.dart';
import '../doador/home_doador_page.dart';
import '../mapa/mapa_page.dart';
import '../ong/home_ong_page.dart';
import '../perfil/perfil_page.dart';

/// "Casca" do app depois do login: a barra inferior de 5 itens e a aba
/// escolhida em cima dela (seção 2 da especificação).
///
/// - Doador: Início • Mensagens • **Doar** • Comunidade • Perfil.
///   O botão do meio ABRE o formulário de nova doação (não é uma aba).
/// - ONG: Início • Mensagens • **Mapa** • Comunidade • Perfil.
///   O botão do meio é a aba do mapa.
class CascaPage extends StatefulWidget {
  const CascaPage({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  State<CascaPage> createState() => _CascaPageState();
}

class _CascaPageState extends State<CascaPage> {
  /// Qual aba está aberta. Estado só da TELA, por isso `setState`.
  int _abaAtual = 0;

  late final bool _ehOng = widget.dependencias.sessao.usuario?.ehOng ?? false;

  /// Muda quando o doador publica uma doação. Como ela entra na `key` da
  /// tela de início, mudar o número RECRIA a tela, que busca a lista de novo.
  int _versaoDoInicio = 0;

  /// O `IndexedStack` mantém todas as abas vivas: ao trocar de aba, a
  /// pessoa não perde o que estava vendo.
  List<Widget> _criarAbas() {
    final d = widget.dependencias;
    const mensagens = EmConstrucao(
      titulo: 'Mensagens',
      etapa: 6,
      descricao: 'Conversas com o doador ou a ONG de cada retirada.',
    );
    const comunidade = EmConstrucao(
      titulo: 'Comunidade',
      etapa: 7,
      descricao: 'O impacto das doações e as publicações de todos.',
    );
    return [
      if (_ehOng)
        HomeOngPage(
          doacoes: d.doacoes,
          perfis: d.perfis,
          sessao: d.sessao,
          relogio: d.relogio,
        )
      else
        HomeDoadorPage(
          key: ValueKey(_versaoDoInicio),
          doacoes: d.doacoes,
          sessao: d.sessao,
          relogio: d.relogio,
        ),
      mensagens,
      // Doador: o botão do meio abre outra tela; esta posição fica vazia.
      if (_ehOng)
        MapaPage(doacoes: d.doacoes, sessao: d.sessao)
      else
        const SizedBox.shrink(),
      comunidade,
      PerfilPage(sessao: d.sessao),
    ];
  }

  List<ItemDaBarra> get _itens => [
    const ItemDaBarra(icone: Icons.home_outlined, rotulo: 'Início'),
    // O contador de não lidas entra na etapa 6 (chat).
    const ItemDaBarra(icone: Icons.chat_bubble_outline, rotulo: 'Mensagens'),
    _ehOng
        ? const ItemDaBarra(icone: Icons.place, rotulo: 'Mapa')
        : const ItemDaBarra(icone: Icons.add, rotulo: 'Doar'),
    const ItemDaBarra(icone: Icons.groups_outlined, rotulo: 'Comunidade'),
    const ItemDaBarra(icone: Icons.person_outline, rotulo: 'Perfil'),
  ];

  Future<void> _aoTocar(int indice) async {
    if (indice == BarraInferior.indiceCentral && !_ehOng) {
      final publicou = await Navigator.pushNamed(context, AppRoutes.novaDoacao);
      if (publicou == true && mounted) {
        setState(() {
          _versaoDoInicio++;
          _abaAtual = 0; // mostra a doação nova em "Minhas doações"
        });
      }
      return;
    }
    setState(() => _abaAtual = indice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O conteúdo passa por trás do "salto" do botão central.
      extendBody: true,
      body: IndexedStack(index: _abaAtual, children: _criarAbas()),
      bottomNavigationBar: BarraInferior(
        itens: _itens,
        indiceAtual: _abaAtual,
        aoTocar: _aoTocar,
      ),
    );
  }
}
