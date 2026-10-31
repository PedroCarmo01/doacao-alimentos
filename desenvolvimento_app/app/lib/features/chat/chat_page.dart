import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/notificacoes/receptor_de_notificacoes.dart';
import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../data/chat/chat_repository.dart';
import '../../shared/widgets/estados.dart';
import 'chat_view_model.dart';

/// T30 — Chat da retirada: mensagens com horário e "✓ lida", mensagens do
/// sistema no meio, respostas rápidas e, depois da retirada, só leitura.
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.reservaId,
    required this.chat,
    required this.sessao,
    required this.receptor,
  });

  final int reservaId;
  final ChatRepository chat;
  final Sessao sessao;
  final ReceptorDeNotificacoes receptor;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatViewModel _viewModel;
  final _texto = TextEditingController();
  final _rolagem = ScrollController();
  int _quantasNaTela = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel(
      chat: widget.chat,
      sessao: widget.sessao,
      receptor: widget.receptor,
      reservaId: widget.reservaId,
    )..iniciar();
    _viewModel.addListener(_rolarSeChegouMensagem);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_rolarSeChegouMensagem);
    _viewModel.dispose();
    _texto.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  /// Mensagem nova: rola até o fim (depois do desenho da tela).
  void _rolarSeChegouMensagem() {
    final quantas = _viewModel.mensagens.length;
    if (quantas == _quantasNaTela) return;
    _quantasNaTela = quantas;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rolagem.hasClients) {
        _rolagem.jumpTo(_rolagem.position.maxScrollExtent);
      }
    });
  }

  Future<void> _enviar(String texto) async {
    final enviou = await _viewModel.enviar(texto);
    if (enviou) {
      _texto.clear();
    } else if (mounted && _viewModel.erro != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_viewModel.erro!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(_viewModel.titulo),
              if (_viewModel.subtitulo != null)
                Text(
                  _viewModel.subtitulo!,
                  style: const TextStyle(fontSize: 14),
                ),
            ],
          ),
        ),
        body: SafeArea(child: _corpo()),
      ),
    );
  }

  Widget _corpo() {
    if (!_viewModel.carregou) {
      final erro = _viewModel.erro;
      return erro == null
          ? const CarregandoWidget()
          : ErroWidget(mensagem: erro, onTentar: _viewModel.carregar);
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _rolagem,
            padding: const EdgeInsets.all(12),
            children: [
              for (final mensagem in _viewModel.mensagens)
                mensagem.ehDoSistema
                    ? _DoSistema(mensagem: mensagem)
                    : _Balao(
                        mensagem: mensagem,
                        minha: _viewModel.ehMinha(mensagem),
                        lida: _viewModel.foiLida(mensagem),
                      ),
            ],
          ),
        ),
        _viewModel.somenteLeitura ? const _SoLeitura() : _campoDeTexto(),
      ],
    );
  }

  Widget _campoDeTexto() {
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Respostas rápidas: um toque, sem digitar (T30).
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final resposta in _viewModel.respostasRapidas)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(resposta),
                        onPressed: _viewModel.ocupado
                            ? null
                            : () => _enviar(resposta),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('campo_mensagem'),
                    controller: _texto,
                    maxLength: Mensagem.tamanhoMaximo,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Escreva uma mensagem',
                      counterText: '',
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('botao_enviar'),
                  tooltip: 'Enviar',
                  icon: const Icon(Icons.send, color: AppColors.verde),
                  onPressed: _viewModel.ocupado
                      ? null
                      : () => _enviar(_texto.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Balão de uma mensagem: as minhas à direita (verde), as da outra pessoa
/// à esquerda.
class _Balao extends StatelessWidget {
  const _Balao({
    required this.mensagem,
    required this.minha,
    required this.lida,
  });

  final Mensagem mensagem;
  final bool minha;
  final bool lida;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: minha ? AppColors.verdeClaro : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(mensagem.texto, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              '${Formatador.hora(mensagem.criadoEm)}'
              '${minha && lida ? '  ✓ lida' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.cinza),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensagem do sistema, centralizada ("ONG X aceitou a doação • 14:10").
class _DoSistema extends StatelessWidget {
  const _DoSistema({required this.mensagem});

  final Mensagem mensagem;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      '${mensagem.texto} • ${Formatador.hora(mensagem.criadoEm)}',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.cinza,
        fontStyle: FontStyle.italic,
      ),
    ),
  );
}

/// RN31: no lugar do campo de texto.
class _SoLeitura extends StatelessWidget {
  const _SoLeitura();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      'A retirada terminou. A conversa fica disponível só para leitura '
      'por 7 dias.',
      key: Key('so_leitura'),
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.cinza),
    ),
  );
}
