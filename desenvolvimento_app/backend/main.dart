import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/arquivos/armazenamento_de_fotos.dart';
import 'package:summit_backend/auth/usuario_repository_mysql.dart';
import 'package:summit_backend/chat/chat_repository_mysql.dart';
import 'package:summit_backend/chat/chat_service.dart';
import 'package:summit_backend/comunidade/comunidade_repository_mysql.dart';
import 'package:summit_backend/comunidade/comunidade_service.dart';
import 'package:summit_backend/core/config/env.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/senha_service.dart';
import 'package:summit_backend/core/seguranca/token_service.dart';
import 'package:summit_backend/doacoes/doacao_repository_mysql.dart';
import 'package:summit_backend/doacoes/doacao_service.dart';
import 'package:summit_backend/documentos/consulta_cnpj.dart';
import 'package:summit_backend/documentos/consulta_cnpj_brasil_api.dart';
import 'package:summit_backend/documentos/consulta_cnpj_fake.dart';
import 'package:summit_backend/documentos/documento_service.dart';
import 'package:summit_backend/documentos/reverificacao_job.dart';
import 'package:summit_backend/notificacoes/central_de_notificacoes.dart';
import 'package:summit_backend/notificacoes/enviador_de_push.dart';
import 'package:summit_backend/notificacoes/notificacao_repository_mysql.dart';
import 'package:summit_backend/perfil/perfil_repository_mysql.dart';
import 'package:summit_backend/reservas/confirmacao_service.dart';
import 'package:summit_backend/reservas/expiracao_job.dart';
import 'package:summit_backend/reservas/gerador_de_codigo.dart';
import 'package:summit_backend/reservas/penalidades.dart';
import 'package:summit_backend/reservas/reserva_repository_mysql.dart';
import 'package:summit_backend/reservas/reserva_service.dart';

// Recursos criados UMA vez, mesmo que o Dart Frog recarregue o código
// (hot reload) durante o desenvolvimento.
Database? _database;
ConsultaCnpj? _consultaCnpj;
ReverificacaoJob? _reverificacao;
ExpiracaoJob? _expiracao;

/// Ponto de entrada customizado do Dart Frog ("custom entrypoint").
///
/// O Dart Frog chama [run] ao iniciar o servidor. Aqui é a RAIZ DE COMPOSIÇÃO
/// do backend: criamos os objetos de infraestrutura e os disponibilizamos
/// para todas as rotas com `provider`. Nas rotas e middlewares, eles são
/// lidos com `context.read<Database>()`, `context.read<Env>()` etc.
///
/// Arquivo de FUNDAÇÃO: altere só em PR combinado com o grupo.
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  final env = Env.carregar();
  final database = _database ??= Database.conectar(env);
  const relogio = RelogioSistema();
  const senhas = SenhaService();
  final tokens = TokenService(
    segredo: env.jwtSegredo,
    validade: env.jwtValidade,
  );

  // POLIMORFISMO: o resto do backend só conhece a interface ConsultaCnpj.
  // CONSULTAR_BRASILAPI=false troca a consulta real por uma sem internet.
  final consultaCnpj = _consultaCnpj ??= env.consultarBrasilApi
      ? ConsultaCnpjBrasilApi()
      : ConsultaCnpjFake();

  // RN03: a cada 10 min, tenta de novo verificar os CNPJs "pendentes".
  _reverificacao ??= ReverificacaoJob(
    DocumentoService(
      consulta: consultaCnpj,
      perfis: PerfilRepositoryMysql(database),
    ),
  )..iniciar();

  // Notificações (etapa 5). POLIMORFISMO: para o push real (Firebase),
  // troque EnviadorPushDesligado() por EnviadorFcm(...). Só esta linha.
  const EnviadorDePush enviador = EnviadorPushDesligado();
  final chat = ChatRepositoryMysql(database);
  final avisos = CentralDeNotificacoes(
    notificacoes: NotificacaoRepositoryMysql(database),
    enviador: enviador,
    chat: chat,
    relogio: relogio,
    fusoHorarioUtc: env.fusoHorarioUtc,
  );

  // Doações e retiradas. Os serviços são criados aqui, uma vez, porque o
  // job de expiração usa os mesmos que as rotas.
  final reservas = ReservaRepositoryMysql(database);
  final doacoes = DoacaoRepositoryMysql(database);
  final usuarios = UsuarioRepositoryMysql(database);
  final doacaoService = DoacaoService(
    doacoes: doacoes,
    usuarios: usuarios,
    avisos: avisos,
    relogio: relogio,
    fusoHorarioUtc: env.fusoHorarioUtc,
  );
  final penalidades = Penalidades(
    reservas: reservas,
    usuarios: usuarios,
    doacoes: doacoes,
    avisos: avisos,
    regras: env.regrasDaRetirada,
  );
  final reservaService = ReservaService(
    reservas: reservas,
    doacoes: doacoes,
    usuarios: usuarios,
    penalidades: penalidades,
    avisos: avisos,
    regras: env.regrasDaRetirada,
    codigos: GeradorDeCodigoAleatorio(),
    relogio: relogio,
  );
  final confirmacaoService = ConfirmacaoService(
    reservas: reservas,
    doacoes: doacoes,
    penalidades: penalidades,
    avisos: avisos,
    relogio: relogio,
  );

  // RN29: a cada 30 s, expira as retiradas vencidas e as doações cujo
  // horário de retirada acabou (RN13), e lembra "faltam 10 minutos".
  _expiracao ??= ExpiracaoJob(reservas: reservaService, doacoes: doacaoService)
    ..iniciar();

  // Onde as fotos das doações ficam: uma pasta do servidor (fora do Git).
  final ArmazenamentoDeFotos fotos = ArmazenamentoEmPasta(env.pastaArquivos);

  final aplicacao = handler
      .use(provider<ArmazenamentoDeFotos>((_) => fotos))
      .use(provider<DoacaoService>((_) => doacaoService))
      .use(
        provider<ComunidadeService>(
          (_) => ComunidadeService(
            comunidade: ComunidadeRepositoryMysql(database),
            armazenamento: fotos,
            avisos: avisos,
            relogio: relogio,
            denunciasParaOcultar: env.denunciasParaOcultar,
          ),
        ),
      )
      .use(
        provider<ChatService>(
          (_) => ChatService(chat: chat, avisos: avisos, relogio: relogio),
        ),
      )
      .use(provider<ReservaService>((_) => reservaService))
      .use(provider<ConfirmacaoService>((_) => confirmacaoService))
      .use(provider<ConsultaCnpj>((_) => consultaCnpj))
      .use(provider<SenhaService>((_) => senhas))
      .use(provider<TokenService>((_) => tokens))
      .use(provider<Relogio>((_) => relogio))
      .use(provider<Database>((_) => database))
      .use(provider<Env>((_) => env));

  // Seguro por padrão: só o próprio computador (e o emulador Android, via
  // 10.0.2.2) acessam. Para testar em celular físico, ESCUTAR_NA_REDE=true.
  final endereco = env.escutarNaRede
      ? InternetAddress.anyIPv4
      : InternetAddress.loopbackIPv4;
  stdout.writeln(
    env.escutarNaRede
        ? 'API aceitando conexões da rede local na porta $port.'
        : 'API rodando em http://127.0.0.1:$port',
  );
  return serve(aplicacao, endereco, port);
}
