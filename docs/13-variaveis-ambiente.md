# 13 — Variáveis de ambiente e configuração

Duas regras ([ADR-012](adr/ADR-012-configuracao-dotenv-dart-define.md)):

1. **Backend:** arquivo `desenvolvimento_app/backend/.env` (lido pela classe `Env` com o pacote `dotenv`). Ele tem senhas e **nunca vai para o Git**. O modelo, sem segredos, é o `.env.example`.
2. **App:** nenhum segredo. Só o endereço da API e o modo Fake, passados na compilação com `--dart-define`.

## Backend (`.env`)

Criar: `cd desenvolvimento_app\backend` e `Copy-Item .env.example .env`. Se a mesma variável existir no sistema operacional (ex.: na CI), o valor do sistema vence.

| Variável | Obrigatória | Padrão | Para quê |
|---|---|---|---|
| `DB_HOST` | não | `127.0.0.1` | servidor MySQL |
| `DB_PORTA` | não | `3306` | porta |
| `DB_NOME` | não | `summit` | banco |
| `DB_USUARIO` | **sim** | — | `summit_app` (criado pelo `criar_usuario.sql`) |
| `DB_SENHA` | **sim** | — | a mesma do `criar_usuario.sql` |
| `DB_TLS` | não | `true` | conexão segura, exigida pelo login padrão do MySQL 8.4 |
| `JWT_SEGREDO` | **sim** | — | segredo que assina os tokens; **mínimo 32 caracteres**, cada pessoa gera o seu |
| `JWT_VALIDADE_HORAS` | não | `12` | validade do token |
| `RESERVA_MINUTOS` | não | `120` | prazo da reserva (use `2` para demonstrar a expiração) |
| `RAIO_PADRAO_KM` | não | `10` | raio de `GET /proximas` sem `raioKm` |
| `FUSO_HORARIO` | não | `-3` | horas de diferença para o UTC, para decidir "hoje" (Brasília = -3) |
| `CORS_ORIGEM` | não | `*` | só importa com o app no Chrome |
| `ESCUTAR_NA_REDE` | não | `false` | `true` aceita conexões da rede local (celular físico) |

Gerar o `JWT_SEGREDO` no PowerShell:

```powershell
-join ((48..57)+(65..90)+(97..122) | Get-Random -Count 48 | ForEach-Object {[char]$_})
```

Se faltar uma variável obrigatória ou algum valor for inválido, o backend **não sobe** e a mensagem diz o que corrigir (ex.: `A variável DB_SENHA não está definida. Você criou o arquivo .env?`).

## App (`--dart-define`)

| Variável | Padrão | Exemplos |
|---|---|---|
| `API_URL` | `http://10.0.2.2:8080` | emulador: `http://10.0.2.2:8080` · Chrome: `http://127.0.0.1:8080` · celular: `http://192.168.0.10:8080` |
| `USAR_FAKE` | `false` | `true` = dados em memória, sem backend |

Os perfis do VS Code (`.vscode/launch.json`) já passam esses valores:

| Perfil | Valores |
|---|---|
| App — dados fictícios (sem backend) | `USAR_FAKE=true` |
| App — API local (emulador) | `API_URL=http://10.0.2.2:8080` |
| App — API local (celular físico) | `API_URL=http://<IP do PC>:8080` (edite o IP) |
| App — Chrome (API local) | `API_URL=http://127.0.0.1:8080` |

> **Por que `10.0.2.2`?** Dentro do emulador, `127.0.0.1` é o próprio emulador. O endereço especial `10.0.2.2` aponta para o computador que roda o emulador.

Outras configurações fixas do app ficam em `lib/core/config/app_config.dart` (`nomeApp`, `intervaloAtualizacao`, `identificadorApp`).
