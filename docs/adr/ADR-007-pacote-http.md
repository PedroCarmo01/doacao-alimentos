# ADR-007 — Pacote `http` oficial no lugar do `dio`

- Status: Aceita
- Data: 2026-09-15

## Contexto
O `dio` estava sendo usado principalmente pelos *interceptors*, para colocar o token em cada requisição. No nosso desenho, toda chamada já passa por uma única classe, o `ApiClient`.

## Decisão
Usar o pacote **`http`** (mantido pelo time do Dart). O `ApiClient` centraliza URL base, token, tempo limite, decodificação UTF-8 e tradução de erros para `ApiException`.

## Alternativas consideradas
- **`dio`**: mais recursos (interceptors, cancelamento, upload com progresso) do que o projeto precisa.

## Consequências
- Positivas: um conceito a menos para aprender; o `MockClient` oficial (`package:http/testing.dart`) facilita testar o `ApiClient`.
- Cuidados: sempre decodificar com `utf8.decode(resposta.bodyBytes)` para não quebrar acentos. Isso já está no `ApiClient`.
