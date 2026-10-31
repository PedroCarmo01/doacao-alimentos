import 'package:shared_models/shared_models.dart';

import '../data/auth/auth_repository.dart';
import '../data/documentos/documento_repository.dart';
import '../data/doacoes/doacao_repository.dart';
import '../data/fake/banco_fake.dart';
import '../data/fotos/seletor_de_fotos.dart';
import '../data/localizacao/cep_repository.dart';
import '../data/localizacao/localizacao_service.dart';
import '../data/notificacoes/notificacao_repository.dart';
import '../data/perfil/perfil_repository.dart';
import '../data/reservas/reserva_repository.dart';
import '../data/sistema/sistema_repository.dart';
import 'api/api_client.dart';
import 'config/app_config.dart';
import 'notificacoes/mostrador_de_notificacoes.dart';
import 'notificacoes/receptor_de_notificacoes.dart';
import 'preferencias/preferencias.dart';
import 'sessao/armazenamento_token.dart';
import 'sessao/sessao.dart';

/// RAIZ DE COMPOSIÇÃO do app (docs/adr/ADR-006).
///
/// É o ÚNICO lugar que sabe quais classes CONCRETAS são usadas. Todo o resto
/// do app conhece só as interfaces (`AuthRepository`, `DoacaoRepository`...).
/// Trocar API por Fake é escolher outro construtor aqui.
class Dependencias {
  Dependencias({
    required this.sessao,
    required this.preferencias,
    required this.auth,
    required this.documentos,
    required this.perfis,
    required this.doacoes,
    required this.reservas,
    required this.sistema,
    required this.localizacao,
    required this.cep,
    required this.seletorDeFotos,
    required this.mostrador,
    required this.receptor,
    required this.relogio,
    required this.modoFake,
  });

  /// App de verdade: conversa com o backend em [AppConfig.urlApi].
  factory Dependencias.api() {
    final armazenamento = ArmazenamentoTokenSeguro();
    final api = ApiClient(
      urlBase: AppConfig.urlApi,
      armazenamentoToken: armazenamento,
    );
    const relogio = RelogioSistema();
    final mostrador = MostradorAndroid();
    return Dependencias(
      sessao: Sessao(armazenamento),
      preferencias: PreferenciasDoAparelho(),
      auth: AuthRepositoryApi(api, armazenamento),
      documentos: DocumentoRepositoryApi(api),
      perfis: PerfilRepositoryApi(api),
      doacoes: DoacaoRepositoryApi(api),
      reservas: ReservaRepositoryApi(api),
      sistema: SistemaRepositoryApi(api),
      localizacao: const LocalizacaoServiceGps(),
      cep: CepRepositoryBrasilApi(),
      seletorDeFotos: SeletorDeFotosDoAparelho(),
      mostrador: mostrador,
      // POLIMORFISMO: para o push real (Firebase), troque esta linha por
      // `ReceptorPush(...)`. Nenhuma tela muda (seção 9 da especificação).
      receptor: ReceptorPorConsulta(
        notificacoes: NotificacaoRepositoryApi(api),
        mostrador: mostrador,
        relogio: relogio,
      ),
      relogio: relogio,
      modoFake: false,
    );
  }

  /// Tudo em memória, sem backend (`--dart-define=USAR_FAKE=true`).
  /// [seletorDeFotos] e [mostrador]: no celular, o modo Fake usa a câmera
  /// e as notificações de verdade; nos testes, passe as versões de teste.
  factory Dependencias.fake({
    BancoFake? banco,
    SeletorDeFotos? seletorDeFotos,
    MostradorDeNotificacoes? mostrador,
  }) {
    final dados = banco ?? BancoFake();
    final armazenamento = ArmazenamentoTokenMemoria();
    final avisos = mostrador ?? MostradorAndroid();
    return Dependencias(
      sessao: Sessao(armazenamento),
      preferencias: PreferenciasMemoria(),
      auth: AuthRepositoryFake(dados, armazenamento),
      documentos: DocumentoRepositoryFake(dados),
      perfis: PerfilRepositoryFake(dados),
      doacoes: DoacaoRepositoryFake(dados),
      reservas: ReservaRepositoryFake(dados),
      sistema: const SistemaRepositoryFake(),
      localizacao: const LocalizacaoServiceFake(),
      cep: const CepRepositoryFake(),
      seletorDeFotos: seletorDeFotos ?? SeletorDeFotosDoAparelho(),
      mostrador: avisos,
      receptor: ReceptorPorConsulta(
        notificacoes: NotificacaoRepositoryFake(dados),
        mostrador: avisos,
        relogio: const RelogioSistema(),
      ),
      relogio: const RelogioSistema(),
      modoFake: true,
    );
  }

  final Sessao sessao;
  final Preferencias preferencias;
  final AuthRepository auth;
  final DocumentoRepository documentos;
  final PerfilRepository perfis;
  final DoacaoRepository doacoes;
  final ReservaRepository reservas;
  final SistemaRepository sistema;
  final LocalizacaoService localizacao;
  final CepRepository cep;
  final SeletorDeFotos seletorDeFotos;

  /// Mostra os avisos na barra do Android (e pede a permissão).
  final MostradorDeNotificacoes mostrador;

  /// Como os avisos chegam: hoje por consulta a cada 15 s.
  final ReceptorDeNotificacoes receptor;
  final Relogio relogio;
  final bool modoFake;
}
