# 23 — Análise Técnica do Projeto

Revisão completa de todos os arquivos do repositório (código, banco, documentação e organização da equipe), feita antes do início do desenvolvimento. O objetivo é corrigir agora o que custaria caro depois e registrar **por que** cada decisão foi tomada.

> Contexto considerado: equipe de **5 pessoas**, **4º semestre de Engenharia de Software**, conhecem lógica e alguma linguagem (Java/C#/Python/JS) mas **nunca usaram Dart/Flutter, Docker nem trabalharam juntos no GitHub**. Entrega **via GitHub**, seguindo **Programação Orientada a Objetos**, codando no **VS Code** (Windows). O tema foi conferido com o resumo aprovado na inscrição do Summit.

---

## 1. Resumo executivo

- Foram encontrados **32 problemas**: 2 críticos (impediam o sistema de funcionar), 10 de severidade alta, 14 médios e 6 baixos.
- Os dois críticos estavam no **backend**: as respostas não seguiam o formato JSON que o app espera, e as variáveis do `.env` nunca eram carregadas.
- Quatro tecnologias saíram e três entraram, sempre com justificativa registrada em ADR (ver seção 4).
- **Docker deixou de ser obrigatório.** Ele não resolve nenhum problema real deste projeto e aumenta muito a barreira de entrada (seção 5).
- O repositório passou a seguir a estratégia **walking skeleton + fatias verticais por pessoa**. Cada integrante tem trabalho próprio, que gera histórico individual no GitHub, e ninguém precisa editar o mesmo arquivo que o colega (seção 6).

---

## 2. Escala de severidade

| Severidade | Significado |
|---|---|
| **Crítica** | O sistema não funciona ponta a ponta |
| **Alta** | Vai travar a equipe ou causar retrabalho grande |
| **Média** | Causa bugs, confusão ou dívida técnica |
| **Baixa** | Ajuste de qualidade ou clareza |

---

## 3. Achados

### 3.1 Backend e banco de dados

| ID | Sev. | Achado | Impacto | Ação tomada |
|---|---|---|---|---|
| A01 | Crítica | O backend devolvia as linhas do banco "cruas" (`doador_id`, `janela_inicio`, números como texto), mas o app espera JSON em camelCase com tipos (`doadorId`, `int`, `double`) | Nenhuma tela conseguiria ler os dados | Criada a camada `Mapeador` no backend: linha do banco → modelo do `shared_models` → `toJson()` |
| A02 | Crítica | `Env` lia só `Platform.environment`; o `dart_frog dev` **não carrega** o arquivo `.env` | Backend sem senha do banco e sem segredo JWT | Pacote `dotenv` + classe `Env` que valida as variáveis obrigatórias ([ADR-012](adr/ADR-012-configuracao-dotenv-dart-define.md)) |
| A03 | Alta | Conexão MySQL com `secure: false`. No MySQL 8.4 o login padrão (`caching_sha2_password`) exige conexão segura | Erro de autenticação ao conectar | Pool com TLS, que já é o padrão do driver ([ADR-004](adr/ADR-004-driver-mysql-pool-tls.md)) |
| A04 | Alta | Documentação recomendava MySQL 8.0, que **saiu de suporte em abril/2026** | Versão sem correções de segurança | MySQL **8.4 LTS** ([ADR-003](adr/ADR-003-mysql-84-nativo-docker-opcional.md)) |
| A05 | Alta | `seed.sql` usava um hash bcrypt fictício | Impossível logar com os usuários de exemplo | Seed passou a ser `backend/tool/seed.dart`, que gera hashes reais |
| A06 | Média | Uma única conexão global, sem reconexão | Após horas parado, o MySQL derruba a conexão e tudo falha | `MySQLConnectionPool` (reconecta sob demanda) |
| A07 | Média | Datas sem fuso definido (`NOW()` do servidor x `DateTime` do celular) | Contador de reserva e expiração com horários errados | Tudo em **UTC** + relógio injetável ([ADR-010](adr/ADR-010-datas-utc-relogio.md)) |
| A08 | Alta | Rotas de exemplo importavam `../lib/...` | Não compila em Dart Frog | Imports via `package:summit_backend/...` |
| A09 | Média | `Dockerfile` do backend não incluía `shared_models` no contexto de build | `docker build` falharia | Removido; o deploy opcional usa o Dockerfile que o próprio `dart_frog build` gera ([apêndice A](../trilha/apendice-a-docker-opcional.md)) |
| A10 | Alta | O job de expiração não tinha ponto de inicialização | Reservas nunca expirariam | `main.dart` (entrypoint customizado do Dart Frog) inicializa recursos uma vez |
| A11 | Média | Dois ids diferentes para a mesma pessoa (`doadores.id` x `usuarios.id`); o job chegava a notificar o "usuário 0" | Bugs de autorização e de notificação | Tabela única `perfis` com **chave primária compartilhada** (`usuario_id`): o id do usuário é o id usado em todo lugar |
| A12 | Média | A regra "uma reserva ativa por doação" dependia só do código | Um erro no código permitiria duas ONGs com a mesma doação | Coluna gerada + `UNIQUE` no banco garante a regra mesmo se o código falhar |
| A26 | Média | Respostas sem `charset`; o pacote `http` decodifica como latin1 | Acentos quebrados ("DoaÃ§Ã£o") | `utf8.decode(resposta.bodyBytes)` no `ApiClient` |
| A27 | Média | `GET /doacoes` tinha dois comportamentos (doador e ONG) com donos diferentes | Duas pessoas editando o mesmo arquivo | Endpoint separado `GET /proximas` (dono: Pessoa 4) |
| A28 | Baixa | Formato de erro misturava inglês (`error/code/message`) | Inconsistência | Padrão único: `{"erro": {"codigo", "mensagem"}}` |

### 3.2 App (Flutter)

| ID | Sev. | Achado | Impacto | Ação tomada |
|---|---|---|---|---|
| A17 | Média | Riverpod: a API mudou na versão 3 (`StateNotifier` foi para "legacy"), e o estilo de providers globais é pouco orientado a objetos | Tutoriais inconsistentes; foge da exigência de POO | MVVM com `ChangeNotifier` do próprio Flutter ([ADR-005](adr/ADR-005-app-mvvm-changenotifier.md)) |
| A18 | Média | WebSocket obrigatório no MVP (registro de conexões, reconexão, autenticação no canal) | Muita complexidade para iniciantes | Atualização periódica no MVP; WebSocket opcional ([ADR-008](adr/ADR-008-polling-no-mvp.md)) |
| A21 | Baixa | O app exibia "Summit" como nome do produto, mas Summit é o **evento** | Identidade errada na apresentação | Nome em constante única `AppConfig.nomeApp` |
| A23 | Média | Dados falsos (mock) escritos dentro das telas com `setState` | Mistura UI e dados; vira retrabalho | Repositórios **Fake** (polimorfismo) e modo `USAR_FAKE=true` ([ADR-011](adr/ADR-011-walking-skeleton-fatias-fakes.md)) |
| A25 | Alta | Android 9+ bloqueia HTTP sem TLS e isso não estava documentado | O app não conecta na API local | Configuração do `AndroidManifest.xml` na [trilha 10](../trilha/10-sprint-0-esqueleto-funcional.md) |
| A29 | Baixa | Pacote `dio` usado só para interceptar o token | Dependência e conceito a mais | Pacote oficial `http` ([ADR-007](adr/ADR-007-pacote-http.md)) |

### 3.3 Requisitos (comparados com o resumo aprovado)

| ID | Sev. | Achado | Ação tomada |
|---|---|---|---|
| A22 | Média | O resumo aprovado diz que a plataforma **não se destina a produtos vencidos ou impróprios**, e isso não estava nos requisitos | Novos requisitos: validade ≥ hoje e **declaração obrigatória** do doador de que os alimentos estão próprios para consumo |
| A30 | Baixa | O resumo fala em "consultar oportunidades, demonstrar interesse e acompanhar até a retirada"; a documentação prometia notificação push | Linguagem alinhada: "aviso dentro do app" no MVP; push real fica como evolução futura |

### 3.4 Processo, GitHub e equipe

| ID | Sev. | Achado | Impacto | Ação tomada |
|---|---|---|---|---|
| A13 | Alta | Arquivos compartilhados (roteador, `_middleware` global, `main`, `pubspec`) seriam editados por todos | Conflitos de merge constantes para quem nunca resolveu um | Esses arquivos já vêm **prontos** no Sprint 0; cada pasta de rotas tem o próprio `_middleware`; `CODEOWNERS` define revisores |
| A14 | Alta | `pubspec.lock` estava no `.gitignore` | Cada máquina com versões diferentes de pacotes | O lock passa a ser versionado (recomendação oficial do Dart para aplicativos) |
| A15 | Baixa | `.metadata` do Flutter ignorado | Ferramentas do Flutter perdem informação do projeto | Versionado |
| A16 | Alta | Sem integração contínua (CI) | A `main` pode quebrar sem ninguém perceber | GitHub Actions: formatação, análise e testes a cada Pull Request |
| A19 | Média | Docker obrigatório (WSL2, virtualização, RAM disputando com o emulador) | Primeira semana perdida instalando | Docker opcional (seção 5) |
| A20 | Média | Documentação fragmentada: 5 pontos de entrada, informação repetida e divergente (4 x 5 pessoas, caminhos antigos) | Ninguém sabe qual versão seguir | **Trilha única** (passo a passo) + `docs/` como referência + ADRs |
| A24 | Média | Nenhum teste automatizado nas regras de negócio | Regressões silenciosas | Testes em cada fatia + CI |
| A31 | Alta | Se o commit inicial já tivesse todo o código pronto, o GitHub mostraria um único autor | O professor não veria a contribuição de cada um | Walking skeleton: a base vem pronta e **cada pessoa implementa a própria fatia** em branch e PR |
| A32 | Baixa | Uso de IA na geração da base | Questão de integridade acadêmica | Verifiquem a política da disciplina; se necessário, declarem no README |

---

## 4. Tecnologias: o que ficou, saiu, entrou

| Situação | Tecnologia | Justificativa |
|---|---|---|
| Mantida | **Dart + Flutter** | Requisito da disciplina |
| Mantida | **Dart Frog** (backend) | Backend em Dart, rotas por arquivo (fácil de dividir). Hoje mantido pela comunidade em `dart-frog-dev` ([ADR-002](adr/ADR-002-backend-dart-frog.md)) |
| Mantida | **MySQL** (agora 8.4 LTS) | Escolha do grupo; 8.0 saiu de suporte |
| Mantida | **mysql_client**, **dart_jsonwebtoken**, **bcrypt** | Driver com pool e TLS; JWT e hash de senha padrão de mercado |
| Mantida | **flutter_secure_storage**, **geolocator**, **flutter_map** + **latlong2** | Token protegido, GPS e mapa sem chave paga (OpenStreetMap) |
| Removida | **Riverpod** | Substituído por `ChangeNotifier` (SDK do Flutter) |
| Removida | **dio** | Substituído pelo `http` oficial |
| Removida | **intl** | Só formatava datas numéricas; um formatador de 20 linhas resolve |
| Removida | **dart_frog_web_socket** / **web_socket_channel** | WebSocket passou a ser opcional (apêndice B) |
| Removida | **mocktail** | Fakes escritos à mão ensinam polimorfismo e dispensam outra API |
| Adicionada | **dotenv** (backend) | Carregar o `.env` (problema A02) |
| Adicionada | **http** (app) | Cliente HTTP oficial do time do Dart |
| Adicionada | **GitHub Actions** | CI gratuita para repositório do GitHub |
| Opcional | **Docker** | Ver seção 5 |
| Ferramenta | **REST Client** (extensão do VS Code) | Testar a API com um arquivo `api.http`, sem instalar Postman |

---

## 5. O Docker é realmente necessário?

| Critério | Análise |
|---|---|
| O que o Docker faria aqui | Subir o MySQL igual em todas as máquinas |
| O que realmente garante o banco igual | Os **scripts SQL versionados no Git** (`database/`), não o Docker |
| O banco é compartilhado entre a equipe? | Não. Cada um usa o próprio banco local |
| Custo no Windows | WSL2, virtualização na BIOS e cerca de 2 GB de RAM, competindo com o emulador Android |
| Experiência da equipe | Nenhuma com Docker; seria mais uma tecnologia a aprender na primeira semana |
| O professor exige? | Não. A entrega é pelo GitHub |
| Onde ainda ajuda | Máquinas onde o MySQL nativo não instala, ou deploy opcional |

**Conclusão:** o Docker **não é necessário**. O caminho padrão é **MySQL 8.4 LTS instalado nativamente + MySQL Workbench**. O `docker-compose.yml` foi mantido em `database/` como **alternativa opcional** ([apêndice A](../trilha/apendice-a-docker-opcional.md)).

---

## 6. Estratégia de desenvolvimento adotada

1. **Sprint 0 — walking skeleton** (esqueleto que anda): o app abre, navega entre todas as telas (por enquanto "em construção"), chama a API e a API responde consultando o banco. Isso prova que a arquitetura está ligada de ponta a ponta antes de qualquer funcionalidade.
2. **Contratos definidos antes**: modelos (`shared_models`), formato da API (`docs/08`), interfaces dos repositórios e assinaturas das telas já existem. Cada pessoa trabalha contra o contrato, sem esperar o colega.
3. **Fatias verticais por pessoa**: cada funcionalidade vai do banco à tela. Quem implementa é dono dos arquivos da fatia, então não há duas pessoas no mesmo arquivo.
4. **Modo Fake**: com `USAR_FAKE=true` o app roda com repositórios em memória. Quem faz tela não precisa esperar o backend.
5. **Ferramentas que destravam o paralelismo**: `tool/seed.dart` (dados de exemplo) e `tool/gerar_token.dart` (token de teste antes do login existir).

---

## 7. O que mudou no repositório

| Tipo | Itens |
|---|---|
| Novo | `00_COMECE_AQUI/` (ponto de partida, regras e guia de cada pessoa), `trilha/` (passo a passo do zero à entrega), `docs/adr/`, `docs/23-analise-tecnica.md`, `.github/` (CI, templates, CODEOWNERS), `.vscode/`, `.gitattributes`, `CONTRIBUTING.md`, `CHANGELOG.md`, `backend/main.dart`, `backend/tool/`, `backend/api.http`, camada `data/` do app com interfaces + implementações API e Fake |
| Reescrito | `shared_models`, fundação do backend, fundação do app, `database/schema.sql`, documentos de `docs/`, READMEs |
| Removido | Riverpod e providers, `ws_event.dart`, `Dockerfile` do backend, `seed.sql` (substituído pelo seed em Dart), `.env.example` e `docker-compose.yml` da raiz (movidos), `docs/frontend-guia/` (substituído pela trilha), `equipe/`, `orientacao_grupo/` e `SCAFFOLD.md` (substituídos por `00_COMECE_AQUI/`) |

---

## 8. Riscos que continuam (e como mitigar)

| Risco | Mitigação |
|---|---|
| A base foi escrita sem compilar (a máquina usada não tinha Flutter/Dart) | O Sprint 0 inclui rodar `dart analyze`, `flutter analyze` e os testes; os erros esperados são pequenos (import, versão de pacote) |
| Versões de pacotes mudarem | `pubspec.lock` versionado; atualizar só em PR combinado com o grupo |
| Dart Frog ser mantido pela comunidade | Ele é uma camada fina sobre o `shelf` (oficial do Dart); a lógica fica nos *services*, que não dependem do framework |
| Política de uso dos tiles do OpenStreetMap | Uso baixo (demonstração) e atribuição visível no mapa |
| HTTP sem TLS em desenvolvimento | Só na rede local; em produção, HTTPS ([docs/19](19-deploy.md)) |

---

## 9. Próximos passos

Comece por [`00_COMECE_AQUI`](../00_COMECE_AQUI/README.md) e siga a [trilha](../trilha/README.md) a partir da etapa 01. O Sprint 0 está na [etapa 10](../trilha/10-sprint-0-esqueleto-funcional.md).
