# desenvolvimento_app — todo o código do projeto

É aqui que se programa. A documentação fica em [`../docs/`](../docs/00-indice.md), o passo a passo em [`../trilha/`](../trilha/README.md) e os scripts de banco em [`../database/`](../database/README.md).

## Os três pacotes

```text
desenvolvimento_app/
├── shared_models/   modelos, contratos da API e validações (Dart puro, usado pelos dois lados)
├── backend/         a API (Dart Frog + MySQL 8.4)        → README em backend/README.md
└── app/             o aplicativo (Flutter, MVVM)          → README em app/README.md
```

> Os três ficam lado a lado de propósito: `app` e `backend` usam `shared_models` pelo caminho `../shared_models`. Não mova as pastas.

## Primeira vez

No VS Code: `Ctrl+Shift+P` → *Tasks: Run Task* → **Tudo: baixar dependências (pub get)**. Ou, no terminal, a partir desta pasta:

```powershell
cd shared_models; dart pub get; cd ..\backend; dart pub get; cd ..\app; flutter pub get; cd ..
```

Antes de rodar o backend: banco criado (`database/schema.sql` + `criar_usuario.sql`) e `backend/.env` preenchido ([trilha/10](../trilha/10-sprint-0-esqueleto-funcional.md), passos 4 e 5).

## Rodar

| O quê | Como |
|---|---|
| Dados de exemplo | tarefa **Backend: recriar dados de exemplo (seed)** |
| API | tarefa **Backend: iniciar (dart_frog dev)** → <http://localhost:8080/> |
| App sem backend | *Run and Debug* → **App — dados fictícios (sem backend)** |
| App com a API | *Run and Debug* → **App — API local (emulador)** |
| Tudo antes do PR | tarefa **Tudo: verificar antes do PR (format + analyze + test)** |

## Onde cada pessoa cria arquivos

| Pessoa | Backend | App | Etapas |
|---|---|---|---|
| 1 — Autenticação | `backend/lib/auth/`, `backend/routes/auth/`, `backend/test/auth/` | `app/lib/features/auth/presentation/` (login e cadastro), `app/test/features/auth/` | [12](../trilha/12-backend-autenticacao.md), [17](../trilha/17-app-autenticacao.md) |
| 2 — Doador | `backend/lib/doacoes/`, `backend/routes/doacoes/`, `backend/test/doacoes/` | `app/lib/features/doador/presentation/`, `app/test/features/doador/` | [13](../trilha/13-backend-doacoes.md), [18](../trilha/18-app-doador.md) |
| 3 — Reservas | `backend/lib/reservas/`, `backend/routes/reservas/`, `backend/test/reservas/` (+ bloco do job em `backend/main.dart`) | (dupla com a 5) | [15](../trilha/15-backend-reservas.md) |
| 4 — Infra e mapa | `backend/lib/proximidade/`, `backend/routes/proximas/`, `backend/test/proximidade/` | `app/lib/features/mapa/presentation/`, `app/test/features/mapa/` | [10](../trilha/10-sprint-0-esqueleto-funcional.md), [14](../trilha/14-backend-proximidade.md), [20](../trilha/20-app-mapa.md) |
| 5 — ONG | — | `app/lib/features/ong/presentation/`, `app/test/features/ong/` | [19](../trilha/19-app-ong.md) |

Guia pessoal de cada um: [`../00_COMECE_AQUI/pessoas/`](../00_COMECE_AQUI/README.md).

## Arquivos de fundação (não editar sem combinar)

- `shared_models/**` (dono: Pessoa 1)
- `backend/main.dart`, `backend/routes/_middleware.dart`, `backend/routes/index.dart`, `backend/lib/core/**`, `backend/tool/**`
- `app/lib/main.dart`, `app/lib/app.dart`, `app/lib/core/**`, `app/lib/data/**`, `app/lib/shared/**`
- todos os `pubspec.yaml` e `pubspec.lock`
- os **construtores** das páginas (são o contrato com o `AppRouter`)

Mapa completo de arquivos: [docs/06](../docs/06-estrutura-projeto.md).
