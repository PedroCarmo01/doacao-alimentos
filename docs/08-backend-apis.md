# 08 — API: o contrato entre o app e o backend

Este documento é o **contrato**: o app (repositórios `...Api`) e o backend (rotas) seguem exatamente o que está aqui. Os corpos e respostas são as classes do `shared_models` (`toJson`/`fromJson`), então os dois lados não conseguem divergir sem o compilador ou um teste reclamar.

- **Base local:** `http://127.0.0.1:8080` (no emulador Android: `http://10.0.2.2:8080`)
- **Formato:** JSON UTF-8. Campos em **camelCase**.
- **Datas:** instantes em ISO-8601 **UTC** (`"2026-09-15T14:30:00.000Z"`); validade como data (`"2026-09-16"`).
- **Autenticação:** `Authorization: Bearer <token>` em todas as rotas, exceto `GET /`, `POST /auth/cadastro`, `POST /auth/login` e `GET /documentos/{numero}`. O token vale **30 dias** (`JWT_VALIDADE_DIAS`, RN05).
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
| 409 | `EMAIL_EM_USO`, `DOCUMENTO_EM_USO`, `DOACAO_NAO_CANCELAVEL`, `DOACAO_INDISPONIVEL`, `RESERVA_NAO_ATIVA` | o estado atual não permite |
| 422 | `DOCUMENTO_INVALIDO`, `CNPJ_NAO_ENCONTRADO`, `CNPJ_INATIVO`, `CNPJ_NAO_E_ENTIDADE` | o documento foi recusado (RN02, RN03) |
| 503 | `CONSULTA_INDISPONIVEL` | só na pré-consulta: a BrasilAPI não respondeu (dá para continuar o cadastro) |
| 500 | `ERRO_INTERNO` | bug no servidor (detalhes só no terminal do backend) |

## Resumo das rotas

A coluna **Etapa** diz em qual etapa do desenvolvimento a rota ficou pronta.

| Método | Rota | Quem | Etapa |
|---|---|---|---|
| GET | `/` | público | 0 ✅ |
| POST | `/auth/cadastro` | público | 1 ✅ |
| POST | `/auth/login` | público | 1 ✅ |
| GET | `/auth/me` | logado | 1 ✅ |
| GET | `/documentos/{numero}?tipo=` | público | 1 ✅ |
| PUT | `/perfil` | logado | 1 ✅ |
| POST | `/dispositivos` | logado | 1 ✅ (usada no push, etapa 9) |

Rotas da versão anterior, que serão refeitas nas etapas 2 a 4:

| Método | Rota | Quem | Dono | Trilha |
|---|---|---|---|---|
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
  "documento": "11.222.333/0001-81",
  "telefone": "(11) 99999-0000",
  "endereco": "Rua Nova, 10",
  "cep": "08780-000",
  "latitude": -23.53,
  "longitude": -46.19,
  "familiasAtendidas": 30,
  "transporte": "carro",
  "infoExtra": "Retiramos à tarde",
  "aceitouTermos": true
}
```

Doador manda também `"tipoEstabelecimento"` (`supermercado`, `hortifruti`, `feira`, `padaria`, `restaurante`, `produtorRural`, `outro`). Campos que não são do tipo da conta são ignorados (RN01).

Regras, na ordem (`AuthService.cadastrar`):

1. `ValidadorUsuario.validarCadastro` (as mesmas do app): nome 3–120; organização 3–160; e-mail válido; senha 6–72; **telefone obrigatório** com DDD; CEP com 8 números (opcional); termos aceitos; doador escolhe o tipo de estabelecimento. **RN02:** ONG só com CNPJ; feira, produtor rural e "outro" aceitam CNPJ ou CPF; os demais, só CNPJ; dígitos verificadores sempre conferidos (`ValidadorDocumento`). → 400 `VALIDACAO` com `detalhes`.
2. **RN04:** e-mail único (409 `EMAIL_EM_USO`) e documento único (409 `DOCUMENTO_EM_USO`).
3. **RN03:** CNPJ é consultado na BrasilAPI (até 5 s). Não existe → 422 `CNPJ_NAO_ENCONTRADO`; situação diferente de ATIVA → 422 `CNPJ_INATIVO`; ONG com natureza jurídica que não começa com 3 → 422 `CNPJ_NAO_E_ENTIDADE`. BrasilAPI fora do ar (ou `CONSULTAR_BRASILAPI=false`) → a conta é criada com `"verificacao": "pendente"` e o `ReverificacaoJob` tenta de novo a cada 10 min. CPF não tem consulta pública: fica `pendente`.

Documento e CEP são gravados só com números; o e-mail, em minúsculas.

Resposta (`RespostaAutenticacao`, mesma do login):

```json
{
  "token": "eyJhbGciOi...",
  "usuario": {"id": 8, "nome": "Coordenação Nova Esperança", "email": "novaesperanca@exemplo.com", "tipo": "ong"},
  "perfil": {
    "usuarioId": 8, "nomeOrganizacao": "ONG Nova Esperança",
    "tipoDocumento": "cnpj", "documento": "11222333000181", "verificacao": "verificada",
    "tipoEstabelecimento": null, "razaoSocial": "CAIXA ESCOLAR ...",
    "telefone": "(11) 99999-0000", "endereco": "Rua Nova, 10", "cep": "08780000",
    "latitude": -23.53, "longitude": -46.19,
    "familiasAtendidas": 30, "transporte": "carro",
    "buscaAtiva": true, "raioKm": 10.0, "suspensaAte": null, "infoExtra": "Retiramos à tarde"
  }
}
```

### `POST /auth/login` — `DadosLogin` → `200 RespostaAutenticacao`

```json
{"email": "mercado@exemplo.com", "senha": "senha123"}
```

Erro: 401 `CREDENCIAIS_INVALIDAS` ("E-mail ou senha incorretos.", igual para e-mail inexistente e senha errada).

### `GET /auth/me` → `200 Conta`

`{"usuario": {...}, "perfil": {...}}`. Usado pela tela de abertura (T1) para restaurar a sessão. Token vencido: 401 `TOKEN_EXPIRADO` (o app mostra "Sua sessão expirou. Entre novamente."); token inválido: 401 `TOKEN_INVALIDO`.

---

## Documentos

### `GET /documentos/{numero}?tipo=ong|doador` → `200 InfoCnpj` (pública)

Pré-consulta do CNPJ no passo 3 do cadastro, para o app preencher o nome. **Mande só os números**: a barra de `0001/81` quebraria o caminho da URL.

```json
{
  "cnpj": "11222333000181", "razaoSocial": "CAIXA ESCOLAR ...", "nomeFantasia": "...",
  "situacao": "ATIVA", "naturezaJuridica": "Associação Privada", "codigoNaturezaJuridica": 3999,
  "ativa": true, "semFinsLucrativos": true
}
```

Erros (422): `DOCUMENTO_INVALIDO`, `CNPJ_NAO_ENCONTRADO`, `CNPJ_INATIVO`, `CNPJ_NAO_E_ENTIDADE` (só com `tipo=ong`). BrasilAPI sem resposta: 503 `CONSULTA_INDISPONIVEL` (o app avisa e deixa continuar).

---

## Perfil

### `PUT /perfil` — `DadosPerfil` → `200 Conta`

Manda o perfil **inteiro** (o que mudou e o que não mudou). Documento, tipo e e-mail não mudam por aqui.

```json
{
  "nome": "Coordenação Mãos Amigas", "nomeOrganizacao": "ONG Mãos Amigas",
  "telefone": "(11) 4799-1111", "endereco": "Rua da Solidariedade, 45", "cep": "08780000",
  "latitude": -23.518, "longitude": -46.185,
  "familiasAtendidas": 120, "transporte": "van", "infoExtra": null,
  "buscaAtiva": false, "raioKm": 5
}
```

Regras: as mesmas do cadastro para nome, telefone, CEP e coordenadas; `raioKm` só 2, 5, 10 ou 20. Para doador, `familiasAtendidas`, `transporte`, `buscaAtiva` e `raioKm` voltam ao padrão (RN01). `GET /perfil/estatisticas` entra na etapa 7.

---

## Dispositivos

### `POST /dispositivos` — `{"token": "...", "plataforma": "android"}` → `204`

Guarda o identificador de push do celular (tabela `dispositivos`). Se o token já existe, só troca o dono e a data. O app passa a chamar esta rota na etapa 9 (push real); ela já existe para que a troca seja "mudar uma linha".

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

| id | E-mail | Tipo | Organização e situação para testar |
|---|---|---|---|
| 1 | `mercado@exemplo.com` | doador (supermercado, CNPJ) | Mercado Bom Preço: 3 doações disponíveis, 1 reservada, 2 concluídas, 3 expiradas |
| 2 | `padaria@exemplo.com` | doador (padaria, CNPJ) | Padaria Pão Quente: 1 refeição pronta disponível |
| 3 | `feirante@exemplo.com` | doador (feira, **CPF**) | Banca do Zé: 1 doação; verificação pendente |
| 4 | `maosamigas@exemplo.com` | ong | ONG Mãos Amigas: retirada em andamento (código **4821**) e conversa no chat |
| 5 | `pratocheio@exemplo.com` | ong | Instituto Prato Cheio: **2 desistências** (o próximo aviso é "mais uma e será suspensa") |
| 6 | `suspensa@exemplo.com` | ong | Casa Esperança: **suspensa** por mais 30 h |
| 7 | `distante@exemplo.com` | ong | Associação Distante (~45 km, fora do raio) |

Os ids da tabela valem logo depois de recriar o banco com o `schema.sql`. Rodar o seed de novo apaga as linhas com `DELETE`, que **não** reinicia a contagem: os ids mudam e os tokens antigos deixam de valer (o app volta para o login).

Senha de todos: `senha123`. Os CNPJs e o CPF são fictícios (dígitos calculados pelo `ValidadorDocumento`). O seed também cria 4 publicações na Comunidade. Token sem login: `dart run tool/gerar_token.dart <id> <doador|ong>`.
