# Registros de Decisão de Arquitetura (ADR)

Um **ADR** (*Architecture Decision Record*) registra uma decisão técnica importante: o contexto, o que foi decidido, as alternativas e as consequências. É uma prática comum em Engenharia de Software para que qualquer pessoa (inclusive o professor) entenda **por que** o projeto é como é.

## Como usar

- Antes de trocar uma tecnologia ou mudar a arquitetura, leia o ADR correspondente.
- Para uma decisão nova, copie o modelo abaixo, numere em sequência e abra um Pull Request para o grupo discutir.
- Um ADR não é apagado quando muda de ideia: crie um novo e marque o antigo como "Substituído por ADR-XXX".

## Índice

| ADR | Decisão | Status |
|---|---|---|
| [001](ADR-001-monorepo-tres-pacotes.md) | Monorepo com três pacotes Dart (app, backend, shared_models) | Aceita |
| [002](ADR-002-backend-dart-frog.md) | Backend em Dart Frog | Aceita |
| [003](ADR-003-mysql-84-nativo-docker-opcional.md) | MySQL 8.4 LTS instalado nativamente; Docker opcional | Aceita |
| [004](ADR-004-driver-mysql-pool-tls.md) | Driver `mysql_client` com pool de conexões e TLS | Aceita |
| [005](ADR-005-app-mvvm-changenotifier.md) | App em MVVM com `ChangeNotifier` (sem Riverpod) | Aceita |
| [006](ADR-006-injecao-por-construtor.md) | Injeção de dependência por construtor + raiz de composição | Aceita |
| [007](ADR-007-pacote-http.md) | Pacote `http` oficial no lugar do `dio` | Aceita |
| [008](ADR-008-polling-no-mvp.md) | Atualização periódica (polling) no MVP; WebSocket opcional | Aceita |
| [009](ADR-009-jwt-bcrypt-secure-storage.md) | Autenticação com JWT + bcrypt; token no armazenamento seguro | Aceita |
| [010](ADR-010-datas-utc-relogio.md) | Datas em UTC e relógio injetável | Aceita |
| [011](ADR-011-walking-skeleton-fatias-fakes.md) | Walking skeleton, fatias verticais por pessoa e repositórios Fake | Aceita |
| [012](ADR-012-configuracao-dotenv-dart-define.md) | Configuração: `.env` no backend e `--dart-define` no app | Aceita |

## Modelo

```markdown
# ADR-0XX — Título curto da decisão

- Status: Proposta | Aceita | Substituída por ADR-0YY
- Data: AAAA-MM-DD

## Contexto
Qual problema ou necessidade motivou a decisão?

## Decisão
O que foi decidido, em uma ou duas frases.

## Alternativas consideradas
- Opção A — por que não
- Opção B — por que não

## Consequências
- Positivas: ...
- Negativas / cuidados: ...
```
