# 21 — Checklist geral do projeto

Visão do projeto inteiro numa página. Cada etapa da trilha tem o próprio checklist detalhado; aqui ficam só os marcos. O líder atualiza esta página (ou o quadro do GitHub Projects) a cada sprint.

## Sprint 0 — esqueleto ([trilha 01–11](../trilha/README.md))

- [ ] Todos leram [`00_COMECE_AQUI`](../00_COMECE_AQUI/README.md) e fizeram a reunião de kickoff
- [ ] As 5 máquinas com Git, Flutter, Android, Dart Frog, MySQL 8.4 e VS Code ([trilha/03](../trilha/03-ambiente-windows-vscode.md))
- [ ] Repositório no GitHub, 5 colaboradores, `main` protegida, squash merge
- [ ] `CODEOWNERS` com os usuários reais
- [ ] `android/` gerado e configurado
- [ ] `GET /` com `"banco":"conectado"` em todas as máquinas
- [ ] App abre nos modos Fake e API
- [ ] CI verde
- [ ] Quadro do Projects com HU01–HU13
- [ ] Tag `v0.1.0`

## Sprint 1 — autenticação e doador

| Item | Dono | Etapa | Feito |
|---|---|---|---|
| Backend: cadastro, login, `/auth/me` | P1 | 12 | [ ] |
| Backend: criar, listar, detalhar, cancelar doação | P2 | 13 | [ ] |
| App: login e cadastro | P1 | 17 | [ ] |
| App: minhas doações, nova doação, detalhe | P2 | 18 | [ ] |

## Sprint 2 — ONG

| Item | Dono | Etapa | Feito |
|---|---|---|---|
| Backend: doações próximas | P4 | 14 | [ ] |
| Backend: reservas + job de expiração | P3 | 15 | [ ] |
| App: doações próximas, detalhe com reserva, minhas reservas | P5 (+P3) | 19 | [ ] |
| App: mapa | P4 | 20 | [ ] |

## Sprint 3 — integração ([trilha/21](../trilha/21-integracao-e-testes.md))

- [ ] Roteiro de 21 cenários executado no modo API
- [ ] `docs/relatorio-de-testes.md`
- [ ] Bugs como issues, corrigidos com teste de regressão
- [ ] Revisão de acessibilidade
- [ ] Tag `v0.9.0` (congelamento)

## Entrega ([trilha/22](../trilha/22-documentacao-e-entrega.md))

- [ ] README final com prints, equipe e uso de IA (se exigido)
- [ ] `docs/manual-do-usuario.md`
- [ ] `docs/08`, `docs/07` e `docs/12` conferidos com o código
- [ ] `CHANGELOG.md` com a 1.0.0
- [ ] Tag `v1.0.0` e release com o APK
- [ ] Professor com acesso
- [ ] Os 5 aparecem em *Insights → Contributors*
- [ ] Apresentação ensaiada duas vezes, com plano B

## Definição de Pronto (toda tarefa)

Está no [CONTRIBUTING.md](../CONTRIBUTING.md): atende aos critérios de aceite, tem testes das regras, CI verde, revisada por outra pessoa, sem segredos, documentação atualizada.
