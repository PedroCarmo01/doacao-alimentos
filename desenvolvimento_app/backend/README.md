# backend/ — API REST (Dart Frog + MySQL 8.4)

API da plataforma de doação de alimentos. Recebe requisições HTTP do app, aplica as regras de negócio e grava no MySQL.

- Passo a passo para iniciantes: [trilha/11 — Backend: fundamentos](../../trilha/11-backend-fundamentos.md)
- Contrato de cada endpoint: [docs/08 — API](../../docs/08-backend-apis.md)

## Estrutura

```text
backend/
├── main.dart                  FUNDAÇÃO: cria Env, Database, Relogio, TokenService (raiz de composição)
├── routes/                    endpoints: cada arquivo é uma rota (Dart Frog)
│   ├── _middleware.dart       FUNDAÇÃO: logger + CORS + tratamento de erros (vale para tudo)
│   ├── index.dart             FUNDAÇÃO: GET / (health check)
│   ├── auth/                  Pessoa 1  (trilha/12)
│   ├── doacoes/               Pessoa 2  (trilha/13)
│   ├── proximas/              Pessoa 4  (trilha/14)
│   └── reservas/              Pessoa 3  (trilha/15)
├── lib/
│   ├── core/                  FUNDAÇÃO (pronta; altere só em PR combinado)
│   │   ├── config/env.dart          variáveis do .env, validadas ao iniciar
│   │   ├── db/database.dart         pool MySQL, transações, ExecutorSql
│   │   ├── db/mapeador.dart         linha do banco → modelo do shared_models
│   │   ├── erros/app_exception.dart exceções com status HTTP (polimorfismo)
│   │   ├── http/requisicao.dart     lerJson(), parametroDecimal(), idDaRota()
│   │   ├── http/middlewares.dart    tratarErros(), cors()
│   │   ├── seguranca/               JWT, bcrypt, exigirAutenticacao(), UsuarioAutenticado
│   │   └── utils/datas.dart         datas Dart ↔ MySQL em UTC
│   ├── auth/                  Pessoa 1: UsuarioRepository, AuthService
│   ├── doacoes/               Pessoa 2: DoacaoRepository, DoacaoService
│   ├── proximidade/           Pessoa 4: ProximidadeRepository, ProximidadeService
│   └── reservas/              Pessoa 3: ReservaRepository, ReservaService, ExpiracaoJob
├── tool/
│   ├── seed.dart              recria os dados de exemplo (senha: senha123)
│   └── gerar_token.dart       gera um token de teste (antes do login existir)
├── test/                      testes automatizados (dart test)
├── api.http                   requisições prontas para a extensão REST Client
├── .env.example               modelo de configuração (copie para .env)
└── pubspec.yaml / pubspec.lock
```

> As pastas `lib/auth`, `lib/doacoes`, `lib/proximidade`, `lib/reservas` e as subpastas de `routes/` são criadas por cada pessoa, seguindo a trilha. Por isso ainda não existem no Sprint 0.

## Rodar pela primeira vez

Pré-requisitos: Dart (vem com o Flutter), Dart Frog CLI e MySQL 8.4 com o banco criado ([database/README.md](../../database/README.md)).

```powershell
cd desenvolvimento_app/backend
Copy-Item .env.example .env     # depois edite: DB_SENHA e JWT_SEGREDO
dart pub get
dart run tool/seed.dart          # dados de exemplo
dart_frog dev                    # API em http://127.0.0.1:8080
```

Teste no navegador, ou com a primeira requisição do `api.http`: `GET http://127.0.0.1:8080/` deve responder `{"status": "ok", "banco": "conectado", ...}`.

> Use `127.0.0.1` em vez de `localhost`: no Windows, `localhost` às vezes resolve para IPv6 (`::1`) e a conexão é recusada.

## Comandos do dia a dia

| Comando | Para quê |
|---|---|
| `dart_frog dev` | Sobe a API com recarga automática ao salvar |
| `dart test` | Roda os testes |
| `dart analyze` | Procura erros e más práticas |
| `dart format .` | Formata o código (o VS Code já faz ao salvar) |
| `dart run tool/seed.dart` | Recria os dados de exemplo |
| `dart run tool/gerar_token.dart 1 doador` | Token de teste para o usuário 1 |

## Regras de arquitetura (valem para todas as fatias)

1. **Rota fina**: a rota lê a requisição, chama o *Service* e devolve a resposta. Sem SQL e sem regra de negócio na rota.
2. **Service** concentra as regras e a autorização (tipo de usuário e "é dono?"). Não importa o Dart Frog, então pode ser testado sem servidor.
3. **Repository** só faz SQL, e sempre com parâmetros nomeados (`:id`). A interface fica em um arquivo e a implementação MySQL em outro.
4. **Erros** são exceções da `core/erros/app_exception.dart`; o middleware global as transforma em JSON com o status certo.
5. **Datas**: o horário vem do `Relogio` (nunca `NOW()` nem `DateTime.now()` nas regras) e é gravado em UTC com `Datas.paraSql()`.
6. **Dependências** chegam pelo construtor. A fatia monta os próprios objetos no `_middleware.dart` da sua pasta, sem editar o global.
