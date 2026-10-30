# 08 — API: o contrato entre o app e o backend

Este documento é o **contrato**: o app (repositórios `...Api`) e o backend (rotas) seguem exatamente o que está aqui. Os corpos e respostas são as classes do `shared_models` (`toJson`/`fromJson`), então os dois lados não conseguem divergir sem o compilador ou um teste reclamar.

- **Base local:** `http://127.0.0.1:8080` (no emulador Android: `http://10.0.2.2:8080`)
- **Formato:** JSON UTF-8. Campos em **camelCase**.
- **Datas:** instantes em ISO-8601 **UTC** (`"2026-09-15T14:30:00.000Z"`); validade como data (`"2026-09-16"`).
- **Autenticação:** `Authorization: Bearer <token>` em todas as rotas, exceto `GET /`, `POST /auth/cadastro` e `POST /auth/login`.
- **Testar na mão:** `desenvolvimento_app/backend/api.http` com a extensão REST Client.

## Formato de erro (todas as rotas)

```json
{
  "erro": {
    "codigo": "DOACAO_INDISPONIVEL",
    "mensagem": "Esta doação acabou de ser reservada por outra ONG ou não está mais disponível.",
    "detalhes": ["só aparece em erros de validação, uma mensagem por campo"]
  }
}
```

| HTTP | `codigo` | Quando |
|---|---|---|
| 400 | `VALIDACAO` | dados inválidos, JSON malformado ou campo faltando |
| 401 | `NAO_AUTENTICADO` | sem token |
| 401 | `TOKEN_INVALIDO` / `TOKEN_EXPIRADO` | token ruim ou vencido (o app volta para o login) |
| 401 | `CREDENCIAIS_INVALIDAS` | e-mail ou senha incorretos (mesma mensagem nos dois casos) |
| 403 | `SEM_PERMISSAO` | o perfil não pode fazer a ação (ex.: ONG criando doação) |
| 404 | `NAO_ENCONTRADO` | não existe **ou não é seu** |
| 405 | `METODO_NAO_PERMITIDO` | método HTTP não aceito na rota |
| 409 | `EMAIL_EM_USO`, `DOACAO_NAO_CANCELAVEL`, `DOACAO_INDISPONIVEL`, `RESERVA_NAO_ATIVA` | o estado atual não permite |
| 500 | `ERRO_INTERNO` | bug no servidor (detalhes só no terminal do backend) |

## Resumo das rotas

| Método | Rota | Quem | Dono | Trilha |
|---|---|---|---|---|
| GET | `/` | público | fundação | 10 |
| POST | `/auth/cadastro` | público | P1 | 12 |
| POST | `/auth/login` | público | P1 | 12 |
| GET | `/auth/me` | logado | P1 | 12 |
| POST | `/doacoes` | doador | P2 | 13 |
| GET | `/doacoes` | doador | P2 | 13 |
| GET | `/doacoes/{id}` | doador dono / ONG | P2 | 13 |
| DELETE | `/doacoes/{id}` | doador dono | P2 | 13 |
| GET | `/proximas?raioKm=` | ONG | P4 | 14 |
| POST | `/reservas` | ONG | P3 | 15 |
| GET | `/reservas` | ONG | P3 | 15 |
| DELETE | `/reservas/{id}` | ONG dona | P3 | 15 |
| POST | `/reservas/{id}/retirada` | ONG dona / doador dono | P3 | 15 |

---

## Saúde

### `GET /`

`200` (ou `503` se o banco não responder):

```json
{"servico": "api-doacao-alimentos", "status": "ok", "banco": "conectado", "horario": "2026-09-15T14:30:00.000Z"}
```

---

## Autenticação

### `POST /auth/cadastro` — `DadosCadastro` → `201 RespostaAutenticacao`

```json
{
  "tipo": "ong",
  "nome": "Coordenação Nova Esperança",
  "email": "novaesperanca@exemplo.com",
  "senha": "senha123",
  "nomeOrganizacao": "ONG Nova Esperança",
  "telefone": "(11) 99999-0000",
  "endereco": "Rua Nova, 10",
  "latitude": -23.53,
  "longitude": -46.19
}
```

Regras (`ValidadorUsuario`): nome 3–120; organização 3–160; e-mail válido e **único** (409 `EMAIL_EM_USO`); senha 6–72; telefone opcional com DDD; coordenadas válidas. O e-mail é guardado em minúsculas.

Resposta (`RespostaAutenticacao`, mesma do login):

```json
{
  "token": "eyJhbGciOi...",
  "usuario": {"id": 6, "nome": "Coordenação Nova Esperança", "email": "novaesperanca@exemplo.com", "tipo": "ong"},
  "perfil": {"usuarioId": 6, "nomeOrganizacao": "ONG Nova Esperança", "telefone": "(11) 99999-0000", "endereco": "Rua Nova, 10", "latitude": -23.53, "longitude": -46.19}
}
```

### `POST /auth/login` — `DadosLogin` → `200 RespostaAutenticacao`

```json
{"email": "mercado@exemplo.com", "senha": "senha123"}
```

Erro: 401 `CREDENCIAIS_INVALIDAS`.

### `GET /auth/me` → `200 Conta`

`{"usuario": {...}, "perfil": {...}}`. Usado pelo app ao abrir, para restaurar a sessão. Token inválido: 401.

---

## Doações (doador)

### Objeto `Doacao`

```json
{
  "id": 1,
  "doadorId": 1,
  "titulo": "Frutas e verduras do dia",
  "descricao": null,
  "categoria": "hortifruti",
  "quantidade": "5 caixas",
  "validade": "2026-09-17",
  "janelaInicio": "2026-09-15T13:30:00.000Z",
  "janelaFim": "2026-09-15T20:30:00.000Z",
  "endereco": "Rua Principal, 100 - Centro",
  "latitude": -23.5229,
  "longitude": -46.188,
  "status": "disponivel",
  "criadoEm": "2026-09-15T14:30:00.000Z",
  "nomeDoador": "Mercado Bom Preço",
  "distanciaKm": 0.62
}
```

- `categoria`: `hortifruti`, `padaria`, `laticinios`, `mercearia`, `refeicoesProntas`, `outros`.
- `status`: `disponivel`, `reservada`, `concluida`, `cancelada`.
- `nomeDoador` e `distanciaKm` são **de leitura** e só aparecem em algumas respostas (`distanciaKm` só em `/proximas`).

### `POST /doacoes` — `DadosNovaDoacao` → `201 Doacao`

```json
{
  "titulo": "Legumes do dia",
  "descricao": "Pequenas marcas, próprios para consumo.",
  "categoria": "hortifruti",
  "quantidade": "3 caixas",
  "validade": "2026-09-17",
  "janelaInicio": "2026-09-15T14:30:00Z",
  "janelaFim": "2026-09-15T18:30:00Z",
  "declaracaoAlimentosProprios": true
}
```

Regras (`ValidadorDoacao`): título 3–120; quantidade até 60; descrição até 500; **validade ≥ hoje** no fuso `FUSO_HORARIO`; janela com fim depois do início e no futuro; **declaração = true**. `latitude`, `longitude` e `endereco` são opcionais: sem eles, usa os do perfil. ONG: 403.

### `GET /doacoes` → `200 {"doacoes": [Doacao]}`

As do doador logado, todos os status, mais recentes primeiro.

### `GET /doacoes/{id}` → `200 DetalheDoacao`

```json
{"doacao": {...}, "reserva": {...} }
```

`reserva` é a reserva **ativa** (ou `null`). O doador só vê as próprias. A ONG vê as que ainda podem ser reservadas **ou** a que ela mesma reservou. Fora disso: 404.

### `DELETE /doacoes/{id}` → `204`

Só se `disponivel`. Senão: 409 `DOACAO_NAO_CANCELAVEL`.

---

## Proximidade (ONG)

### `GET /proximas?raioKm=5` → `200 {"doacoes": [Doacao]}`

- Centro: a localização do **perfil** da ONG (não vem do app).
- `raioKm` opcional (padrão `RAIO_PADRAO_KM`), limitado a 0,5–50. Não numérico: 400.
- Só doações `disponivel` com a janela aberta, com `distanciaKm`, **ordenadas da mais perto para a mais longe**.
- Doador: 403.

---

## Reservas

### Objeto `Reserva`

```json
{
  "id": 1,
  "doacaoId": 4,
  "ongId": 3,
  "status": "ativa",
  "reservadoEm": "2026-09-15T14:30:00.000Z",
  "expiraEm": "2026-09-15T16:30:00.000Z",
  "retiradoEm": null,
  "tituloDoacao": "Cestas de mercearia",
  "nomeOng": "ONG Mãos Amigas"
}
```

`status`: `ativa`, `concluida`, `expirada`, `cancelada`.

### `POST /reservas` — `DadosReserva` → `201 Reserva`

```json
{"doacaoId": 1}
```

- `expiraEm = mínimo(agora + RESERVA_MINUTOS, janelaFim)`.
- A doação passa para `reservada` na mesma transação.
- Doação inexistente: 404. Já reservada, cancelada, concluída ou janela encerrada: **409 `DOACAO_INDISPONIVEL`**. Doador: 403.

### `GET /reservas` → `200 {"reservas": [Reserva]}`

As da ONG logada (ativas e histórico), mais recentes primeiro. Reservas vencidas já aparecem como `expirada`.

### `DELETE /reservas/{id}` → `204`

A ONG dona desiste; a doação volta a `disponivel`. Não ativa: 409 `RESERVA_NAO_ATIVA`. De outra ONG: 404.

### `POST /reservas/{id}/retirada` → `200 Reserva`

ONG dona **ou** doador dono da doação. Reserva → `concluida` com `retiradoEm`; doação → `concluida`. Não ativa ou prazo vencido: 409 `RESERVA_NAO_ATIVA`. Outros usuários: 404.

### Expiração automática

Não é rota: o `ExpiracaoJob` (iniciado em `main.dart`) roda a cada 30 s. Reservas `ativa` com `expira_em <= agora` → `expirada`; a doação volta a `disponivel`.

---

## Usuários do seed (`dart run tool/seed.dart`)

| id | E-mail | Tipo | Organização |
|---|---|---|---|
| 1 | `mercado@exemplo.com` | doador | Mercado Bom Preço |
| 2 | `padaria@exemplo.com` | doador | Padaria Pão Quente |
| 3 | `maosamigas@exemplo.com` | ong | ONG Mãos Amigas (~0,6 km do mercado) |
| 4 | `pratocheio@exemplo.com` | ong | Instituto Prato Cheio (~3 km) |
| 5 | `distante@exemplo.com` | ong | Associação Distante (~45 km, fora do raio) |

Senha de todos: `senha123`. Token sem login: `dart run tool/gerar_token.dart <id> <doador|ong>`.
