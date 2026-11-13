# 08 — API: o contrato entre o app e o backend

Este documento é o **contrato**: o app (repositórios `...Api`) e o backend (rotas) seguem exatamente o que está aqui. Os corpos e respostas são as classes do `shared_models` (`toJson`/`fromJson`), então os dois lados não conseguem divergir sem o compilador ou um teste reclamar.

- **Base local:** `http://127.0.0.1:8080` (no emulador Android: `http://10.0.2.2:8080`)
- **Formato:** JSON UTF-8. Campos em **camelCase**.
- **Datas:** instantes em ISO-8601 **UTC** (`"2026-09-15T14:30:00.000Z"`); validade como data (`"2026-09-16"`).
- **Autenticação:** `Authorization: Bearer <token>` em todas as rotas, exceto `GET /`, `POST /auth/cadastro`, `POST /auth/login`, `GET /documentos/{numero}` e `GET /arquivos/{nome}`. O token vale **30 dias** (`JWT_VALIDADE_DIAS`, RN05).
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
| 409 | `EMAIL_EM_USO`, `DOCUMENTO_EM_USO`, `DOACAO_NAO_EDITAVEL`, `DOACAO_NAO_CANCELAVEL`, `LIMITE_DE_FOTOS`, `DOACAO_INDISPONIVEL`, `RESERVA_NAO_ATIVA` | o estado atual não permite |
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
| POST | `/doacoes` | doador | 2 ✅ |
| POST | `/doacoes/{id}/fotos` | doador dono | 2 ✅ |
| GET | `/doacoes?situacao=` | doador | 2 ✅ |
| GET | `/doacoes/{id}` | doador dono / ONG | 2 ✅ |
| PUT | `/doacoes/{id}` | doador dono | 2 ✅ |
| DELETE | `/doacoes/{id}` | doador dono | 2 ✅ |
| GET | `/arquivos/{nome}` | público | 2 ✅ |
| GET | `/proximas?raioKm=` | ONG | 3 ✅ |
| POST | `/reservas` | ONG | 4 ✅ |
| GET | `/reservas?situacao=` | ONG | 4 ✅ |
| GET | `/reservas/situacao-da-ong` | ONG | 4 ✅ |
| GET | `/reservas/{id}` | ONG dona | 4 ✅ |
| DELETE | `/reservas/{id}` | ONG dona | 4 ✅ |
| POST | `/reservas/{id}/confirmar` | doador dono | 4 ✅ |
| POST | `/reservas/{id}/nao-compareceu` | doador dono | 4 ✅ |
| GET | `/notificacoes?depois=` | logado | 5 ✅ |
| POST | `/notificacoes/lidas` | logado | 5 ✅ |
| GET | `/conversas` | logado | 6 ✅ |
| GET | `/conversas/{reservaId}/mensagens?depois=` | participante | 6 ✅ |
| POST | `/conversas/{reservaId}/mensagens` | participante | 6 ✅ |
| POST | `/conversas/{reservaId}/lidas` | participante | 6 ✅ |
| GET | `/comunidade/impacto` | logado | 7 ✅ |
| GET | `/comunidade/publicacoes?antesDe=` | logado | 7 ✅ |
| POST | `/comunidade/publicacoes` | logado | 7 ✅ |
| POST | `/comunidade/publicacoes/{id}/fotos` | autor | 7 ✅ |
| POST / DELETE | `/comunidade/publicacoes/{id}/apoio` | logado | 7 ✅ |
| POST | `/comunidade/publicacoes/{id}/denuncia` | logado | 7 ✅ |
| PUT | `/perfil/avisos` | logado | 7 ✅ |
| GET | `/perfil/estatisticas` | logado | 7 ✅ |

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

## Doações (doador) — etapa 2

### Objeto `Doacao`

```json
{
  "id": 1, "doadorId": 1,
  "titulo": "Frutas e verduras do dia", "descricao": null,
  "categoria": "hortifruti",
  "quantidade": 5.0, "unidade": "caixas", "pesoKg": 25.0,
  "conservacao": "ambiente", "veiculo": null,
  "validade": "2026-09-17", "preparadoEm": null,
  "janelaInicio": "2026-09-15T13:30:00.000Z", "janelaFim": "2026-09-15T20:30:00.000Z",
  "endereco": "Rua Principal, 100 - Centro", "latitude": -23.5229, "longitude": -46.188,
  "status": "disponivel", "motivoCancelamento": null,
  "criadoEm": "2026-09-15T14:30:00.000Z",
  "fotos": ["3f2a9c0d...e1.jpg"],
  "nomeDoador": "Mercado Bom Preço",
  "nomeOng": null, "prazoRetirada": null, "distanciaKm": 0.62
}
```

- `categoria`: `hortifruti`, `padaria`, `laticinios`, `mercearia`, `refeicoesProntas`, `carnesFrios`, `bebidas`, `outros`.
- `unidade`: `kg`, `unidades`, `caixas`, `pacotes`, `litros`. `conservacao`: `ambiente`, `refrigerado`, `congelado`. `veiculo`: `sacola`, `carro`, `van` (ou `null`).
- `status`: `disponivel`, `reservada`, `concluida`, `cancelada`, `expirada` (RN13).
- `fotos`: nomes dos arquivos, na ordem (até 3). A foto é baixada em `GET /arquivos/{nome}`.
- **De leitura:** `nomeDoador`, `nomeOng` e `prazoRetirada` (quando reservada) e `distanciaKm` (só em `/proximas`).

### `POST /doacoes` — `DadosNovaDoacao` → `201 {"doacao": Doacao, "ongsAvisadas": 7}`

```json
{
  "titulo": "Pães do dia", "descricao": "Retirar pela porta lateral.",
  "categoria": "padaria", "quantidade": 30, "unidade": "unidades", "pesoKg": 6,
  "conservacao": "ambiente", "veiculo": "sacola",
  "validade": "2026-09-15",
  "janelaInicio": "2026-09-15T14:30:00Z", "janelaFim": "2026-09-15T18:30:00Z",
  "declaracaoAlimentosProprios": true
}
```

Regras (`ValidadorDoacao`, RN10): só **doador** (ONG: 403); título 3–120; quantidade e peso > 0; descrição até 500; **validade ≥ hoje** no fuso `FUSO_HORARIO`; fim da retirada **depois do início e no futuro**; **declaração = true**. Refeições prontas: `preparadoEm` obrigatório, não no futuro, e `janelaFim` no máximo **4 h** depois dele. `latitude`, `longitude` e `endereco` são opcionais: sem eles, valem os do perfil. `ongsAvisadas` = quantas ONGs receberam o aviso "Doação nova" (RN11, veja Notificações). As fotos vão depois, uma por vez.

### `POST /doacoes/{id}/fotos` — *multipart*, campo `foto` → `201 Doacao`

Uma foto por requisição. Só o doador dono, enquanto a doação está `disponivel`. Até **3** (409 `LIMITE_DE_FOTOS`), **2 MB** cada, só **JPEG ou PNG**, conferido pelos primeiros bytes do arquivo e não pelo nome (400 `VALIDACAO`). O servidor salva em `PASTA_ARQUIVOS` com um nome aleatório de 32 caracteres.

### `GET /arquivos/{nome}` → bytes da foto (pública)

Pública porque o `Image.network` não manda o token, e o nome aleatório não dá para adivinhar. Só aceita nomes no formato que o servidor gera (`^[0-9a-f]{32}\.(jpg|png)$`): `../.env` responde 404. Cabeçalho `Cache-Control: public, max-age=604800, immutable`.

### `GET /doacoes?situacao=ativas|historico` → `200 {"doacoes": [Doacao]}`

As do doador logado, da mais nova para a mais antiga. **Ativas** = `disponivel` e `reservada`; **Histórico** = `concluida`, `cancelada` e `expirada`. Antes de listar, o servidor expira as doações cujo horário de retirada acabou (RN13).

### `GET /doacoes/{id}` → `200 DetalheDoacao`

```json
{"doacao": {...}, "reserva": {...}, "ong": {...}, "doador": null}
```

`reserva` é a retirada **ativa** (ou `null`). Para a ONG dona ela vem com `codigoRetirada`; para o doador, **sem** o código (RN26). O **doador** só vê as próprias e recebe `ong` (nome, selo, responsável, telefone, transporte). A **ONG** vê as que ainda pode aceitar (disponível, janela aberta, sem bloqueio RN22) **ou** a que ela mesma está retirando, e recebe `doador`. Fora disso: 404.

### `PUT /doacoes/{id}` — `DadosNovaDoacao` → `200 Doacao`

Mesmas regras do `POST`. Só enquanto `disponivel` (RN12); reservada: 409 `DOACAO_NAO_EDITAVEL`.

### `DELETE /doacoes/{id}` — corpo opcional `{"motivo": "..."}` → `204`

RN12: `disponivel` cancela sem motivo. `reservada` **exige** motivo (400 sem ele): a retirada vira `canceladaDoador`, **sem** contar desistência para a ONG, e a ONG recebe o aviso `doacaoCancelada` com o motivo. Concluída, cancelada ou expirada: 409 `DOACAO_NAO_CANCELAVEL`.

---

## Proximidade (ONG)

### `GET /proximas?raioKm=5` → `200 {"doacoes": [Doacao]}`

- Centro: a localização do **perfil** da ONG (não vem do app).
- `raioKm` opcional. Sem ele, vale o **raio salvo no perfil** (T20/T50; muda com `PUT /perfil`). Limitado a 0,5–50. Não numérico: 400.
- Só doações `disponivel` com a janela de retirada aberta (`janela_fim > agora`), com `distanciaKm`, `fotos` e `nomeDoador`, **ordenadas da mais perto para a mais longe**.
- **RN22:** não traz as doações que essa ONG está bloqueada para aceitar (`bloqueios_doacao`, depois de desistir).
- Como funciona: o banco filtra um **retângulo** ao redor da ONG (usa o índice de latitude/longitude); o service calcula a distância exata (Haversine) e tira os "cantos" fora do círculo.
- ONG suspensa (RN24) **vê** a lista; só não aceita (etapa 4).
- Doador: 403.

---

## Retiradas (reservas) — etapa 4

### Objeto `Reserva`

```json
{
  "id": 1,
  "doacaoId": 4,
  "ongId": 3,
  "status": "ativa",
  "reservadoEm": "2026-09-15T14:30:00.000Z",
  "expiraEm": "2026-09-15T15:30:00.000Z",
  "encerradaEm": null,
  "codigoRetirada": "4821",
  "contouDesistencia": false,
  "tituloDoacao": "Cestas de mercearia",
  "nomeOng": "ONG Mãos Amigas"
}
```

- `status`: `ativa`, `concluida`, `expirada`, `canceladaOng`, `canceladaDoador`.
- `codigoRetirada` (RN26) só vai para a **ONG dona**. O doador nunca recebe o código.
- `contouDesistencia`: a retirada contou para a suspensão (RN22–RN24).

### `POST /reservas` — `{"doacaoId": 1}` → `201 Reserva` ("Vou retirar")

As conferências, em ordem:

1. Expira as retiradas vencidas (RN29), sem esperar o job.
2. ONG suspensa: **409 `ONG_SUSPENSA`** (RN24).
3. Doação inexistente: 404.
4. ONG bloqueada para esta doação: **409 `ONG_BLOQUEADA_NESTA_DOACAO`** (RN22).
5. Doação não disponível ou com a janela encerrada: **409 `DOACAO_INDISPONIVEL`**.
6. Já tem `RESERVAS_SIMULTANEAS` retiradas em andamento: **409 `LIMITE_DE_RETIRADAS`** (RN25).
7. Transação com `SELECT ... FOR UPDATE` na doação + índice único `uk_reservas_uma_ativa_por_doacao`: se outra ONG ganhou a corrida, **409 `DOACAO_INDISPONIVEL`** ("Que pena! Outra ONG aceitou esta doação primeiro.") (RN20).

`expiraEm = mínimo(agora + RESERVA_MINUTOS, janelaFim)` (RN21). O código de 4 dígitos é sorteado com `Random.secure()` (RN26). Doador: 403.

### `GET /reservas?situacao=ativas|historico` → `200 {"reservas": [Reserva]}`

As da ONG logada, mais recentes primeiro. Padrão: `ativas`.

### `GET /reservas/situacao-da-ong` → `200 SituacaoDaOng`

```json
{
  "desistenciasRecentes": 2,
  "suspensaAte": null,
  "ativas": [Reserva],
  "regras": {"prazoMinutos": 60, "toleranciaMinutos": 5, "desistenciasParaSuspender": 3,
             "janelaDesistenciasDias": 30, "suspensaoHoras": 48, "retiradasSimultaneas": 2}
}
```

Usada pelo app para a faixa de retirada em andamento, o aviso "mais uma desistência e sua conta será suspensa" e os textos com os números do `.env`.

### `GET /reservas/{id}` → `200 Reserva`

Só a ONG dona (outra: 404). Tela T23.

### `DELETE /reservas/{id}` → `200 RespostaDesistencia`

```json
{"contouDesistencia": true, "desistenciasRecentes": 3, "suspensaAte": "2026-09-17T15:00:00.000Z"}
```

A ONG dona desiste e a doação volta a `disponivel`. Até `TOLERANCIA_MINUTOS` depois do aceite **não conta** nem bloqueia (RN23). Depois: conta, bloqueia a ONG para esta doação (RN22) e, na 3ª em 30 dias, suspende por 48 h (RN24; `suspensaAte` preenchido). Não ativa: 409 `RESERVA_NAO_ATIVA`.

### `POST /reservas/{id}/confirmar` — `{"codigo": "4821"}` → `200 Reserva`

Só o **doador dono** da doação (ONG: 403; outro doador: 404). Código certo: retirada e doação → `concluida` (RN27).

| Erro | Quando |
|---|---|
| 400 `VALIDACAO` | não são 4 números |
| 400 `CODIGO_INCORRETO` | código errado ("Restam N tentativas") |
| 429 `TENTATIVAS_ESGOTADAS` | 5 erros seguidos: bloqueia por 10 min |
| 409 `RESERVA_NAO_ATIVA` | já encerrada ou prazo vencido |

### `POST /reservas/{id}/nao-compareceu` → `204`

RN28: doador dono, **depois** do prazo (antes: 409 `PRAZO_NAO_ACABOU`). Mesmo efeito da expiração: a doação volta, conta desistência e bloqueia.

### Expiração automática (RN29)

Não é rota: o `ExpiracaoJob` (iniciado em `main.dart`) roda a cada 30 s. Retiradas `ativa` com `expira_em <= agora` → `expirada` com `conta_desistencia = TRUE`, a doação volta a `disponivel`, a ONG fica bloqueada para ela e a suspensão é conferida. Depois, as doações disponíveis com a janela encerrada → `expirada` (RN13). O aceite e as consultas de `/reservas` também expiram antes, para nunca deixar uma doação presa.

---

## Notificações — etapa 5

Todo aviso é **gravado** na tabela `notificacoes` pela `CentralDeNotificacoes` e entregue ao `EnviadorDePush`. Hoje o enviador é o `EnviadorPushDesligado` (não faz nada): o app busca os avisos a cada 15 s. Para o push real (Firebase), cria-se um `EnviadorFcm` e troca-se **uma linha** no `main.dart`.

### Objeto `Notificacao`

```json
{
  "id": 12,
  "tipo": "doacaoNova",
  "titulo": "Doação nova perto de você",
  "corpo": "Doação nova a 1,2 km: 30 unidades de Pães do dia — Padaria Pão Quente. Retirar até 18:00.",
  "criadoEm": "2026-09-15T15:00:00.000Z",
  "doacaoId": 4,
  "reservaId": null,
  "lida": false
}
```

`doacaoId` e `reservaId` dizem ao app qual tela abrir no toque. Os horários do texto usam `FUSO_HORARIO`.

### Quando cada aviso é criado

| `tipo` | Quem recebe | Quando |
|---|---|---|
| `doacaoNova` | ONGs da RN11 | `POST /doacoes` |
| `doacaoAceita` | doador | `POST /reservas` |
| `prazoAcabando` | ONG | `ExpiracaoJob`, quando faltam 10 min (uma vez por retirada) |
| `prazoAcabouOng` | ONG | a retirada expirou (job, aceite ou "não compareceu") |
| `prazoAcabouDoador` | doador | a retirada terminou sem retirada (expirou ou a ONG desistiu) |
| `doacaoDisponivelDeNovo` | ONGs da RN11 (menos a bloqueada) | junto com o anterior, se a janela ainda está aberta |
| `retiradaConfirmada` | doador e ONG | `POST /reservas/{id}/confirmar` |
| `doacaoCancelada` | ONG da retirada | `DELETE /doacoes/{id}` de uma reservada |
| `suspensao` | ONG | a 3ª desistência (RN24) |
| `mensagemNova` | a outra pessoa da conversa | `POST /conversas/{id}/mensagens` |
| `apoioNovo` | o autor da publicação | `POST /comunidade/publicacoes/{id}/apoio` (só o 1º apoio de cada conta) |

**Preferências (T50):** `doacaoNova` e `doacaoDisponivelDeNovo` respeitam `avisar_doacoes`; `mensagemNova`, `avisar_mensagens`; `apoioNovo`, `avisar_comunidade`. Os avisos da retirada (aceite, prazo, confirmação, cancelamento, suspensão) chegam sempre.

**RN11 — quais ONGs:** `busca_ativa = TRUE`, não suspensas, **sem bloqueio** para a doação (RN22) e com a doação **dentro do raio** salvo no perfil delas (Haversine).

### `GET /notificacoes?depois={id}` → `200 {"notificacoes": [Notificacao]}`

As do usuário logado com `id > depois`, da mais antiga para a mais nova, no máximo 50. `depois` padrão 0; não numérico: 400.

### `POST /notificacoes/lidas` — `{"ate": 12}` → `204`

Marca como lidas as do usuário logado até o id 12. Sem `ate` inteiro: 400.

---

## Chat da retirada — etapa 6

Uma conversa por retirada (o id da conversa é o **id da reserva**). Participantes: o **doador** da doação e a **ONG** da retirada (RN30); para os outros, 404. Depois que a retirada termina (concluída, expirada ou cancelada), a conversa fica **só de leitura por 7 dias** e depois some (RN31).

Os eventos da retirada também entram na conversa como **mensagens do sistema** (`autorId: null`), gravadas pela `CentralDeNotificacoes`: "ONG Mãos Amigas aceitou a doação.", "Retirada confirmada. Obrigado!", "O prazo da retirada acabou.", "A ONG desistiu da retirada.", "O doador cancelou a doação. Motivo: …". O texto não leva a hora: o app mostra a hora da mensagem no fuso do celular.

### Objeto `Mensagem`

```json
{"id": 7, "reservaId": 3, "autorId": 4, "texto": "Estou a caminho",
 "criadoEm": "2026-09-15T14:12:00.000Z", "lidaEm": null}
```

### `GET /conversas` → `200 {"conversas": [ResumoConversa]}`

```json
{"reservaId": 3, "doacaoId": 4, "tituloDoacao": "Cestas de mercearia",
 "nomeOutro": "Mercado Bom Preço", "naoLidas": 1, "somenteLeitura": false,
 "fotoDoacao": null, "categoria": "mercearia",
 "ultimaMensagem": "Pode entrar pelo portão lateral",
 "ultimaEm": "2026-09-15T14:13:00.000Z"}
```

A com a novidade mais recente primeiro. `naoLidas` conta as mensagens da outra pessoa ainda não lidas (as do sistema não contam).

### `GET /conversas/{reservaId}/mensagens?depois={id}` → `200 RespostaMensagens`

```json
{"mensagens": [Mensagem], "somenteLeitura": false, "lidasAte": 7}
```

Só as com id maior que `depois` (o app consulta a cada 4 s com a conversa aberta). `lidasAte` = maior id das **minhas** mensagens que a outra pessoa já leu: o app marca "✓ lida" em todas até ele.

### `POST /conversas/{reservaId}/mensagens` — `{"texto": "..."}` → `201 Mensagem`

Texto de 1 a 1000 caracteres (400 fora disso). Retirada encerrada: **409 `CHAT_SOMENTE_LEITURA`**. Cria o aviso `mensagemNova` para a outra pessoa.

### `POST /conversas/{reservaId}/lidas` → `204`

Marca como lidas as mensagens da outra pessoa.

---

## Perfil: avisos e estatísticas — etapa 7

### `PUT /perfil/avisos` — `{"doacoes": true, "mensagens": false, "comunidade": true}` → `200 Conta`

Quais avisos a pessoa quer receber (T50). O objeto `Perfil` passa a ter `"avisos": {...}`.

### `GET /perfil/estatisticas` → `200 EstatisticasDoPerfil`

```json
{"concluidas": 1, "kg": 30.0, "comparecimento": 0.5, "desistenciasRecentes": 1}
```

- **Doador:** `concluidas` = doações entregues; `kg` = soma do peso delas; os outros dois vêm `null`.
- **ONG:** `concluidas` = retiradas feitas; `kg` = kg recebidos; `comparecimento` = feitas ÷ (feitas + desistências que contaram), ou `null` se ainda não houve nenhuma; `desistenciasRecentes` = desistências nos últimos `JANELA_DESISTENCIAS_DIAS` (RN24).

---

## Comunidade — etapa 7

### Objeto `Publicacao`

```json
{
  "id": 9, "autorId": 3, "nomeAutor": "ONG Mãos Amigas", "tipoAutor": "ong",
  "verificacaoAutor": "verificada",
  "texto": "O arroz e o feijão viraram 160 refeições. Obrigado!",
  "criadoEm": "2026-09-15T14:00:00.000Z", "fotos": ["4f3c...e9.jpg"],
  "doacaoId": 4, "resumoDoacao": "Arroz e feijão — Mercado Bom Preço → ONG Mãos Amigas",
  "familiasAjudadas": 40, "refeicoes": 160, "apoios": 2, "apoiadaPorMim": false
}
```

### `GET /comunidade/impacto` → `200 Impacto`

```json
{"kgSalvos": 60.0, "doacoesConcluidas": 2, "familiasAjudadas": 65, "refeicoes": 160}
```

`kgSalvos` e `doacoesConcluidas` vêm das doações **concluídas**; `familiasAjudadas` e `refeicoes` são somas das publicações **não ocultas**.

### `GET /comunidade/publicacoes?antesDe={id}` → `200 {"publicacoes": [Publicacao]}`

20 por vez, da mais nova para a mais antiga, sem as ocultas. `antesDe=0` (padrão) = as mais novas; para a próxima página, mande o id da última recebida.

### `POST /comunidade/publicacoes` — `DadosPublicacao` → `201 Publicacao`

```json
{"texto": "...", "doacaoId": 4, "familiasAjudadas": 40, "refeicoes": 160}
```

RN40: qualquer conta publica. Texto de 1 a 1000 caracteres; números entre 0 e 100000 (400 fora disso). `doacaoId` opcional: precisa ser uma doação **concluída** da qual quem publica participou (o doador dela ou a ONG que retirou); senão 400. As fotos vão depois.

### `POST /comunidade/publicacoes/{id}/fotos` — *multipart*, campo `foto` → `201 Publicacao`

Só o autor (outro: 404). Até 3 (409 `LIMITE_DE_FOTOS`), 2 MB, JPEG ou PNG — as mesmas regras das fotos das doações (`ConferenciaDeFoto`).

### `POST` / `DELETE /comunidade/publicacoes/{id}/apoio` → `200 Publicacao`

RN41: apoiar de novo não soma (a chave `(publicacao_id, usuario_id)` impede). `DELETE` desfaz. Publicação oculta ou inexistente: 404. O primeiro apoio de cada conta avisa o autor (`apoioNovo`).

### `POST /comunidade/publicacoes/{id}/denuncia` — `{"motivo": "improprio" | "falso" | "outro"}` → `204`

RN42: uma por conta (repetir não soma). Com `DENUNCIAS_PARA_OCULTAR` (padrão 3) contas diferentes, a publicação fica **oculta** (`oculta = TRUE`): some do feed e do painel. O autor não denuncia a própria (400).

---

## Usuários do seed (`dart run tool/seed.dart`)

| id | E-mail | Tipo | Organização e situação para testar |
|---|---|---|---|
| 1 | `mercado@exemplo.com` | doador (supermercado, CNPJ) | Mercado Bom Preço: "Mantimentos não perecíveis" (120 kg), reservada |
| 2 | `padaria@exemplo.com` | doador (padaria, CNPJ) | Padaria Pão Quente: "Pão francês do dia" (4 caixas, 12 kg), disponível |
| 3 | `feirante@exemplo.com` | doador (feira, **CPF**) | Banca do Zé: sem doações; verificação pendente |
| 4 | `maosamigas@exemplo.com` | ong | ONG Mãos Amigas: retirando os mantimentos (código **4821**) e conversa no chat |
| 5 | `pratocheio@exemplo.com` | ong | Instituto Prato Cheio: **2 desistências**, uma em cada doação de exemplo (fica bloqueado nelas, RN22; o próximo aviso é "mais uma e será suspensa") |
| 6 | `suspensa@exemplo.com` | ong | Casa Esperança: **suspensa** por mais 30 h |
| 7 | `distante@exemplo.com` | ong | Associação Distante (~45 km, fora do raio) |

Os ids da tabela valem logo depois de recriar o banco com o `schema.sql`. Rodar o seed de novo apaga as linhas com `DELETE`, que **não** reinicia a contagem: os ids mudam e os tokens antigos deixam de valer (o app volta para o login).

Senha de todos: `senha123`. Os CNPJs e o CPF são fictícios (dígitos calculados pelo `ValidadorDocumento`). O seed também cria 2 publicações com foto na Comunidade (Prato Cheio e Mãos Amigas, sem doação ligada). As fotos de exemplo ficam em `tool/seed/fotos/` (`mantimentos.jpg` e `paes.jpg`); o modo Fake do app usa as mesmas, em `app/assets/exemplos/`. Token sem login: `dart run tool/gerar_token.dart <id> <doador|ong>`.
