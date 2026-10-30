# Pessoa 4 — Infraestrutura, proximidade e mapa

**Sua missão:** fazer o projeto **rodar em todas as máquinas** (Sprint 0, banco, CI) e fazer a ONG **encontrar as doações perto dela**, na lista e no mapa.

**Histórias:** HU06 (doações próximas, backend) e HU12 (mapa). **Requisitos:** RF16, RF17, RF19.

## Sua sequência

| # | Etapa | O que você entrega | Feito |
|---|---|---|---|
| 1 | Trilha 01 a 09 (com todos) | ambiente pronto | [ ] |
| 2 | [10 — Sprint 0](../../trilha/10-sprint-0-esqueleto-funcional.md) **(você lidera com o líder)** | repositório, `CODEOWNERS`, `android/`, CI verde, tag `v0.1.0`, todos rodando | [ ] |
| 3 | [11 — Backend: fundamentos](../../trilha/11-backend-fundamentos.md) | entender rotas e camadas | [ ] |
| 4 | [14 — Backend: proximidade](../../trilha/14-backend-proximidade.md) | `GET /proximas` + 5 testes | [ ] |
| 5 | [16 — App: fundamentos](../../trilha/16-app-fundamentos.md) | entender MVVM | [ ] |
| 6 | [20 — App: mapa](../../trilha/20-app-mapa.md) | tela do mapa + 3 testes | [ ] |
| 7 | [21](../../trilha/21-integracao-e-testes.md) e [22](../../trilha/22-documentacao-e-entrega.md) | banco de demonstração, CI verde, **APK** da release, `docs/07` | [ ] |

## Seus arquivos

```text
database/                                       (scripts SQL e migrações)
.github/                                        (CI, modelos, CODEOWNERS)
desenvolvimento_app/backend/lib/proximidade/
desenvolvimento_app/backend/routes/proximas/
desenvolvimento_app/backend/test/proximidade/
desenvolvimento_app/app/lib/features/mapa/presentation/
desenvolvimento_app/app/test/features/mapa/
```

## Dependências

- **Você depende de:** ninguém para o Sprint 0. Para a proximidade: `dart run tool/gerar_token.dart 3 ong`.
- **Dependem de você:** **todos**, no Sprint 0. Sem o Sprint 0 ninguém começa. A Pessoa 5 usa o seu `GET /proximas` na tela inicial da ONG (no modo Fake ela não precisa esperar).

## Com quem você precisa se alinhar

| Com | Sobre | Quando |
|---|---|---|
| P1 | a localização gravada no cadastro (centro da busca e do mapa) | início do Sprint 1 |
| P5 | o seu `GET /proximas` (raio, `distanciaKm`, ordem) alimenta a tela inicial da ONG; o mapa abre o detalhe da P5 | início do Sprint 2 |
| P2 | doação criada pela P2 aparece no `/proximas` com a distância certa | quando as etapas 13 e 14 estiverem prontas |
| todos | CI, `CODEOWNERS` e problemas de instalação | Sprint 0 |

Detalhes: [03 — Alinhamentos](../03-alinhamentos-entre-pessoas.md).

## O que você precisa saber explicar

- Como a busca de proximidade funciona em **duas etapas** (caixa no SQL + Haversine no Dart) e por que não calcular tudo no Dart.
- Por que o **centro** da busca vem do perfil, e não do app.
- O que é um **tile**, por que a **atribuição do OpenStreetMap** é obrigatória.
- Como a **CI** protege a `main` (o que roda a cada PR).
- Por que o Docker é **opcional** (docs/23, seção 5).

## Dicas

- No Sprint 0, anote todo problema de instalação que aparecer e acrescente em `docs/22-troubleshooting.md`: é a sua contribuição para os colegas.
- Você é a pessoa que mais conhece o `api.http`, as tarefas do VS Code e a CI: seja a referência do grupo nisso.
