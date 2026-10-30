# ADR-001 — Monorepo com três pacotes Dart

- Status: Aceita
- Data: 2026-09-15

## Contexto
O sistema tem um app (Flutter) e uma API (Dart). Os dois trocam os mesmos dados (usuário, doação, reserva). Se cada lado tiver a sua própria classe `Doacao`, elas acabam divergindo, por exemplo quando alguém renomeia um campo só de um lado.

## Decisão
Um único repositório (monorepo) com três pacotes dentro de `desenvolvimento_app/`:
- `shared_models/`: modelos, enums, contratos da API (DTOs), validações e utilitários puros. Não depende de Flutter nem de banco.
- `backend/`: API em Dart Frog, que depende de `shared_models`.
- `app/`: app Flutter, que também depende de `shared_models`.

A dependência é feita por caminho (`path: ../shared_models`).

## Alternativas consideradas
- **Dois repositórios separados**: duplicaria os modelos e complicaria a entrega única no GitHub.
- **Publicar `shared_models` no pub.dev**: desnecessário para um projeto acadêmico.

## Consequências
- Positivas: um contrato único entre app e API; a mesma validação roda nos dois lados; uma só entrega no GitHub.
- Cuidados: os três pacotes devem ficar sempre lado a lado (o caminho `../shared_models` depende disso). Mudar um modelo afeta app e backend, por isso exige PR revisado por pelo menos uma pessoa de cada lado.
