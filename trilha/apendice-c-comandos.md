# Apêndice C — Comandos rápidos

Cola para consultar no dia a dia. Todos os comandos são para o **PowerShell** (terminal do VS Code: `` Ctrl+` ``). Quando estiver escrito "em `backend`", entre antes na pasta: `cd desenvolvimento_app\backend`.

## VS Code

| Quero... | Atalho / caminho |
|---|---|
| Abrir o terminal | `` Ctrl+` `` |
| Rodar uma tarefa pronta | `Ctrl+Shift+P` → *Tasks: Run Task* |
| Rodar o app (escolher o perfil) | `Ctrl+Shift+D` → escolha → `F5` |
| Parar o app | `Shift+F5` |
| Hot reload (aplicar mudança no app rodando) | salvar o arquivo (`Ctrl+S`) ou `r` no terminal |
| Procurar em todos os arquivos | `Ctrl+Shift+F` |
| Abrir um arquivo pelo nome | `Ctrl+P` |
| Formatar o arquivo | `Shift+Alt+F` |
| Ver os erros | `Ctrl+Shift+M` (aba *Problems*) |
| Abrir o emulador | `Ctrl+Shift+P` → *Flutter: Launch Emulator* |

## Tarefas prontas (`.vscode/tasks.json`)

| Tarefa | O que faz |
|---|---|
| **Tudo: baixar dependências (pub get)** | `pub get` nos três pacotes |
| **Tudo: verificar antes do PR (format + analyze + test)** | formata, analisa e testa tudo; rode **antes de todo PR** |
| **Backend: iniciar (dart_frog dev)** | sobe a API em `http://127.0.0.1:8080` |
| **Backend: recriar dados de exemplo (seed)** | apaga os dados e cria os usuários/doações de exemplo |
| **Backend: testes** · **App: testes** · **Modelos: testes** | testes de cada pacote |

## Git (o ciclo de toda tarefa)

```powershell
git switch main                      # 1. volta para a main
git pull                             # 2. pega o que os colegas mesclaram
git switch -c feat/12-login-backend  # 3. cria a sua branch
# ... programa ...
git status                           # 4. o que mudou?
git add <pastas da sua fatia>        # 5. escolhe o que vai no commit
git commit -m "feat(auth): rota de login"
git push -u origin feat/12-login-backend   # 6. envia (depois do 1º, só "git push")
# 7. abre o PR no GitHub
```

| Situação | Comando |
|---|---|
| Ver o histórico resumido | `git log --oneline --graph -15` |
| Desfazer mudanças **não commitadas** de um arquivo | `git restore caminho\do\arquivo.dart` |
| Tirar um arquivo do `git add` | `git restore --staged caminho\do\arquivo.dart` |
| Corrigir a mensagem do último commit (antes do push) | `git commit --amend -m "nova mensagem"` |
| Trazer a `main` nova para a sua branch | `git switch main; git pull; git switch -; git merge main` |
| Guardar mudanças para depois | `git stash` e, para voltar, `git stash pop` |
| Ver em qual branch estou | `git branch --show-current` |

> **Nunca** use `git push --force` na `main`. Conflito de merge? Veja a [trilha/04](04-git-e-github-do-zero.md).

## Backend (em `backend`)

| Quero... | Comando |
|---|---|
| Subir a API | `dart_frog dev` |
| Criar o `.env` | `Copy-Item .env.example .env` |
| Gerar um segredo JWT | `-join ((48..57)+(65..90)+(97..122) \| Get-Random -Count 48 \| ForEach-Object {[char]$_})` |
| Recriar os dados de exemplo | `dart run tool/seed.dart` |
| Token de teste sem login | `dart run tool/gerar_token.dart 1 doador` · `dart run tool/gerar_token.dart 3 ong` |
| Testes | `dart test` |
| Um teste só | `dart test test/reservas/reserva_service_test.dart` |
| Análise e formatação | `dart analyze` · `dart format .` |

**Ids do seed:** 1 = Mercado (doador), 2 = Padaria (doador), 3 = Mãos Amigas (ONG), 4 = Prato Cheio (ONG), 5 = Distante (ONG, fora do raio). Senha de todos: `senha123`.

## App (em `app`)

| Quero... | Comando |
|---|---|
| Baixar pacotes | `flutter pub get` |
| Rodar no modo Fake | `flutter run --dart-define=USAR_FAKE=true` |
| Rodar com a API (emulador) | `flutter run --dart-define=API_URL=http://10.0.2.2:8080` |
| Rodar no Chrome | `flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:8080` |
| Ver aparelhos conectados | `flutter devices` |
| Testes | `flutter test` |
| Cobertura | `flutter test --coverage` |
| Análise | `flutter analyze` |
| Formatar | `dart format lib test` |
| "Limpar" quando algo estranho acontece | `flutter clean; flutter pub get` |
| Conferir a instalação | `flutter doctor -v` |
| Gerar APK | `flutter build apk --release --dart-define=USAR_FAKE=true` |

## Banco (MySQL Workbench)

| Quero... | Como |
|---|---|
| Recriar as tabelas do zero | *File → Open SQL Script* → `database/schema.sql` → raio ⚡ |
| Criar o usuário do backend | `database/criar_usuario.sql` (uma vez) |
| Apagar só os dados | `database/limpar_dados.sql` |
| Consultas prontas | `database/consultas_uteis.sql` |
| O serviço do MySQL caiu | `Win+R` → `services.msc` → **MySQL84** → *Iniciar* |

```sql
USE summit;
SELECT id, email, tipo FROM usuarios;
SELECT id, titulo, status, janela_fim FROM doacoes ORDER BY id DESC;
SELECT id, doacao_id, ong_id, status, expira_em FROM reservas ORDER BY id DESC;
```

## Endereços

| O quê | Endereço |
|---|---|
| API no próprio PC | <http://localhost:8080/> |
| API vista pelo emulador Android | `http://10.0.2.2:8080` |
| API vista por um celular na mesma rede | `http://<IPv4 do PC>:8080` (`ipconfig`) + `ESCUTAR_NA_REDE=true` |

Mais problemas e soluções: [docs/22-troubleshooting.md](../docs/22-troubleshooting.md).
