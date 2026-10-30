# Documentação de referência — Índice

Esta pasta é a **referência** do projeto: o que o sistema faz, como ele é construído e por quê. O **passo a passo** (com código pronto e checklists) fica na [trilha](../trilha/README.md).

> **Regra prática:** para *fazer* algo, siga a trilha. Para *consultar* um detalhe (uma rota da API, uma coluna do banco, uma variável do `.env`), use esta pasta.
>
> Primeira vez no projeto? Comece por [`00_COMECE_AQUI`](../00_COMECE_AQUI/README.md).

## Sumário

### Produto

| # | Documento | Conteúdo |
|---|---|---|
| 01 | [Visão geral](01-visao-geral.md) | Problema, personas, funcionalidades, fluxo geral |
| 02 | [Requisitos](02-requisitos.md) | Requisitos funcionais e não funcionais, fora de escopo |
| 10 | [Telas](10-telas.md) | Cada tela: quem usa, o que mostra, arquivo e responsável |
| 11 | [Fluxos](11-fluxos.md) | Fluxos de usuário e estados (diagramas) |
| 20 | [Roadmap](20-roadmap.md) | MVP, melhorias e evoluções futuras |

### Técnica

| # | Documento | Conteúdo |
|---|---|---|
| 03 | [Stack](03-stack.md) | Tecnologias, versões e por quê |
| 04 | [Arquitetura](04-arquitetura.md) | Camadas, componentes e diagramas |
| 06 | [Estrutura do projeto](06-estrutura-projeto.md) | Pastas e arquivos, quem é dono de quê |
| 07 | [Banco de dados](07-banco-de-dados.md) | Modelo, tabelas, regras garantidas pelo banco |
| 08 | [API (contrato)](08-backend-apis.md) | Todas as rotas, corpos, respostas e erros |
| 09 | [Frontend](09-frontend.md) | Arquitetura do app: MVVM, repositórios, sessão, rotas |
| 12 | [Partes complexas](12-partes-complexas.md) | Concorrência, expiração, proximidade, fuso horário, aviso de novidade |
| 13 | [Variáveis de ambiente](13-variaveis-ambiente.md) | `.env` do backend e `--dart-define` do app |
| 15 | [Padrões de código](15-padroes.md) | Nomes, estilo, organização |
| 16 | [Testes](16-testes.md) | Estratégia, onde ficam, como rodar |
| 17 | [Segurança](17-seguranca.md) | O que foi feito e por quê |
| 23 | [Análise técnica](23-analise-tecnica.md) | Revisão completa e decisões tomadas |
| ADR | [Decisões de arquitetura](adr/README.md) | Um registro por decisão importante |

### Processo e operação

| # | Documento | Conteúdo |
|---|---|---|
| 05 | [Setup da máquina](05-setup-maquina-pessoal.md) | Atalho para a trilha/03 |
| 14 | [Git e trabalho em equipe](14-git-workflow.md) | Branches, PRs, revisão, conflitos |
| 18 | [Docker](18-docker.md) | Opcional: atalho para o apêndice A |
| 19 | [Deploy](19-deploy.md) | Opcional: publicar a API |
| 21 | [Checklist geral](21-checklist.md) | Visão do projeto inteiro por fase |
| 22 | [Troubleshooting](22-troubleshooting.md) | Problema → causa → solução |

## Convenções

- Comandos de terminal são para **PowerShell** (Windows), o terminal padrão do VS Code.
- Diagramas usam **Mermaid** (o GitHub desenha automaticamente).
- Nomes de classes, métodos e arquivos citados aqui existem **de verdade** no código; se divergir, o código vale e a documentação deve ser corrigida num PR `docs:`.
