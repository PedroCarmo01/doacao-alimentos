# Pessoa 3 — Reservas e expiração (servidor)

**Sua missão:** a regra mais importante do sistema. **Duas ONGs nunca ficam com a mesma doação**, toda reserva tem **prazo** e, se ninguém buscar, ela **expira sozinha** e a doação volta para as outras ONGs.

**Histórias:** HU08 (reservar), HU09 (expirar), HU10 (retirada), HU11 (desistir). **Requisitos:** RF20–RF27.

## Sua sequência

| # | Etapa | O que você entrega | Feito |
|---|---|---|---|
| 1 | Trilha 01 a 10 (com todos) | ambiente pronto e Sprint 0 rodando | [ ] |
| 2 | [11 — Backend: fundamentos](../../trilha/11-backend-fundamentos.md) | entender rotas, middlewares, **transações** | [ ] |
| 3 | [15 — Backend: reservas e expiração](../../trilha/15-backend-reservas.md) | 4 rotas de reserva, job de expiração no `main.dart` + 8 testes | [ ] |
| 4 | [16 — App: fundamentos](../../trilha/16-app-fundamentos.md) | entender o app para ajudar a Pessoa 5 | [ ] |
| 5 | [19 — App: telas da ONG](../../trilha/19-app-ong.md) **em dupla com a Pessoa 5** | revisar e testar as telas que usam as suas rotas | [ ] |
| 6 | [21](../../trilha/21-integracao-e-testes.md) e [22](../../trilha/22-documentacao-e-entrega.md) | teste de concorrência com duas ONGs; `docs/12` com as suas palavras | [ ] |

## Seus arquivos

```text
desenvolvimento_app/backend/lib/reservas/
desenvolvimento_app/backend/routes/reservas/
desenvolvimento_app/backend/test/reservas/
desenvolvimento_app/backend/main.dart   (só descomentar o bloco do job; combinar com o grupo)
```

## Dependências

- **Você depende de:** Sprint 0. Tokens de teste: `dart run tool/gerar_token.dart 3 ong` (Mãos Amigas) e `4 ong` (Prato Cheio). O seed já tem doações disponíveis.
- **Dependem de você:** a Pessoa 5 (telas da ONG) no modo API. Enquanto isso, ela usa o `BancoFake`, que já imita as suas regras.

## Com quem você precisa se alinhar

| Com | Sobre | Quando |
|---|---|---|
| P5 | **todas** as suas rotas: corpo, resposta, erros (`DOACAO_INDISPONIVEL`, `RESERVA_NAO_ATIVA`) e o que a tela mostra | antes da P5 começar cada tela |
| P2 e P5 | detalhe da doação para a ONG e a reserva ativa no detalhe do doador — conversa a três | início do Sprint 2 |
| P2 | confirmar retirada pelo doador; aliases `titulo_doacao` e `nome_ong` | quando começar a etapa 15 |
| líder | o bloco do job no `main.dart` (fundação) | no seu PR |

Detalhes: [03 — Alinhamentos](../03-alinhamentos-entre-pessoas.md).

## O que você precisa saber explicar

Este é o **ponto técnico mais forte** da apresentação. Prepare-se para:

- O que é uma **condição de corrida** e as **três camadas** de proteção (checagem no Service, `SELECT ... FOR UPDATE` na transação, índice `UNIQUE` sobre a coluna gerada).
- O que é uma **transação** (tudo ou nada) e por que reservar mexe em duas tabelas.
- Como o **job** funciona (`Timer.periodic`, `??=` para não duplicar) e por que o Service também expira antes de reservar.
- Como os testes "avançam o tempo" com `RelogioFixo`.
- Demonstração ao vivo: **duas ONGs** reservando ao mesmo tempo e uma reserva **expirando** com `RESERVA_MINUTOS=2`.

## Dicas

- É a etapa mais longa (5 a 7 dias). Faça um passo por dia e abra PRs parciais (repositório + testes primeiro).
- Faça o teste "burlando" o código direto no Workbench (passo 7 da etapa 15): é ótimo para mostrar ao professor.
