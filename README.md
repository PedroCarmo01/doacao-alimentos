# Doação de Alimentos — conectando excedentes a quem precisa

> Projeto acadêmico de Engenharia de Software apresentado no **Summit**. Um aplicativo que conecta estabelecimentos com **excedente de alimentos** (mercados, feiras, sacolões, padarias) a **ONGs próximas**, combatendo a fome e o desperdício. Alinhado aos **ODS 2 (Fome Zero)** e **ODS 12 (Consumo e Produção Responsáveis)**.

**Primeira vez aqui? Comece por [`00_COMECE_AQUI`](00_COMECE_AQUI/README.md).**

<!-- TODO(grupo, trilha/22): acrescentar 3 ou 4 prints das telas principais aqui. -->

## Como funciona

1. O **doador** anuncia o excedente, com validade e janela de retirada (alimentos vencidos não são aceitos, e o doador declara que estão próprios para consumo).
2. As **ONGs próximas** veem a doação na lista e no mapa, e são avisadas quando surge uma nova.
3. A primeira ONG que **reservar** tem um **prazo** para buscar, com contador regressivo.
4. A retirada é **confirmada** pela ONG ou pelo doador. Se o prazo acabar, a reserva **expira sozinha** e a doação volta para as outras ONGs.

## Tecnologias

| Camada | Tecnologia | Por quê |
|---|---|---|
| App | **Flutter** (Dart), MVVM com `ChangeNotifier` | um código para Android e iOS; arquitetura orientada a objetos ([ADR-005](docs/adr/ADR-005-app-mvvm-changenotifier.md)) |
| Backend | **Dart Frog** (Dart) | mesma linguagem do app; rotas por arquivo ([ADR-002](docs/adr/ADR-002-backend-dart-frog.md)) |
| Banco | **MySQL 8.4 LTS** | relacional, com regras garantidas pelo banco ([ADR-003](docs/adr/ADR-003-mysql-84-nativo-docker-opcional.md)) |
| Compartilhado | pacote `shared_models` | modelos, contratos da API e validações iguais no app e no backend |
| Segurança | JWT + bcrypt + armazenamento seguro | [ADR-009](docs/adr/ADR-009-jwt-bcrypt-secure-storage.md) |
| Qualidade | testes automatizados + GitHub Actions | CI a cada Pull Request |

Todas as decisões: [docs/adr](docs/adr/README.md).

## Como rodar

Pré-requisitos e instalação passo a passo: [trilha/03](trilha/03-ambiente-windows-vscode.md). Resumo para quem já tem tudo instalado:

1. MySQL Workbench (como root): rodar `database/schema.sql` e `database/criar_usuario.sql`.
2. `cd desenvolvimento_app\backend` · `Copy-Item .env.example .env` · preencher `DB_SENHA` e `JWT_SEGREDO`.
3. VS Code → *Tasks: Run Task* → **Tudo: baixar dependências (pub get)**.
4. Tarefas **Backend: recriar dados de exemplo (seed)** e **Backend: iniciar (dart_frog dev)**.
5. *Run and Debug* → **App — API local (emulador)** → `F5`. (Sem backend: **App — dados fictícios**.)

### Usuários de teste

Senha de todos: `senha123`.

| E-mail | Perfil |
|---|---|
| `mercado@exemplo.com` | doador (Mercado Bom Preço) |
| `padaria@exemplo.com` | doador (Padaria Pão Quente) |
| `maosamigas@exemplo.com` | ONG (ONG Mãos Amigas) |
| `pratocheio@exemplo.com` | ONG (Instituto Prato Cheio) |
| `distante@exemplo.com` | ONG fora do raio (Associação Distante) |

## Estrutura

```text
00_COMECE_AQUI/        por onde começar, regras do grupo, guia de cada pessoa
trilha/                passo a passo do zero à entrega (com código e checklists)
docs/                  referência: requisitos, API, banco, arquitetura, ADRs
database/              scripts SQL (MySQL 8.4)
desenvolvimento_app/
├── shared_models/     modelos e validações (Dart puro)
├── backend/           API (Dart Frog)
└── app/               aplicativo (Flutter)
```

Detalhes: [docs/06 — Estrutura do projeto](docs/06-estrutura-projeto.md).

## Documentação

| Para... | Veja |
|---|---|
| começar | [00_COMECE_AQUI](00_COMECE_AQUI/README.md) |
| desenvolver (passo a passo) | [trilha](trilha/README.md) |
| consultar (API, banco, regras) | [docs](docs/00-indice.md) |
| contribuir (Git, PR) | [CONTRIBUTING.md](CONTRIBUTING.md) |

## Equipe

<!-- TODO(grupo): preencher com os nomes e usuários do GitHub. -->

| Integrante | GitHub | Responsabilidade |
|---|---|---|
| Pessoa 1 | @ | Autenticação (backend + app) |
| Pessoa 2 | @ | Doador (backend + app) |
| Pessoa 3 | @ | Reservas e expiração (backend) |
| Pessoa 4 | @ | Infraestrutura, proximidade e mapa |
| Pessoa 5 | @ | Telas da ONG (app) |

## Uso de inteligência artificial

<!-- TODO(grupo): conferir a política da disciplina e ajustar este texto (trilha/22, passo 3). -->

A estrutura inicial do repositório, parte da documentação e os exemplos de código da pasta `trilha/` foram produzidos com apoio de ferramentas de IA generativa e revisados pelo grupo. Cada integrante implementou, testou e é capaz de explicar o código da própria parte, conforme o histórico de commits e Pull Requests.
