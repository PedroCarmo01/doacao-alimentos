# COMECE AQUI

Bem-vindos! Este é o **ponto de partida** do projeto. Leia esta página inteira antes de abrir qualquer outra pasta: ela diz **o que é o projeto**, **o que ler e em que ordem** e **o que pode ignorar por enquanto**.

> Escrito para 5 estudantes do 4º semestre que conhecem lógica e alguma linguagem, mas nunca usaram Dart, Flutter, Dart Frog, MySQL Workbench nem trabalharam juntos no GitHub. Está tudo bem não saber nada disso ainda: o material ensina do zero, um passo de cada vez.

## 1. O projeto em 1 minuto

Um **aplicativo de celular** que funciona como um **"iFood da doação"**:

1. Um **mercado** anuncia: "tenho 5 caixas de frutas, retirada até as 18h".
2. As **ONGs próximas** veem a doação no app (e são avisadas quando surge uma nova).
3. A primeira ONG que **reservar** tem um **prazo** (ex.: 2 horas) para buscar.
4. Buscou? A doação é **concluída**. O prazo acabou? A reserva **expira sozinha** e a doação volta para as outras ONGs.

Ligado aos **ODS 2 (Fome Zero)** e **12 (Consumo e Produção Responsáveis)**. Alimentos vencidos ou impróprios **não** são aceitos.

| Parte | O que é | Tecnologia |
|---|---|---|
| App | o que o usuário usa no celular | Flutter (linguagem Dart) |
| Backend (API) | o "cérebro": guarda os dados e aplica as regras | Dart Frog (linguagem Dart) |
| Banco | onde os dados ficam salvos | MySQL 8.4 |

Uma linguagem só (**Dart**) para o app e para o backend.

## 2. O que já está pronto

Vocês **não começam do zero**. Já existe a **fundação**: a estrutura das pastas, os modelos de dados, a conexão com o banco, o login com token, o tratamento de erros, a navegação do app, os componentes visuais e as telas "em construção". E a **trilha** traz o código completo de cada parte que falta, explicado passo a passo.

O trabalho de cada pessoa é **implementar a própria parte seguindo a trilha**: digitar (ou colar), **entender**, testar e abrir um Pull Request. Assim o GitHub mostra a contribuição de cada um, e cada um sabe explicar o próprio código na apresentação.

> **Importante:** o código foi escrito sem ser executado (não havia Flutter/Dart na máquina onde foi gerado). O primeiro momento de rodar tudo é o **Sprint 0** (trilha/10). Pequenos ajustes (um import, uma versão de pacote) são esperados e fazem parte do aprendizado.

## 3. Ordem de leitura

### Semana 1 — todos juntos

| # | O quê | Onde | Tempo |
|---|---|---|---|
| 1 | Esta página | você está aqui | 10 min |
| 2 | Regras do grupo | [02-regras-do-grupo.md](02-regras-do-grupo.md) | 10 min |
| 3 | **Primeira reunião** (dividir as pessoas) | [01-primeira-reuniao.md](01-primeira-reuniao.md) | 1 h |
| 4 | O **seu** guia pessoal | [pessoas/](pessoas/) (o arquivo com o seu número) | 15 min |
| 5 | **Com quem você precisa se alinhar** (tela por tela) | [03-alinhamentos-entre-pessoas.md](03-alinhamentos-entre-pessoas.md) | 15 min |
| 6 | Trilha 01 e 02: entender o projeto e o processo | [../trilha/](../trilha/README.md) | 3 h |
| 7 | Trilha 03 e 04: **instalar o ambiente** e aprender Git | [../trilha/03](../trilha/03-ambiente-windows-vscode.md), [../trilha/04](../trilha/04-git-e-github-do-zero.md) | 4 a 5 h |
| 8 | Trilha 05 e 06: Dart e Flutter do zero | [../trilha/05](../trilha/05-dart-para-quem-vem-de-outras-linguagens.md), [../trilha/06](../trilha/06-flutter-essencial-e-mvvm.md) | 8 a 12 h |
| 9 | Trilha 07 a 09: arquitetura, banco, telas | [../trilha/07](../trilha/07-arquitetura-e-poo.md) a [09](../trilha/09-design-de-telas.md) | 6 h |
| 10 | Trilha 10: **Sprint 0** (tudo rodando em todas as máquinas) | [../trilha/10](../trilha/10-sprint-0-esqueleto-funcional.md) | 1 dia |

### Semanas 2 a 7 — cada um na sua parte

Siga as etapas da trilha indicadas no **seu guia pessoal** (pasta [pessoas/](pessoas/)). Resumo:

| Pessoa | Parte | Etapas |
|---|---|---|
| 1 | Login e cadastro | 11 → 12 → 16 → 17 |
| 2 | Telas e regras do doador | 11 → 13 → 16 → 18 |
| 3 | Reservas e expiração (servidor) | 11 → 15 → 16 → 19 (em dupla com a 5) |
| 4 | Infraestrutura, proximidade e mapa | 10 (lidera) → 11 → 14 → 16 → 20 |
| 5 | Telas da ONG | 16 → 19 (em dupla com a 3) |

Antes de cada tela que usa o trabalho de um colega, façam a conversa indicada em [03 — Alinhamentos](03-alinhamentos-entre-pessoas.md) (a mais importante é o **detalhe da doação para a ONG**, que junta P2, P3 e P5).

### Semana 8 — todos

Trilha [21 — Integração e testes](../trilha/21-integracao-e-testes.md) e [22 — Entrega](../trilha/22-documentacao-e-entrega.md).

## 4. Quanto tempo leva

Estimativa para o grupo **mexendo todo dia**, com as 5 pessoas trabalhando em paralelo (cada um na sua parte):

| Fase | Etapas | Com ~2 h por dia | Com ~4 h por dia |
|---|---|---|---|
| Aprender e instalar | trilha 01 a 09 | 2 a 3 semanas | 1 a 1,5 semana |
| Sprint 0 (tudo rodando) | 10 | 2 a 3 dias | 1 dia |
| Construir as partes (em paralelo) | 11 a 20 | 3 a 4 semanas | 2 a 2,5 semanas |
| Integração e testes | 21 | 1 semana | 3 a 4 dias |
| Documentação e entrega | 22 | 3 a 4 dias | 2 dias |
| **Total** | | **cerca de 7 a 9 semanas** | **cerca de 4 a 5 semanas** |

- O **caminho mais longo** é o da Pessoa 3 (reservas) seguido da Pessoa 5 (telas da ONG, que dependem das reservas para o teste no modo API). Se alguém terminar antes, ajude essas duas (em dupla, sem pegar o teclado).
- O calendário oficial de 8 semanas da [trilha/02](../trilha/02-processo-e-planejamento.md) já tem **uma semana de folga** no fim. Não gastem a folga antes da hora.
- O que mais atrasa grupos iniciantes: instalar o ambiente sozinho (façam juntos), deixar PRs grandes parados sem revisão (revisem em até 1 dia) e descobrir na integração que duas partes não combinam (façam os [alinhamentos](03-alinhamentos-entre-pessoas.md)).

## 5. Mapa do repositório: o que é cada pasta

```text
Summit/
├── 00_COMECE_AQUI/        ← VOCÊ ESTÁ AQUI. Primeira leitura, regras, guia de cada pessoa
├── trilha/                ← O PASSO A PASSO. É o que vocês vão seguir todos os dias
├── docs/                  ← CONSULTA. Detalhes (rotas da API, tabelas, decisões). Não precisa ler inteiro
├── desenvolvimento_app/   ← O CÓDIGO. É aqui que se programa
│   ├── shared_models/        modelos e regras usados pelo app e pelo backend
│   ├── backend/              a API (Dart Frog)
│   └── app/                  o aplicativo (Flutter)
├── database/              ← scripts do banco (rodar no MySQL Workbench)
├── .github/  .vscode/     ← configurações prontas (CI, tarefas do VS Code). Não precisa mexer
├── README.md              ← a "capa" do repositório no GitHub
├── CONTRIBUTING.md        ← regras curtas de Git e Pull Request
└── CHANGELOG.md           ← histórico de versões
```

| Pasta | Quando abrir | Pode ignorar no começo? |
|---|---|---|
| `00_COMECE_AQUI/` | primeiro dia (e o arquivo 03 antes de cada tela) | não |
| `trilha/` | todo dia | não |
| `docs/` | quando a trilha mandar consultar algo | **sim** |
| `docs/adr/` | quando quiser saber "por que escolheram X?" | **sim** |
| `desenvolvimento_app/` | a partir do Sprint 0 | até a trilha 10 |
| `database/` | trilha 08 e 10 | até a trilha 08 |
| `.github/`, `.vscode/` | só o líder/P4 no Sprint 0 | **sim** |

> **Regra de ouro:** para *fazer*, siga a **trilha**. Para *consultar*, use a **docs**. Na dúvida, pergunte no grupo.

## 6. Os 3 jeitos de travar (e como evitar)

| Trava | Como evitar |
|---|---|
| "Não consigo instalar X" | Instalem **juntos**, em chamada (trilha 03). Plano B: modo Fake, Chrome ou celular físico |
| "Estou esperando o colega terminar" | Ninguém espera ninguém: o app tem o **modo Fake** e o backend tem o `gerar_token.dart` |
| "Mexi no arquivo do colega e deu conflito" | Cada pessoa cria arquivos **só nas próprias pastas**; os arquivos de fundação já estão prontos |

## 7. Glossário rápido

| Palavra | Significado |
|---|---|
| **Fatia** | uma funcionalidade inteira, do banco à tela, com um dono |
| **Fundação** | o código-base pronto que todos usam (não editar sem combinar) |
| **Modo Fake** | o app funcionando com dados de mentira, sem backend |
| **Branch** | uma "cópia de trabalho" do código para uma tarefa |
| **Pull Request (PR)** | pedido para juntar a sua branch na `main`, revisado por um colega |
| **CI** | o GitHub rodando os testes sozinho a cada PR |
| **Sprint** | um ciclo de 2 semanas com metas definidas |
| **Seed** | os dados de exemplo (usuários e doações) para testar |

Próximo passo: [01 — Primeira reunião](01-primeira-reuniao.md).
