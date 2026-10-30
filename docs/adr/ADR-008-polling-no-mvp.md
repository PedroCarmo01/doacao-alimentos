# ADR-008 — Atualização periódica (polling) no MVP; WebSocket opcional

- Status: Aceita
- Data: 2026-09-15

## Contexto
O requisito é avisar as ONGs próximas quando surge uma doação e quando uma reserva expira. Havia duas opções técnicas:
- **WebSocket**: o servidor "empurra" o aviso. Exige registro de conexões no servidor, reconexão no app e autenticação do canal.
- **Polling**: o app pergunta ao servidor a cada N segundos.

Os dois só funcionam **com o app aberto**. Avisar com o app fechado exige push notification (Firebase Cloud Messaging), que está fora do escopo.

## Decisão
No MVP, a tela inicial da ONG consulta `GET /proximas` a cada **15 segundos** (`AppConfig.intervaloAtualizacao`), compara com a lista anterior e mostra um aviso "Nova doação perto de você" para os itens novos. Quando uma reserva expira, a doação volta para "disponível" e aparece como nova para as outras ONGs na próxima consulta, o que atende ao requisito de "avisar de novo". O WebSocket está documentado como evolução opcional no [apêndice B](../../trilha/apendice-b-websocket-opcional.md).

## Alternativas consideradas
- **WebSocket no MVP**: mesma experiência para o usuário, com o triplo de código e de pontos de falha.
- **Push (FCM)**: exige Firebase, conta Google e configuração nativa; fica para versões futuras.

## Consequências
- Positivas: implementação simples e testável (um `Timer` no ViewModel); nenhuma infraestrutura extra.
- Negativas: o aviso pode chegar com até 15 segundos de atraso, e há uma requisição a cada intervalo por app aberto (irrelevante na escala do projeto).
