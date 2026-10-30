# ADR-004 — Driver `mysql_client` com pool de conexões e TLS

- Status: Aceita
- Data: 2026-09-15

## Contexto
O código original abria uma única conexão com `secure: false`. No MySQL 8.4, o método de login padrão (`caching_sha2_password`) exige conexão segura, e uma conexão única não se recupera quando o servidor a encerra por inatividade.

## Decisão
- Usar `MySQLConnectionPool` do pacote `mysql_client`, com TLS ligado (`secure: true`, o padrão do driver; configurável por `DB_TLS` no `.env`).
- Encapsular o pool na classe `Database` (backend `lib/core/db/`), com métodos `consultar`, `executar`, `inserir`, `transacao` e `ping`.
- **Sempre** usar parâmetros nomeados (`:id`) nas queries, nunca concatenar texto.

## Alternativas consideradas
- **`mysql1`**: não suporta `caching_sha2_password`.
- **Trocar o usuário do banco para `mysql_native_password`**: método legado, desativado por padrão no 8.4 e removido no 9.0.

## Consequências
- Positivas: conexões renovadas sob demanda; login compatível com o padrão do MySQL 8.4; proteção contra SQL Injection pela parametrização.
- Cuidados: o driver devolve valores como texto. A conversão para `int`, `double` e `DateTime` é feita em um único lugar (`Mapeador`). Não use nomes de parâmetro que sejam prefixo de outro (`:lat` e `:latMin`, por exemplo).
