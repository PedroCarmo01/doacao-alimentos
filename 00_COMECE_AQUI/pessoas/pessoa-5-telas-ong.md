# Pessoa 5 — Telas da ONG

**Sua missão:** a experiência de quem **recebe** as doações. A ONG vê o que está perto, é **avisada** quando surge algo novo, reserva, acompanha o **prazo** com um contador, confirma a retirada e consulta o histórico.

**Histórias:** HU06 (lista, no app), HU07 (aviso de novidade), HU08 e HU11 (reservar/desistir, no app), HU10 (retirada, lado da ONG), HU13 (histórico). **Requisitos:** RF16, RF18, RF20–RF23.

## Sua sequência

| # | Etapa | O que você entrega | Feito |
|---|---|---|---|
| 1 | Trilha 01 a 10 (com todos) | ambiente pronto e Sprint 0 rodando | [ ] |
| 2 | [09 — Design de telas](../../trilha/09-design-de-telas.md) **(você lidera)** | wireframes e padrões visuais combinados com o grupo | [ ] |
| 3 | [16 — App: fundamentos](../../trilha/16-app-fundamentos.md) | entender MVVM e a receita de tela | [ ] |
| 4 | [19 — App: telas da ONG](../../trilha/19-app-ong.md) **em dupla com a Pessoa 3** | doações próximas com aviso, detalhe com reserva, minhas reservas + 6 testes | [ ] |
| 5 | [21](../../trilha/21-integracao-e-testes.md) e [22](../../trilha/22-documentacao-e-entrega.md) | revisão de acessibilidade; manual do usuário (ONG); relatório de testes | [ ] |

> Você não tem etapa de backend: a Pessoa 3 faz as reservas no servidor. Use o tempo extra para caprichar no visual, na acessibilidade e nos testes, e para ajudar a Pessoa 3 a testar as rotas pelo `api.http`.

## Seus arquivos

```text
desenvolvimento_app/app/lib/features/ong/presentation/
desenvolvimento_app/app/test/features/ong/
```

## Dependências

- **Você depende de:** nada para começar: o **modo Fake** já tem doações, reservas, expiração em 2 minutos e até uma "doação surpresa" a cada 45 s para testar o aviso.
- **No modo API**, depende do backend das Pessoas 1 (login), 4 (`/proximas`) e 3 (`/reservas`).

## Com quem você precisa se alinhar

Você é quem **mais depende** dos outros (a sua tela usa rotas de três pessoas). Marque estas conversas cedo:

| Com | Sobre | Quando |
|---|---|---|
| P4 | `GET /proximas` (raio, `distanciaKm`, ordem) e a navegação lista ↔ mapa | antes da tela inicial |
| P3 | rotas de reserva, erros e o prazo do contador | antes do detalhe e de Minhas reservas |
| P2 e P3 | **detalhe da doação para a ONG** (o que você pode ver, o 404 depois da retirada) — conversa a três | início do Sprint 2 |
| P1 | botão Sair igual ao do doador | antes da tela inicial |
| todos | padrões visuais (você lidera a trilha 09) | Sprint 0 |

Detalhes: [03 — Alinhamentos](../03-alinhamentos-entre-pessoas.md).

## O que você precisa saber explicar

- Como o **aviso de novidade** funciona (atualização a cada 15 s + conjunto de ids já vistos) e por que não usamos WebSocket no MVP (ADR-008).
- Por que o **timer** precisa ser cancelado no `dispose`.
- O que a tela faz quando **outra ONG reserva antes** (409 `DOACAO_INDISPONIVEL`).
- Como a tela separa **View** (desenho) e **ViewModel** (estado e ações).

## Dicas

- Faça na ordem: lista → detalhe → minhas reservas. Cada uma é um PR.
- O teste de concorrência com a Pessoa 3 (duas pessoas tocando em "Reservar" juntas) é o momento mais legal da apresentação. Ensaiem!
