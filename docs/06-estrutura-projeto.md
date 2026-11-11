# 06 — Estrutura do projeto

Mapa de pastas e arquivos. **F** = fundação (pronta; só mude em PR combinado com o grupo). **Pn** = criado pela pessoa n na sua fatia.

## Raiz

```text
Summit/
├── 00_COMECE_AQUI/          por onde começar, regras do grupo e guia de cada pessoa
├── trilha/                  PASSO A PASSO do zero à entrega (o caminho principal)
├── docs/                    REFERÊNCIA (requisitos, API, banco, decisões)
│   └── adr/                 registros de decisão de arquitetura
├── database/                scripts SQL (MySQL 8.4)
├── desenvolvimento_app/     TODO O CÓDIGO
│   ├── shared_models/
│   ├── backend/
│   └── app/
├── .github/                 CI, modelos de issue/PR, CODEOWNERS
├── .vscode/                 tarefas, perfis de execução, extensões recomendadas
├── README.md · CONTRIBUTING.md · CHANGELOG.md
└── .gitignore · .gitattributes
```

## `desenvolvimento_app/shared_models/` (F, com testes)

```text
lib/
├── shared_models.dart            exporta tudo (import 'package:shared_models/shared_models.dart')
└── src/
    ├── usuario.dart              TipoUsuario, Usuario
    ├── perfil.dart               Perfil, Conta (usuário + perfil)
    ├── doacao.dart               CategoriaAlimento, StatusDoacao, Doacao (podeSerReservada, podeSerCancelada)
    ├── reserva.dart              StatusReserva, Reserva (tempoRestante, estaVencida)
    ├── detalhe_doacao.dart       DetalheDoacao (doação + reserva ativa)
    ├── contratos/                corpos e respostas da API
    │   ├── autenticacao.dart     DadosCadastro, DadosLogin, RespostaAutenticacao
    │   ├── doacoes.dart          DadosNovaDoacao
    │   └── reservas.dart         DadosReserva
    ├── validacao/                ValidadorUsuario, ValidadorDoacao (app e backend)
    ├── geo/geo.dart              Coordenadas, Geo.distanciaKm (Haversine)
    ├── tempo/relogio.dart        Relogio, RelogioSistema, RelogioFixo, Calendario
    └── util/json.dart            LeitorJson (interno)
test/                             modelos, validações, geo e tempo
```

## `desenvolvimento_app/backend/`

```text
main.dart                 F  raiz de composição; P3 liga o job de expiração (trilha/15)
pubspec.yaml              F
.env.example              F  copie para .env (nunca vai para o Git)
api.http                  F  requisições prontas para o REST Client
lib/
├── core/                 F
│   ├── config/env.dart           lê e valida o .env
│   ├── db/database.dart          pool MySQL, transacao(), ExecutorSql
│   ├── db/mapeador.dart          linha do banco → modelo
│   ├── erros/app_exception.dart  exceções que viram HTTP
│   ├── http/middlewares.dart     tratarErros, cors
│   ├── http/requisicao.dart      lerJson, parametroDecimal, idDaRota
│   ├── seguranca/                TokenService, SenhaService, autenticar, exigirAutenticacao, UsuarioAutenticado
│   └── utils/datas.dart          Datas.paraSql / deSql
├── auth/                 P1  usuario_repository(.dart|_mysql.dart), auth_service.dart
├── doacoes/              P2  doacao_repository(.dart|_mysql.dart), doacao_service.dart
├── proximidade/          P4  area_de_busca.dart, proximidade_repository(.dart|_mysql.dart), proximidade_service.dart
└── reservas/             P3  reserva_repository(.dart|_mysql.dart), reserva_service.dart, expiracao_job.dart
routes/
├── _middleware.dart      F  log → CORS → erros
├── index.dart            F  GET / (health check)
├── auth/                 P1  _middleware, cadastro, login, me
├── doacoes/              P2  _middleware, index (GET/POST), [id] (GET/DELETE)
├── proximas/             P4  _middleware, index (GET)
└── reservas/             P3  _middleware, index (GET/POST), [id]/index (DELETE), [id]/retirada (POST)
tool/
├── seed.dart             F  dados de exemplo (senha123)
└── gerar_token.dart      F  token de teste sem login
test/
├── core/                 F
└── auth/ doacoes/ proximidade/ reservas/   uma pasta por fatia
```

## `desenvolvimento_app/app/`

```text
lib/
├── main.dart · app.dart                       F
├── core/                                      F
│   ├── config/app_config.dart     API_URL, USAR_FAKE, nomeApp, intervaloAtualizacao, identificadorApp
│   ├── dependencias.dart          Dependencias.api() / .fake()
│   ├── api/                       ApiClient, ApiException
│   ├── erros/erro_amigavel.dart   ErroAmigavel, ErroDeRegra
│   ├── mvvm/view_model_base.dart  ViewModelBase (ocupado, erro, executar)
│   ├── routing/                   AppRoutes, AppRouter
│   ├── sessao/                    Sessao, ArmazenamentoToken
│   ├── theme/app_theme.dart       AppColors, AppTheme
│   └── utils/formatador.dart      Formatador
├── data/                                      F
│   ├── auth/ doacoes/ reservas/ sistema/      interface + Api + Fake
│   ├── localizacao/localizacao_service.dart   GPS + Fake
│   └── fake/banco_fake.dart                   "backend de mentira"
├── shared/widgets/                            F  PrimaryButton, AppTextField, DoacaoCard, ContadorRegressivo, estados
└── features/
    ├── auth/presentation/         P1  escolha_perfil (F, exemplo), login, cadastro
    ├── doador/presentation/       P2  home_doador, nova_doacao, detalhe_doacao_doador
    ├── ong/presentation/          P5  home_ong, detalhe_doacao_ong, minhas_reservas
    └── mapa/presentation/         P4  mapa
test/
├── core/ data/ features/auth/     F  exemplos de teste
└── features/<area>/               cada pessoa
android/                           gerado no Sprint 0 (flutter create)
```

## Convenções de nomes de arquivo

| Tipo | Nome |
|---|---|
| Tela | `algo_page.dart` → `class AlgoPage` |
| ViewModel | `algo_view_model.dart` → `class AlgoViewModel extends ViewModelBase` |
| Interface de repositório | `algo_repository.dart` → `abstract interface class AlgoRepository` |
| Implementação | `AlgoRepositoryApi`, `AlgoRepositoryFake`, `AlgoRepositoryMysql` |
| Service | `algo_service.dart` → `class AlgoService` |
| Teste | mesmo caminho de `lib/`, em `test/`, terminando em `_test.dart` |

Mais em [15 — Padrões](15-padroes.md).
