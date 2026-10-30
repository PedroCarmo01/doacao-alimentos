# 10 — Sprint 0: esqueleto funcional

> **Quem:** líder do grupo + Pessoa 4 (infra). Os outros acompanham por chamada de vídeo e depois repetem os passos 4 a 9 na própria máquina.
> **Tempo:** 1 dia.
> **Resultado:** o repositório no GitHub com a **fundação** (código-base que já existe nesta pasta) rodando de ponta a ponta: app → API → banco. Tag `v0.1.0`.

## Por que começar por um "esqueleto"?

Um **walking skeleton** (esqueleto que anda) é a menor versão do sistema que já liga todas as camadas: a tela inicial do app chama `GET /` da API, que faz um `SELECT 1` no MySQL e responde "ok". Nenhuma funcionalidade de negócio existe ainda, mas:

- Todos os problemas de ambiente (Flutter, MySQL, rede do emulador, `.env`) aparecem **no primeiro dia**, e não na véspera da entrega.
- Cada pessoa passa a trabalhar **dentro de uma estrutura que já compila**, só preenchendo os arquivos da própria fatia.
- O primeiro commit é pequeno e revisável. O código de cada fatia entra depois, por PRs de cada autor, e o histórico do GitHub mostra a contribuição de cada um (o professor vai olhar isso).

> **Por quê?** Se alguém colocasse o projeto inteiro no primeiro commit, o GitHub mostraria uma única pessoa como autora de tudo. Ver [ADR-011](../docs/adr/ADR-011-walking-skeleton-fatias-fakes.md).

## O que já existe nesta pasta

| Pasta | Conteúdo | Situação |
|---|---|---|
| `desenvolvimento_app/shared_models/` | Modelos, contratos, validações, relógio, geo | **Pronto**, com testes |
| `desenvolvimento_app/backend/` | Fundação do Dart Frog: `main.dart`, `lib/core/*`, `routes/index.dart`, `tool/seed.dart` | **Pronto**; as rotas de negócio são das fatias |
| `desenvolvimento_app/app/` | `lib/` e `test/` do Flutter (MVVM, Fakes, rotas, widgets) | Falta gerar a pasta `android/` (passo 3) |
| `database/` | `schema.sql`, `criar_usuario.sql` etc. | **Pronto** |
| `.vscode/`, `.github/` | Tarefas, perfis de execução, CI, templates | **Pronto** |

Nada disso foi executado ainda: o primeiro `pub get`/`flutter test` acontece neste Sprint. Se aparecer erro de compilação, corrija no próprio PR do Sprint 0 (ver [22-troubleshooting](../docs/22-troubleshooting.md)).

---

## Passo 1 — Criar o repositório no GitHub (líder)

1. Em <https://github.com/new>: nome `doacao-alimentos` (ou o combinado), **Private** (o professor é adicionado depois), **sem** README, `.gitignore` ou licença (já temos).
2. Em *Settings → Collaborators*, convide as 4 pessoas.
3. Abra a pasta do projeto no VS Code (*File → Open Folder...*), abra o terminal (`` Ctrl+` ``) e rode:

```powershell
git init -b main
git add .gitignore .gitattributes
git commit -m "chore: configura gitignore e gitattributes"
```

> **Por quê commitar os dois primeiro?** O `.gitattributes` define o fim de linha (LF) antes de qualquer outro arquivo entrar no Git. Assim não aparece "o arquivo inteiro mudou" entre Windows e o CI (Linux).

Confira que **não** vão para o Git: qualquer `.env`, `build/`, `.dart_tool/`. Rode `git status --ignored` e veja se eles aparecem na seção *Ignored files*.

## Passo 2 — Personalizar o CODEOWNERS

Abra `.github/CODEOWNERS` e troque `@lider-usuario`, `@pessoa1-usuario` ... `@pessoa5-usuario` pelos usuários reais do GitHub. Isso faz o GitHub pedir revisão automaticamente para o dono de cada pasta.

## Passo 3 — Gerar a parte Android do app

A pasta `app/` tem só o código Dart. Os arquivos nativos (Gradle, `AndroidManifest.xml`) são gerados pelo próprio Flutter, na versão instalada na máquina, para não ficarem desatualizados.

```powershell
cd desenvolvimento_app\app
flutter create . --org br.edu.umc --project-name summit_app --platforms android
```

O `flutter create .` **não sobrescreve** arquivos que já existem (`lib/`, `pubspec.yaml`, `README.md`, `analysis_options.yaml`). Ele cria `android/`, `.metadata` e um teste de exemplo que **não serve** para o nosso app. Apague-o:

```powershell
Remove-Item test\widget_test.dart
```

> O identificador final do app fica `br.edu.umc.summit_app` (igual a `AppConfig.identificadorApp`). "summit" é só o nome técnico do pacote, herdado do evento; o nome que aparece na tela é `AppConfig.nomeApp`.

### 3.1 Permissões (AndroidManifest)

Abra `android/app/src/main/AndroidManifest.xml` e adicione, **antes** da tag `<application`:

```xml
<!-- Acesso à API -->
<uses-permission android:name="android.permission.INTERNET" />
<!-- GPS: cadastro (localização da organização) e mapa -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Ainda no `<application ...>`, troque `android:label="summit_app"` por `android:label="Doação de Alimentos"`.

### 3.2 Permitir HTTP só em desenvolvimento

O Android bloqueia `http://` (sem S) por padrão. Em desenvolvimento a API roda em `http://10.0.2.2:8080`, então liberamos **apenas no build de debug**. Abra `android/app/src/debug/AndroidManifest.xml` (já existe) e deixe assim:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- Só no DEBUG: permite http:// para a API local. O build de release
         continua exigindo https (seguro por padrão). -->
    <application android:usesCleartextTraffic="true" />
</manifest>
```

### 3.3 Versão mínima do Android

Abra `android/app/build.gradle.kts` e procure `minSdk = flutter.minSdkVersion`. Só se o build reclamar de `minSdk` (o `flutter_secure_storage` e o `geolocator` exigem versões recentes), troque por:

```kotlin
minSdk = 23
```

## Passo 4 — Banco de dados (cada pessoa, na própria máquina)

Siga [08 — Banco de dados passo a passo](08-banco-de-dados-passo-a-passo.md), seções "Criando o banco": rode `database/schema.sql` e depois `database/criar_usuario.sql` no MySQL Workbench como `root`.

## Passo 5 — Configurar o backend (cada pessoa)

```powershell
cd desenvolvimento_app\backend
Copy-Item .env.example .env
```

Abra o `.env` e preencha `JWT_SEGREDO` com um texto aleatório. Gere no PowerShell:

```powershell
-join ((48..57)+(65..90)+(97..122) | Get-Random -Count 48 | ForEach-Object {[char]$_})
```

Confira se `DB_SENHA` é a mesma senha usada no `criar_usuario.sql`.

## Passo 6 — Baixar dependências e rodar os testes

No VS Code: `Ctrl+Shift+P` → *Tasks: Run Task* → **Tudo: baixar dependências (pub get)**.

Ela roda `dart pub get` em `shared_models` e `backend` e `flutter pub get` em `app`. Depois rode a tarefa **Tudo: verificar antes do PR (format + analyze + test)**. Tudo precisa passar.

> Se o `dart format` alterar arquivos, é normal na primeira vez: ele ajusta o estilo para a versão do SDK instalada. Revise e commit junto.

## Passo 7 — Dados de exemplo e API no ar

Tarefa **Backend: recriar dados de exemplo (seed)** (ou `dart run tool/seed.dart` dentro de `backend`). Ela cria 2 doadores, 3 ONGs e algumas doações em Mogi das Cruzes, todos com a senha `senha123`.

Depois, tarefa **Backend: iniciar (dart_frog dev)**. Quando aparecer `API rodando em http://127.0.0.1:8080`, abra no navegador <http://localhost:8080/>. O esperado:

```json
{"servico":"api-doacao-alimentos","status":"ok","banco":"conectado","horario":"2026-09-15T14:30:00.000Z"}
```

Se vier `"banco":"indisponivel"`, a API está no ar, mas não alcança o MySQL: confira o `.env` e o serviço `MySQL84` (ver [docs/22-troubleshooting](../docs/22-troubleshooting.md)).

## Passo 8 — Rodar o app

1. Abra o emulador (*Ctrl+Shift+P → Flutter: Launch Emulator*).
2. Na aba *Run and Debug* (`Ctrl+Shift+D`), escolha **App — dados fictícios (sem backend)** e aperte `F5`. A tela inicial deve mostrar os dois botões e *Modo demonstração (dados fictícios)*.
3. Pare (`Shift+F5`), escolha **App — API local (emulador)** e rode de novo, com o backend ligado. Agora o rodapé deve mostrar o servidor online.

Os botões levam a telas "Em construção": cada uma mostra quem é o responsável e qual etapa da trilha implementa. Isso é o esperado no Sprint 0.

## Passo 9 — Primeiro push e tag

```powershell
cd <raiz do projeto>
git add .
git status            # confira: nada de .env ou build/
git commit -m "chore: esqueleto funcional (sprint 0)"
git remote add origin https://github.com/<usuario>/doacao-alimentos.git
git push -u origin main
git tag -a v0.1.0 -m "Sprint 0: esqueleto funcional"
git push origin v0.1.0
```

> **Vão para o Git, sim:** `pubspec.lock` (garante as mesmas versões para todos) e `app/.metadata` (versão do Flutter que gerou o `android/`).

## Passo 10 — Proteger a branch `main` (líder)

Em *Settings → Branches → Add branch ruleset* (ou *Add rule*) para `main`:

- [x] Require a pull request before merging (1 aprovação)
- [x] Require status checks to pass → selecione os três jobs do CI (`shared_models`, `backend`, `app`). Eles só aparecem na lista depois que o CI rodou pelo menos uma vez.
- [x] Block force pushes

Em *Settings → General → Pull Requests*, deixe **só** *Allow squash merging* marcado. Cada PR vira um commit limpo na `main`, com o autor preservado.

## Passo 11 — Os colegas clonam

Cada pessoa:

```powershell
cd $HOME\Documents
git clone https://github.com/<usuario>/doacao-alimentos.git
code doacao-alimentos
```

E repete os passos 4 a 8. O Sprint 0 só termina quando **as cinco máquinas** mostram `"banco":"conectado"` e o app abre no emulador.

---

## Checklist do Sprint 0

- [ ] Repositório criado, 5 colaboradores, `main` protegida, squash merge
- [ ] `CODEOWNERS` com os usuários reais
- [ ] `android/` gerado, permissões e cleartext (só debug) configurados
- [ ] `test/widget_test.dart` gerado pelo Flutter apagado
- [ ] Tarefa "verificar antes do PR" passa em todas as máquinas
- [ ] `GET /` responde `"banco":"conectado"` em todas as máquinas
- [ ] App abre nos modos Fake e API
- [ ] CI verde no GitHub (aba *Actions*)
- [ ] Tag `v0.1.0` publicada
- [ ] Quadro do GitHub Projects com as issues das fatias ([02](02-processo-e-planejamento.md))

Próximo: [11 — Backend: fundamentos do Dart Frog](11-backend-fundamentos.md) (quem mexe no backend) ou [16 — App: fundamentos](16-app-fundamentos.md) (quem mexe no app).
