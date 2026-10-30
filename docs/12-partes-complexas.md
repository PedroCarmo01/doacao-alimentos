# 12 — Partes complexas

As cinco partes do sistema que mais costumam gerar dúvida (e perguntas do professor). Cada seção explica o problema, a solução adotada e onde está o código. O código completo está nas etapas da trilha indicadas.

> **Responsável por revisar este documento na entrega:** Pessoa 3 ([trilha/22](../trilha/22-documentacao-e-entrega.md)).

## 1. Duas ONGs reservando ao mesmo tempo

**Problema (condição de corrida):** duas ONGs leem "disponível" no mesmo instante e as duas gravam uma reserva.

**Solução em três camadas:**

| Camada | Onde | Garante |
|---|---|---|
| Checagem no Service | `ReservaService.reservar` → `doacao.podeSerReservada(agora)` | resposta rápida e clara no caso comum |
| Trava da linha | `ReservaRepositoryMysql.criarSeDisponivel`: transação com `SELECT ... FOR UPDATE` | a segunda transação **espera** a primeira e lê o status novo |
| Índice único | `schema.sql`: coluna gerada `doacao_ativa_id` + `UNIQUE uk_reservas_uma_ativa_por_doacao` | o MySQL recusa a segunda reserva ativa mesmo se o código falhar; o repositório converte o erro 1062 em 409 |

O mesmo padrão "confere no Service + confere de novo, de forma atômica, no banco" aparece no cancelamento da doação (`UPDATE ... WHERE status = 'disponivel'`, trilha 13).

Código: [trilha/15](../trilha/15-backend-reservas.md). Como demonstrar: [trilha/19, passo 7](../trilha/19-app-ong.md).

## 2. Expiração automática das reservas

**Problema:** o banco não "avisa" quando um horário passa. Uma reserva esquecida prenderia a comida.

**Solução:**

- `ExpiracaoJob` (`backend/lib/reservas/expiracao_job.dart`) com `Timer.periodic` de 30 s, iniciado **uma vez** em `main.dart` (`_job ??= ...` evita timers duplicados no hot reload do `dart_frog dev`).
- Cada rodada chama `ReservaService.expirarVencidas()`, que numa transação: (1) volta as doações das reservas vencidas para `disponivel`; (2) marca as reservas como `expirada`. A ordem importa, porque o passo 1 usa o `JOIN` com as reservas ainda ativas.
- **Defesa extra:** o Service também expira as vencidas antes de reservar e de listar, então uma reserva vencida nunca bloqueia outra ONG, mesmo nos 30 s entre duas rodadas.
- **Prazo:** `expiraEm = mínimo(agora + RESERVA_MINUTOS, janelaFim)`.
- **Testes:** `RelogioFixo.avancar(...)` simula a passagem do tempo em milissegundos.

No app, o `ContadorRegressivo` chama `aoExpirar` quando chega a zero, e a tela recarrega. No modo Fake, o `BancoFake` expira as reservas a cada chamada (`simularRede`).

## 3. Doações próximas

**Problema:** achar as doações a até *R* km da ONG, ordenadas pela distância, sem calcular a distância de todas as doações do banco.

**Solução em duas etapas** (`backend/lib/proximidade/`, [trilha/14](../trilha/14-backend-proximidade.md)):

1. **Filtro grosso no SQL:** uma **caixa** de latitude/longitude ao redor da ONG (`AreaDeBusca.aoRedor`), com `BETWEEN`, que usa o índice `idx_doacoes_localizacao`. 1° de latitude ≈ 111,32 km; 1° de longitude ≈ 111,32 × cos(latitude) km.
2. **Filtro fino no Dart:** distância exata pela **fórmula de Haversine** (`Geo.distanciaKm`, no `shared_models`), descarte dos "cantos" da caixa e ordenação.

O **centro** vem do perfil cadastrado (a ONG não consegue "fingir" estar em outro lugar), e o raio é limitado a 0,5–50 km.

## 4. Datas, horários e fuso

**Problema:** o servidor, o banco e o celular podem estar em fusos diferentes. Às 22h em Brasília já é o dia seguinte em UTC.

**Regras** ([ADR-010](adr/ADR-010-datas-utc-relogio.md)):

| Onde | Regra |
|---|---|
| Banco | todo `DATETIME` é UTC, gravado pelo backend com `Datas.paraSql` (nada de `NOW()`) |
| API | ISO-8601 com `Z` (`2026-09-15T14:30:00.000Z`); validade como `AAAA-MM-DD` |
| Backend | "agora" vem do `Relogio` injetado; "hoje" = `Calendario.dataNoFuso(agora, FUSO_HORARIO)` |
| App | "hoje" = data local do aparelho; exibição sempre pelo `Formatador` (`toLocal()`) |
| Testes | `RelogioFixo` com datas fixas |

`DateTime.now()` só aparece em `RelogioSistema` (e no `ContadorRegressivo`, que só desenha).

## 5. Aviso de doação nova para a ONG

**Problema:** a ONG precisa saber quando surge uma doação perto dela.

**Solução do MVP: atualização periódica (polling)** ([ADR-008](adr/ADR-008-polling-no-mvp.md)):

- `HomeOngViewModel.iniciarAtualizacaoAutomatica()` cria um `Timer.periodic(AppConfig.intervaloAtualizacao)` (15 s) que chama `GET /proximas`.
- Um `Set<int>` guarda os ids já vistos. Na primeira carga, nada é novidade; depois, ids novos ganham a etiqueta **NOVA** e incrementam `novidadesParaAvisar`.
- A página escuta o ViewModel (`addListener`) e mostra um **SnackBar**; depois chama `avisoMostrado()`.
- O timer é cancelado no `dispose` do ViewModel.

**Limitação consciente:** atraso de até 15 s e só com o app aberto. Evoluções: WebSocket ([apêndice B](../trilha/apendice-b-websocket-opcional.md)) e push com Firebase Cloud Messaging ([roadmap](20-roadmap.md)).

## Outras partes que valem uma explicação na apresentação

| Tema | Onde |
|---|---|
| Por que a senha não é guardada (bcrypt, sal) | `SenhaService`, [trilha/12](../trilha/12-backend-autenticacao.md) |
| O que tem dentro do JWT (só `uid` e `tipo`) | `TokenService`, [17 — Segurança](17-seguranca.md) |
| Linha do banco → JSON tipado | `Mapeador` (achado A01 da [análise](23-analise-tecnica.md)) |
| Mesma validação no app e no backend | `ValidadorUsuario`, `ValidadorDoacao` |
| Trocar API por Fake sem mudar as telas | `Dependencias`, polimorfismo ([trilha/07](../trilha/07-arquitetura-e-poo.md)) |
