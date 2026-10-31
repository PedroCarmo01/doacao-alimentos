import 'dart:async';

import 'package:shared_models/shared_models.dart';

import '../../core/mvvm/view_model_base.dart';
import '../../core/notificacoes/receptor_de_notificacoes.dart';
import '../../core/sessao/sessao.dart';
import '../../data/chat/chat_repository.dart';

/// ViewModel do chat da retirada (T30).
///
/// Com a conversa aberta, busca as mensagens novas a cada 4 s e avisa o
/// receptor para NÃO apitar notificação desta conversa (ela já está na
/// tela).
class ChatViewModel extends ViewModelBase {
  ChatViewModel({
    required ChatRepository chat,
    required Sessao sessao,
    required ReceptorDeNotificacoes receptor,
    required this.reservaId,
  }) : _chat = chat,
       _sessao = sessao,
       _receptor = receptor;

  final ChatRepository _chat;
  final Sessao _sessao;
  final ReceptorDeNotificacoes _receptor;
  final int reservaId;

  static const intervaloDeConsulta = Duration(seconds: 4);

  /// Respostas rápidas (T30): um toque, sem digitar. Diferentes para quem
  /// vai buscar e para quem entrega.
  static const respostasDaOng = [
    'Estou a caminho',
    'Cheguei',
    'Vou atrasar 10 min',
  ];
  static const respostasDoDoador = [
    'Pode entrar pelo portão lateral',
    'Estou esperando',
    'Já separei a doação',
  ];

  final List<Mensagem> _mensagens = [];
  ResumoConversa? _conversa;
  bool _somenteLeitura = false;
  bool _carregou = false;
  int _lidasAte = 0;
  Timer? _consulta;

  List<Mensagem> get mensagens => List.unmodifiable(_mensagens);
  bool get carregou => _carregou;

  /// RN31: a retirada terminou; dá para ler, não para escrever.
  bool get somenteLeitura => _somenteLeitura;

  /// Título da tela: a doação e com quem é a conversa.
  String get titulo => _conversa?.nomeOutro ?? 'Conversa';
  String? get subtitulo => _conversa?.tituloDoacao;

  List<String> get respostasRapidas =>
      (_sessao.usuario?.ehOng ?? false) ? respostasDaOng : respostasDoDoador;

  bool ehMinha(Mensagem mensagem) => mensagem.autorId == _sessao.usuario?.id;

  /// "✓ lida": a outra pessoa já abriu a conversa depois desta mensagem.
  bool foiLida(Mensagem mensagem) =>
      ehMinha(mensagem) && mensagem.id <= _lidasAte;

  int get _ultimoId => _mensagens.isEmpty ? 0 : _mensagens.last.id;

  /// Abre a conversa: a tela chama uma vez, no `initState`.
  void iniciar() {
    _receptor.conversaAberta(reservaId);
    _consulta ??= Timer.periodic(intervaloDeConsulta, (_) => atualizar());
    carregar();
  }

  Future<bool> carregar() => executar(() async {
    final conversas = await _chat.conversas();
    _conversa = conversas.where((c) => c.reservaId == reservaId).firstOrNull;
    await _buscarNovas();
    _carregou = true;
  });

  /// Consulta "em silêncio" a cada 4 s.
  Future<void> atualizar() async {
    if (ocupado || !_carregou) return;
    try {
      await _buscarNovas();
      notificar();
    } catch (_) {
      // Sem internet por um instante: a próxima consulta resolve.
    }
  }

  /// Envia [texto] (digitado ou uma resposta rápida).
  Future<bool> enviar(String texto) async {
    final erro = Mensagem.validar(texto);
    if (erro != null) {
      definirErro(erro);
      return false;
    }
    return executar(() async {
      await _chat.enviar(reservaId, texto.trim());
      await _buscarNovas(); // traz a minha e qualquer outra que chegou
    });
  }

  Future<void> _buscarNovas() async {
    final resposta = await _chat.mensagens(reservaId, depoisDe: _ultimoId);
    _mensagens.addAll(resposta.mensagens);
    _somenteLeitura = resposta.somenteLeitura;
    _lidasAte = resposta.lidasAte;
    final chegouDoOutro = resposta.mensagens.any(
      (m) => !m.ehDoSistema && !ehMinha(m),
    );
    // Abrir a conversa = ler: a outra pessoa vê "✓ lida".
    if (chegouDoOutro) await _chat.marcarLidas(reservaId);
  }

  @override
  void dispose() {
    _receptor.conversaAberta(null);
    _consulta?.cancel();
    super.dispose();
  }
}
