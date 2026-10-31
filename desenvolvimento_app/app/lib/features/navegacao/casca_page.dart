import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/dependencias.dart';
import '../../core/notificacoes/destino_da_notificacao.dart';
import '../../core/routing/app_routes.dart';
import '../../shared/widgets/barra_inferior.dart';
import '../../shared/widgets/faixa_de_retirada.dart';
import '../chat/conversas_page.dart';
import '../chat/conversas_view_model.dart';
import '../comunidade/comunidade_page.dart';
import '../doador/home_doador_page.dart';
import '../mapa/mapa_page.dart';
import '../ong/home_ong_page.dart';
import '../perfil/perfil_page.dart';
import 'faixa_de_retirada_view_model.dart';

/// "Casca" do app depois do login: a barra inferior de 5 itens e a aba
/// escolhida em cima dela (seção 2 da especificação).
///
/// - Doador: Início • Mensagens • **Doar** • Comunidade • Perfil.
///   O botão do meio ABRE o formulário de nova doação (não é uma aba).
/// - ONG: Início • Mensagens • **Mapa** • Comunidade • Perfil.
///   O botão do meio é a aba do mapa.
///
/// Em cima de tudo, a faixa laranja da retirada em andamento (etapa 4).
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

  late final FaixaDeRetiradaViewModel _faixa;

  /// A aba Mensagens e o número vermelho de não lidas usam o mesmo.
  late final ConversasViewModel _conversas;

  @override
  void initState() {
    super.initState();
    final d = widget.dependencias;
    _faixa = FaixaDeRetiradaViewModel(
      reservas: d.reservas,
      doacoes: d.doacoes,
      sessao: d.sessao,
      relogio: d.relogio,
    )..iniciar();
    _conversas = ConversasViewModel(chat: d.chat, relogio: d.relogio)
      ..iniciar();
    // Etapa 5: avisos enquanto a pessoa está logada (a casca só existe
    // depois do login e some ao sair).
    d.receptor.iniciar(aoTocar: _abrirNotificacao);
  }

  @override
  void dispose() {
    widget.dependencias.receptor.parar();
    _conversas.dispose();
    _faixa.dispose();
    super.dispose();
  }

  /// Tocar numa notificação abre a tela certa (seção 9).
  void _abrirNotificacao(Notificacao notificacao) {
    final destino = DestinoDaNotificacao.para(notificacao, ehOng: _ehOng);
    if (destino == null || !mounted) return;
    Navigator.pushNamed(context, destino.rota, arguments: destino.argumento);
    _faixa.atualizar();
  }

  /// Tocar na faixa: abre a retirada (ONG) ou a doação (doador).
  Future<void> _abrirDaFaixa() async {
    final unica = _faixa.retiradaUnica;
    final doacao = _faixa.doacaoACaminho;
    if (_ehOng) {
      await Navigator.pushNamed(
        context,
        unica == null ? AppRoutes.minhasReservas : AppRoutes.retirada,
        arguments: unica?.id,
      );
    } else if (doacao != null) {
      await Navigator.pushNamed(
        context,
        AppRoutes.detalheDoacaoDoador,
        arguments: doacao.id,
      );
    }
    _faixa.atualizar();
  }

  /// O `IndexedStack` mantém todas as abas vivas: ao trocar de aba, a
  /// pessoa não perde o que estava vendo.
  List<Widget> _criarAbas() {
    final d = widget.dependencias;
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
      ConversasPage(viewModel: _conversas),
      // Doador: o botão do meio abre outra tela; esta posição fica vazia.
      if (_ehOng)
        MapaPage(doacoes: d.doacoes, sessao: d.sessao)
      else
        const SizedBox.shrink(),
      ComunidadePage(comunidade: d.comunidade, sessao: d.sessao),
      PerfilPage(sessao: d.sessao, perfis: d.perfis),
    ];
  }

  List<ItemDaBarra> get _itens => [
    const ItemDaBarra(icone: Icons.home_outlined, rotulo: 'Início'),
    ItemDaBarra(
      icone: Icons.chat_bubble_outline,
      rotulo: 'Mensagens',
      contador: _conversas.totalNaoLidas,
    ),
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
    // Ao trocar de aba, confere se algo mudou.
    _faixa.atualizar();
    _conversas.atualizar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O conteúdo passa por trás do "salto" do botão central.
      extendBody: true,
      body: ListenableBuilder(
        listenable: _faixa,
        builder: (context, abas) {
          if (!_faixa.visivel) return abas!;
          return Column(
            children: [
              FaixaDeRetirada(texto: _faixa.texto, aoTocar: _abrirDaFaixa),
              // A faixa já ocupa o espaço da barra de status: as telas de
              // baixo não precisam desse espaço de novo.
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: abas!,
                ),
              ),
            ],
          );
        },
        // As abas são criadas fora do builder: o contador redesenha só a
        // faixa, não as telas.
        child: IndexedStack(index: _abaAtual, children: _criarAbas()),
      ),
      // A barra se redesenha quando muda o número de não lidas.
      bottomNavigationBar: ListenableBuilder(
        listenable: _conversas,
        builder: (context, _) => BarraInferior(
          itens: _itens,
          indiceAtual: _abaAtual,
          aoTocar: _aoTocar,
        ),
      ),
    );
  }
}
