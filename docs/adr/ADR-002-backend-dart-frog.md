# ADR-002 — Backend em Dart Frog

- Status: Aceita
- Data: 2026-09-15

## Contexto
O professor exige Dart e Flutter. O backend também precisa ser em Dart, e a equipe nunca fez um backend nessa linguagem.

## Decisão
Usar o **Dart Frog**: framework minimalista construído sobre o `shelf` (biblioteca HTTP oficial do Dart). Cada arquivo em `routes/` vira um endpoint, e cada pasta pode ter o seu `_middleware.dart`.

## Alternativas consideradas
- **Shelf puro**: oficial, mas exige montar o roteamento à mão, o que dá mais código repetitivo para iniciantes.
- **Serverpod**: completo (ORM, geração de código), mas a curva de aprendizado é alta e ele tem preferência por PostgreSQL.

## Consequências
- Positivas: o roteamento por arquivo combina com a divisão por pessoa (`routes/auth` é da Pessoa 1, `routes/reservas` da Pessoa 3 e assim por diante); o hot reload acelera o desenvolvimento; injeção de dependência via `provider`.
- Cuidados: o projeto foi criado pela Very Good Ventures e hoje é mantido pela comunidade (`github.com/dart-frog-dev/dart_frog`). Para reduzir esse risco, as regras de negócio ficam em classes *Service* que não importam o Dart Frog. Trocar de framework afetaria só a pasta `routes/`.
