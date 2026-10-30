# 02 — Processo e planejamento (Scrum adaptado + GitHub Projects)

**Objetivo:** definir **como** o grupo vai trabalhar: ritmo, papéis, backlog, histórias de usuário e riscos.
**Quem:** todos.

---

## 1. Modelo de processo: Scrum adaptado

Usaremos uma versão leve do **Scrum**, adequada a 5 estudantes com outras disciplinas.

| Elemento | Como fica no projeto |
|---|---|
| **Sprint** | 2 semanas (4 sprints + Sprint 0 + semana final) |
| **Product Owner (PO)** | O líder: prioriza o backlog e aceita as entregas |
| **Scrum Master** | Rodízio a cada sprint: marca as reuniões e cobra os impedimentos |
| **Time** | Os 5 integrantes |
| **Planning** | Início da sprint (1 h): escolher as issues da sprint |
| **Daily** | Assíncrona no WhatsApp, 3 linhas: *fiz / vou fazer / travei em* |
| **Review** | Fim da sprint (30 min): cada um mostra a sua parte funcionando |
| **Retrospectiva** | Logo após a review (15 min): *manter / melhorar / parar* |

## 2. Calendário (8 semanas)

| Sprint | Semanas | Meta (incremento entregue) |
|---|---|---|
| **0** | 1 | Ambiente de todos funcionando; esqueleto rodando ponta a ponta; CI verde |
| **1** | 2–3 | Autenticação e doações do doador no backend; telas de login, cadastro e do doador (modo Fake) |
| **2** | 4–5 | Proximidade e reservas no backend; telas da ONG e mapa (modo Fake) |
| **3** | 6–7 | Integração app ↔ API; testes; correções; acessibilidade |
| **Final** | 8 | Congelamento, documentação, release v1.0.0, ensaio da apresentação |

> A semana 8 é folga proposital: imprevistos sempre aparecem perto da entrega.

## 3. Backlog no GitHub Projects

O backlog fica no **GitHub Projects** (gratuito e integrado ao repositório):

1. No repositório: aba **Projects > New project > Board**.
2. Colunas: `Backlog`, `A fazer (sprint)`, `Em andamento`, `Em revisão`, `Pronto`.
3. Crie as issues com o modelo **História de usuário** (`.github/ISSUE_TEMPLATE`).
4. Use **Milestones** para as sprints (`Sprint 1`, `Sprint 2`...).
5. Use **Labels**: `historia`, `bug`, `backend`, `app`, `banco`, `docs`, `pessoa-1`...`pessoa-5`.

Quando um PR tem "Fecha #12" na descrição, a issue 12 é fechada sozinha no merge.

## 4. Histórias de usuário (backlog inicial)

Formato: **Como** [persona], **quero** [ação], **para** [benefício]. Os critérios de aceite usam **Dado / Quando / Então** e viram testes.

| ID | História | Dono | Sprint |
|---|---|---|---|
| HU01 | Como **doador/ONG**, quero me **cadastrar** com os dados da organização e a localização | P1 | 1 |
| HU02 | Como **usuário**, quero **entrar** com e-mail e senha e continuar logado ao reabrir o app | P1 | 1 |
| HU03 | Como **doador**, quero **publicar** uma doação com validade e janela de retirada | P2 | 1 |
| HU04 | Como **doador**, quero ver **minhas doações** e o status de cada uma | P2 | 1 |
| HU05 | Como **doador**, quero **cancelar** uma doação ainda não reservada | P2 | 1 |
| HU06 | Como **ONG**, quero ver as **doações próximas**, das mais perto para as mais longe | P4 + P5 | 2 |
| HU07 | Como **ONG**, quero ser **avisada** quando surgir uma doação nova perto de mim | P5 | 2 |
| HU08 | Como **ONG**, quero **reservar** uma doação e ver o **prazo** para buscar | P3 + P5 | 2 |
| HU09 | Como **sistema**, quero **expirar** reservas vencidas e liberar a doação para outras ONGs | P3 | 2 |
| HU10 | Como **ONG ou doador**, quero **confirmar a retirada** | P3 + P2/P5 | 2 |
| HU11 | Como **ONG**, quero **cancelar** minha reserva se não puder buscar | P3 + P5 | 2 |
| HU12 | Como **ONG**, quero ver as doações próximas **no mapa** | P4 | 2 |
| HU13 | Como **ONG**, quero ver o **histórico** das minhas reservas | P5 | 2 |

### Exemplo completo (HU08)

> **Como** ONG, **quero** reservar uma doação e ver o prazo para buscar, **para** garantir o alimento antes que outra organização o leve.
>
> **Critérios de aceite**
> - **Dado** uma doação disponível com janela aberta, **quando** a ONG reserva, **então** a doação fica "reservada" e o app mostra o tempo restante.
> - **Dado** que outra ONG reservou segundos antes, **quando** eu tento reservar, **então** vejo "Esta doação acabou de ser reservada por outra ONG".
> - **Dado** que a janela termina em 30 minutos e o prazo padrão é 2 horas, **quando** reservo, **então** o prazo termina junto com a janela.

## 5. Estimativa

Use **tamanhos de camiseta** em vez de horas: **P** (até meio dia), **M** (1 a 2 dias), **G** (3 a 5 dias). Se algo é maior que G, divida em duas issues. Estime em grupo na Planning (cada um mostra o tamanho ao mesmo tempo; se houver diferença grande, quem estimou o maior e o menor explica).

## 6. Definição de Pronto (DoD)

Está no [CONTRIBUTING.md](../CONTRIBUTING.md) e no modelo de PR. Resumo: atende aos critérios de aceite, tem testes das regras, CI verde, revisado por outra pessoa, sem segredos, documentação atualizada.

## 7. Matriz RACI

R = executa · A = aprova · C = consultado · I = informado

| Entrega | P1 | P2 | P3 | P4 | P5 |
|---|---|---|---|---|---|
| Sprint 0 (esqueleto, CI, banco) | C | I | I | **R** | I |
| Autenticação (backend + app) | **R** | C | I | I | I |
| Doações (backend + app doador) | I | **R** | C | I | I |
| Proximidade + mapa | I | C | C | **R** | C |
| Reservas e expiração (backend) | I | I | **R** | C | C |
| Telas da ONG | I | I | C | C | **R** |
| Documentação final e release | R | R | R | R | R |

O líder (PO) é o **A** de todas as entregas.

## 8. Registro de riscos

| Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|
| Alguém não consegue instalar o ambiente | Média | Alto | Instalação juntos, em chamada; modo Fake e Chrome como plano B |
| Atraso de uma fatia trava as outras | Média | Alto | Contratos definidos no Sprint 0; modo Fake; `gerar_token.dart` |
| Conflitos de merge | Baixa | Médio | Pastas por dono; arquivos de fundação congelados; PRs pequenos |
| Computador fraco para o emulador | Alta | Médio | Celular físico via USB ou Chrome |
| Integração tardia revela problemas | Média | Alto | Sprint 3 dedicada à integração; CI desde o Sprint 0 |
| Integrante some | Baixa | Alto | Daily assíncrona; código no GitHub desde o primeiro dia |

---

## Checklist

- [ ] Quadro criado no GitHub Projects com as 5 colunas
- [ ] Issues HU01–HU13 criadas, com dono e milestone
- [ ] Dia e horário da Planning e da Review definidos
- [ ] Scrum Master da Sprint 0 escolhido
