# 11 — Backend: fundamentos do Dart Frog

> **Quem:** Pessoas 1, 2, 3 e 4 (todos que vão escrever rotas).
> **Tempo:** 2 h.
> **Pré-requisito:** Sprint 0 concluído ([10](10-sprint-0-esqueleto-funcional.md)).

Esta etapa não cria funcionalidade nova. Ela explica **como a fundação do backend funciona**, para que as etapas 12 a 15 façam sentido. Leia com o VS Code aberto em `desenvolvimento_app/backend/`.

## 1. O que é o Dart Frog

Dart Frog é um framework HTTP minimalista para Dart. Se você conhece Express (Node) ou Flask (Python), a ideia é a mesma, com uma diferença: **as rotas são definidas pelos arquivos da pasta `routes/`**.

| Arquivo | URL |
|---|---|
| `routes/index.dart` | `/` |
| `routes/auth/login.dart` | `/auth/login` |
| `routes/doacoes/index.dart` | `/doacoes` |
| `routes/doacoes/[id].dart` | `/doacoes/7`, `/doacoes/42`... (`[id]` é dinâmico) |
| `routes/reservas/[id]/retirada.dart` | `/reservas/7/retirada` |
| `routes/doacoes/_middleware.dart` | roda **antes** de todas as rotas de `routes/doacoes/` |

Cada arquivo de rota exporta uma função `onRequest`:

```dart
import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(body: {'mensagem': 'olá'});
}
```

- `RequestContext context`: tudo sobre a requisição (`context.request.method`, `context.request.headers`, corpo) e acesso às dependências (`context.read<T>()`).
- `Response`: a resposta. `Response.json(statusCode: 201, body: {...})` já converte o mapa em JSON e coloca o cabeçalho `Content-Type`.
- Rotas dinâmicas recebem o trecho da URL como parâmetro extra: `onRequest(RequestContext context, String id)`.

O comando `dart_frog dev` (tarefa **Backend: iniciar**) sobe o servidor em `http://localhost:8080` e **recarrega sozinho** quando você salva um arquivo.

> **Atenção:** o Dart Frog gera uma pasta `.dart_frog/` com o servidor "montado". Ela está no `.gitignore`. Se uma rota nova não aparecer, pare o servidor e rode de novo.

## 2. Middlewares: o que acontece antes da rota

Um **middleware** é uma função que embrulha a rota: recebe a requisição, pode fazer algo antes e depois, e decide se chama a próxima etapa. É o padrão de projeto **Decorator** / *Chain of Responsibility*.

Uma requisição `POST /doacoes` passa por:

```text
main.dart (providers: Env, Database, Relogio, TokenService, SenhaService)
  └─ routes/_middleware.dart         requestLogger → cors → tratarErros
       └─ routes/doacoes/_middleware.dart   exigirAutenticacao + provider<DoacaoService>
            └─ routes/doacoes/index.dart    onRequest
```

- `tratarErros()` (em `lib/core/http/middlewares.dart`) captura **qualquer** exceção e transforma em JSON `{"erro": {"codigo", "mensagem"}}`. Por isso as rotas e services **lançam exceções** em vez de montar respostas de erro.
- `exigirAutenticacao()` (em `lib/core/seguranca/autenticacao.dart`) lê o token `Authorization: Bearer ...`. Sem token válido, responde 401 e a rota nem roda.

## 3. Injeção de dependências com `provider`

Em vez de cada rota criar sua própria conexão com o banco, os objetos são criados **uma vez** em `main.dart` (a raiz de composição) e "pendurados" no contexto:

```dart
// main.dart (já pronto)
handler.use(provider<Database>((_) => database))
```

Qualquer rota ou middleware abaixo lê com:

```dart
final database = context.read<Database>();
```

Cada fatia faz o mesmo no **próprio** `_middleware.dart`, criando o seu Service:

```dart
// routes/doacoes/_middleware.dart (Pessoa 2 cria)
Handler middleware(Handler handler) => handler
    .use(provider<DoacaoService>((context) => DoacaoService(...)))
    .use(exigirAutenticacao());
```

> **Ordem do `.use`:** o último `.use` é o primeiro a executar. Acima, `exigirAutenticacao` roda antes; o `provider` é preguiçoso e só cria o Service quando a rota pedir `context.read<DoacaoService>()`.

## 4. As três camadas de uma fatia

```text
Rota (routes/)          "porteiro": lê HTTP, chama o Service, devolve JSON
  ↓
Service (lib/<fatia>/)  REGRAS DE NEGÓCIO: quem pode, o que é válido, estados
  ↓
Repository (lib/<fatia>/)   SQL: busca e grava no MySQL
```

Regra de ouro: **rota fina**. Uma rota bem escrita tem 5 a 10 linhas. Se você está escrevendo `if` de regra de negócio numa rota, ele pertence ao Service. Se está escrevendo SQL num Service, ele pertence ao Repository.

O Repository tem **duas partes**:

```dart
// O CONTRATO (interface): o que o Service precisa.
abstract interface class DoacaoRepository {
  Future<Doacao?> buscar(int id);
}

// A IMPLEMENTAÇÃO com MySQL.
class DoacaoRepositoryMysql implements DoacaoRepository { ... }
```

O Service depende da **interface**. Nos testes, entregamos a ele um `DoacaoRepositoryEmMemoria` e testamos as regras sem banco (princípio da **inversão de dependência**, o "D" do SOLID).

## 5. Falando com o MySQL

`Database` (em `lib/core/db/database.dart`) implementa `ExecutorSql`, com três métodos:

```dart
// SELECT → lista de linhas (Map coluna → texto)
final linhas = await db.consultar(
  'SELECT id, titulo FROM doacoes WHERE doador_id = :doador',
  {'doador': 3},
);

// INSERT → id gerado
final id = await db.inserir(
  'INSERT INTO ... VALUES (:titulo, ...)',
  {'titulo': 'Pães'},
);

// UPDATE / DELETE → linhas afetadas
final alteradas = await db.executar(
  "UPDATE doacoes SET status = 'cancelada' WHERE id = :id",
  {'id': 7},
);
```

> **Nunca** monte SQL concatenando texto (`"... WHERE id = $id"`). Use sempre `:parametro`. Isso impede **SQL Injection**, uma das falhas mais comuns da [OWASP Top 10](https://owasp.org/Top10/).

O driver devolve **tudo como texto** (`"7"`, `"-23.522900"`, `"2026-09-15 14:30:00"`). Quem converte para os modelos tipados é o `Mapeador`:

```dart
final doacao = Mapeador.doacao(linhas.first);  // Linha → Doacao
```

Para isso funcionar, o `SELECT` precisa trazer as colunas com os nomes esperados (veja o comentário no topo de `mapeador.dart`).

### Transações

Quando duas ou mais escritas precisam acontecer **juntas ou nenhuma** (criar usuário + perfil; reservar + mudar status da doação), use:

```dart
await db.transacao((t) async {
  await t.inserir('INSERT INTO usuarios ...', {...});
  await t.inserir('INSERT INTO perfis ...', {...});
}); // se qualquer linha lançar exceção, NADA é gravado (ROLLBACK)
```

### Datas

Toda data vai para o banco em **UTC**, convertida por `Datas`:

| Dart → SQL | SQL → Dart |
|---|---|
| `Datas.paraSql(instante)` → `'2026-09-15 14:30:00'` | `Datas.deSql(texto)` |
| `Datas.dataParaSql(dia)` → `'2026-09-15'` | `Datas.dataDeSql(texto)` |

E o "agora" vem do `Relogio` (`context.read<Relogio>().agora()`), nunca de `DateTime.now()`. Motivo: nos testes usamos `RelogioFixo` e "avançamos o tempo" para testar expiração em milissegundos ([ADR-010](../docs/adr/ADR-010-datas-utc-relogio.md)).

## 6. Erros: lance, não responda

| Exceção (`lib/core/erros/app_exception.dart`) | HTTP | Quando |
|---|---|---|
| `ValidacaoException('msg', detalhes: [...])` | 400 | dados inválidos |
| `NaoAutenticadoException(codigo:, mensagem:)` | 401 | sem login / token ruim |
| `SemPermissaoException()` | 403 | perfil errado (ONG tentando criar doação) |
| `NaoEncontradoException()` | 404 | não existe **ou** não é seu |
| `MetodoNaoPermitidoException()` | 405 | método HTTP não suportado na rota |
| `ConflitoException('CODIGO', 'msg')` | 409 | estado não permite (doação já reservada) |

Também: o `fromJson` dos contratos lança `FormatException` quando falta um campo, e o `tratarErros` converte em 400 automaticamente.

> **Por que 404 para "não é seu"?** Responder 403 confirma que o id existe. Com 404, quem tenta adivinhar ids de outros usuários não aprende nada.

## 7. Atalhos de requisição

`lib/core/http/requisicao.dart`:

```dart
final json = await context.lerJson();          // corpo como Map (ou 400)
final raio = context.parametroDecimal('raioKm'); // ?raioKm=5 → 5.0 (ou null)
final id = idDaRota(textoId);                   // '7' → 7 (ou 404)
```

E o usuário logado (depois do `exigirAutenticacao`):

```dart
final usuario = context.read<UsuarioAutenticado>();
usuario.id;       // 3
usuario.ehOng;    // true/false
usuario.exigirTipo(TipoUsuario.doador); // lança 403 se não for doador
```

## 8. Testando rotas antes do login existir

A Pessoa 1 está fazendo o login ao mesmo tempo que você. Para não esperar, gere um token direto:

```powershell
cd desenvolvimento_app\backend
dart run tool/gerar_token.dart 1 doador
```

Copie o token e use no `api.http` (ou troque temporariamente a linha `Authorization` pelo token). O id `1` precisa existir no banco (rode o seed).

O arquivo `api.http` tem uma requisição pronta para cada rota do projeto. Com a extensão **REST Client**, clique em *Send Request* acima de cada uma.

## 9. Testes automatizados no backend

Usamos o pacote `test`. Os testes ficam em `backend/test/`, espelhando `lib/`:

```dart
import 'package:test/test.dart';

void main() {
  test('descrição do comportamento esperado', () {
    // Arrange (prepara)  →  Act (executa)  →  Assert (verifica)
    expect(1 + 1, 2);
  });
}
```

- Rode com a tarefa **Backend: testes** ou `dart test` dentro de `backend`.
- Testamos **Services** com repositórios em memória (rápido, sem MySQL). Cada etapa 12–15 traz o seu.
- Os testes já existentes em `test/core/` (datas, mapeador, token, exceções) são exemplos.

## Checklist

- [ ] Sei explicar o caminho de uma requisição: middlewares → rota → service → repository
- [ ] Sei por que a rota lança exceção em vez de montar a resposta de erro
- [ ] Sei usar `:parametro` no SQL e por quê
- [ ] Gerei um token com `tool/gerar_token.dart` e chamei `GET /` pelo `api.http`
- [ ] Rodei a tarefa **Backend: testes** e tudo passou

Próximo: a etapa da sua fatia — [12](12-backend-autenticacao.md) (P1), [13](13-backend-doacoes.md) (P2), [14](14-backend-proximidade.md) (P4), [15](15-backend-reservas.md) (P3).
