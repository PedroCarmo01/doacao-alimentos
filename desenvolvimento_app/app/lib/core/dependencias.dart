import 'package:shared_models/shared_models.dart';

import '../data/auth/auth_repository.dart';
import '../data/doacoes/doacao_repository.dart';
import '../data/fake/banco_fake.dart';
import '../data/localizacao/localizacao_service.dart';
import '../data/reservas/reserva_repository.dart';
import '../data/sistema/sistema_repository.dart';
import 'api/api_client.dart';
import 'config/app_config.dart';
import 'sessao/armazenamento_token.dart';
import 'sessao/sessao.dart';

/// RAIZ DE COMPOSIÇÃO do app (docs/adr/ADR-006).
///
/// É o ÚNICO lugar que sabe quais classes CONCRETAS são usadas. Todo o resto
/// do app conhece só as interfaces (`AuthRepository`, `DoacaoRepository`...).
/// Trocar API por Fake é escolher outro construtor aqui.
///
/// Arquivo de FUNDAÇÃO: altere só em PR combinado com o grupo.
class Dependencias {
  Dependencias({
    required this.sessao,
    required this.auth,
    required this.doacoes,
    required this.reservas,
    required this.sistema,
    required this.localizacao,
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
    return Dependencias(
      sessao: Sessao(armazenamento),
      auth: AuthRepositoryApi(api, armazenamento),
      doacoes: DoacaoRepositoryApi(api),
      reservas: ReservaRepositoryApi(api),
      sistema: SistemaRepositoryApi(api),
      localizacao: const LocalizacaoServiceGps(),
      relogio: const RelogioSistema(),
      modoFake: false,
    );
  }

  /// Tudo em memória, sem backend (`--dart-define=USAR_FAKE=true`).
  factory Dependencias.fake({BancoFake? banco}) {
    final dados = banco ?? BancoFake();
    final armazenamento = ArmazenamentoTokenMemoria();
    return Dependencias(
      sessao: Sessao(armazenamento),
      auth: AuthRepositoryFake(dados, armazenamento),
      doacoes: DoacaoRepositoryFake(dados),
      reservas: ReservaRepositoryFake(dados),
      sistema: const SistemaRepositoryFake(),
      localizacao: const LocalizacaoServiceFake(),
      relogio: const RelogioSistema(),
      modoFake: true,
    );
  }

  final Sessao sessao;
  final AuthRepository auth;
  final DoacaoRepository doacoes;
  final ReservaRepository reservas;
  final SistemaRepository sistema;
  final LocalizacaoService localizacao;
  final Relogio relogio;
  final bool modoFake;
}
