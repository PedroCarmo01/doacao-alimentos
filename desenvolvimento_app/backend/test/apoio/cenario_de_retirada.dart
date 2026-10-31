import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/doacoes/doacao_service.dart';
import 'package:summit_backend/reservas/confirmacao_service.dart';
import 'package:summit_backend/reservas/gerador_de_codigo.dart';
import 'package:summit_backend/reservas/penalidades.dart';
import 'package:summit_backend/reservas/reserva_service.dart';

import 'doacoes_em_memoria.dart';
import 'em_memoria.dart';
import 'notificacoes_em_memoria.dart';
import 'reservas_em_memoria.dart';

/// Monta tudo o que os testes da retirada precisam, sem MySQL: um doador,
/// duas ONGs, os serviços ligados aos repositórios em memória e um relógio
/// que os testes avançam. O código de retirada é sempre "4821".
class CenarioDeRetirada {
  CenarioDeRetirada._(this.agoraInicial)
    : relogio = RelogioFixo(agoraInicial),
      contas = ContasEmMemoria() {
    doacoes = DoacoesEmMemoria(contas);
    reservas = ReservasEmMemoria(doacoes, contas);
    notificacoes = NotificacoesEmMemoria(contas, doacoes);
    final avisos = notificacoes.central(relogio);
    final penalidades = Penalidades(
      reservas: reservas,
      usuarios: contas,
      doacoes: doacoes,
      avisos: avisos,
      regras: regras,
    );
    service = ReservaService(
      reservas: reservas,
      doacoes: doacoes,
      usuarios: contas,
      penalidades: penalidades,
      avisos: avisos,
      regras: regras,
      codigos: const GeradorDeCodigoFixo(codigo),
      relogio: relogio,
    );
    confirmacao = ConfirmacaoService(
      reservas: reservas,
      doacoes: doacoes,
      penalidades: penalidades,
      avisos: avisos,
      relogio: relogio,
    );
    doacaoService = DoacaoService(
      doacoes: doacoes,
      usuarios: contas,
      avisos: avisos,
      relogio: relogio,
      fusoHorarioUtc: -3,
    );
  }

  static const codigo = '4821';
  static const regras = RegrasDaRetirada(); // 60 min, 5 min, 3 em 30 dias...

  final DateTime agoraInicial;
  final RelogioFixo relogio;
  final ContasEmMemoria contas;
  late final DoacoesEmMemoria doacoes;
  late final ReservasEmMemoria reservas;
  late final NotificacoesEmMemoria notificacoes;
  late final ReservaService service;
  late final ConfirmacaoService confirmacao;
  late final DoacaoService doacaoService;

  late UsuarioAutenticado doador;
  late UsuarioAutenticado ongA;
  late UsuarioAutenticado ongB;

  static Future<CenarioDeRetirada> criar() async {
    final cenario = CenarioDeRetirada._(DateTime.utc(2026, 9, 15, 15));
    cenario.doador = await cenario._conta(TipoUsuario.doador, 'doador@ex.com');
    cenario.ongA = await cenario._conta(TipoUsuario.ong, 'a@ex.com');
    cenario.ongB = await cenario._conta(TipoUsuario.ong, 'b@ex.com');
    return cenario;
  }

  DateTime get agora => relogio.agora();

  void avancar(Duration tempo) => relogio.avancar(tempo);

  /// Uma doação disponível do doador, com o horário de retirada aberto
  /// por [janela] a partir de agora.
  Future<Doacao> publicar({Duration janela = const Duration(hours: 3)}) async {
    final resposta = await doacaoService.publicar(
      doador,
      DadosNovaDoacao(
        titulo: 'Pães do dia',
        categoria: CategoriaAlimento.padaria,
        quantidade: 30,
        unidade: Unidade.unidades,
        pesoKg: 6,
        conservacao: Conservacao.ambiente,
        validade: DateTime.utc(2026, 9, 16),
        janelaInicio: agora,
        janelaFim: agora.add(janela),
        declaracaoAlimentosProprios: true,
      ),
    );
    return resposta.doacao;
  }

  Future<Doacao> doacao(int id) async => (await doacoes.buscar(id))!;

  Future<UsuarioAutenticado> _conta(TipoUsuario tipo, String email) async {
    final conta = await contas.criar(
      DadosCadastro(
        tipo: tipo,
        tipoEstabelecimento: tipo == TipoUsuario.doador
            ? TipoEstabelecimento.padaria
            : null,
        nome: 'Responsável',
        email: email,
        senha: 'senha123',
        nomeOrganizacao: 'Org $email',
        documento: '${contas.registros.length}',
        latitude: -23.52,
        longitude: -46.18,
        aceitouTermos: true,
      ),
      senhaHash: 'x',
      criadoEm: agoraInicial,
      verificacao: Verificacao.verificada,
    );
    return UsuarioAutenticado(id: conta.usuario.id, tipo: tipo);
  }
}
