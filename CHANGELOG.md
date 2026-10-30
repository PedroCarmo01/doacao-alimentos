# Histórico de mudanças

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e versionamento [SemVer](https://semver.org/lang/pt-BR/). A cada versão entregue, movam os itens de "Não lançado" para uma seção com número e data, e criem a tag correspondente no Git (`git tag v0.2.0`).

## [Não lançado]

### Adicionado
- (cada PR acrescenta aqui uma linha do que entregou)

## [0.1.0] — Sprint 0 (esqueleto funcional)

### Adicionado
- Monorepo com `shared_models`, `backend` (Dart Frog) e `app` (Flutter).
- Modelos, contratos da API e validações compartilhados entre app e backend.
- Backend: configuração por `.env`, pool MySQL com TLS, tratamento padronizado de erros, CORS, JWT, bcrypt, health check `GET /`, seed de dados e gerador de token de teste.
- App: arquitetura MVVM, repositórios API e Fake, sessão com armazenamento seguro, roteador com proteção de rotas, tela inicial com status do servidor e telas "em construção".
- Banco MySQL 8.4: `schema.sql`, usuário de privilégio mínimo e consultas úteis.
- CI no GitHub Actions, templates de issue e PR, `CODEOWNERS`, configurações do VS Code.
- Documentação: `00_COMECE_AQUI` (ponto de partida e guia de cada pessoa), análise técnica, ADRs, documentação de referência (`docs/`) e trilha de desenvolvimento passo a passo (etapas 01 a 22 e apêndices).
