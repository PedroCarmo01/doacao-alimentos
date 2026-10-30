# ADR-010 — Datas em UTC e relógio injetável

- Status: Aceita
- Data: 2026-09-15

## Contexto
A reserva tem prazo (por exemplo, 120 minutos) e a doação tem janela de retirada. Se o servidor gravar `NOW()` no fuso dele e o celular comparar com o horário local, o contador mostra valores errados. Além disso, testar "a reserva expirou?" é impossível se o código chama `DateTime.now()` diretamente.

## Decisão
- Todo **instante** (`DateTime`) trafega e é gravado em **UTC**. O backend converte com `Datas.paraSql()` e `Datas.deSql()`, e o JSON usa ISO-8601 com `Z`.
- A **validade** do alimento é uma data de calendário (`AAAA-MM-DD`), sem horário.
- O app converte para o horário local só na hora de exibir (`Formatadores`).
- Nenhuma regra chama `DateTime.now()` diretamente: as classes recebem um `Relogio` (interface do `shared_models`). Em produção usa-se `RelogioSistema`; nos testes, `RelogioFixo`, que permite "avançar o tempo".
- O fuso do Brasil usado para decidir "hoje" vem de `FUSO_HORARIO` no `.env` (padrão: −3).

## Consequências
- Positivas: horários corretos em qualquer aparelho; testes de expiração rodam em milissegundos.
- Cuidados: nunca usar `NOW()` nem `CURRENT_TIMESTAMP` nas queries; o horário sempre vem do `Relogio`, como parâmetro.
