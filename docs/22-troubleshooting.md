# 22 — Troubleshooting

Formato: **sintoma → causa provável → solução**. Use `Ctrl+F` com um pedaço da mensagem de erro. Cada etapa da trilha também tem uma tabela "O que pode dar errado" com os problemas específicos dela.

## Instalação e ambiente

| Sintoma | Causa | Solução |
|---|---|---|
| `flutter` / `dart` não é reconhecido | PATH sem o Flutter, ou terminal aberto antes da instalação | Feche e abra o VS Code. Confira o PATH ([trilha/03](../trilha/03-ambiente-windows-vscode.md)) |
| `dart_frog` não é reconhecido | pasta de executáveis do Dart fora do PATH | Adicione `%LOCALAPPDATA%\Pub\Cache\bin` ao PATH do usuário; rode de novo `dart pub global activate dart_frog_cli` |
| `flutter doctor` reclama das licenças | licenças do Android não aceitas | `flutter doctor --android-licenses` e responda `y` |
| `flutter doctor`: Android SDK não encontrado | Android Studio não instalado ou sem SDK | Instale o Android Studio e abra uma vez (*More Actions → SDK Manager*) |
| `The current Dart SDK version is X... requires ^3.9.0` | Flutter antigo | `flutter upgrade` |
| Emulador muito lento ou não abre | pouca RAM / virtualização desligada | Feche o Chrome; habilite virtualização na BIOS; ou use celular físico ou `flutter run -d chrome` |
| PowerShell: "execução de scripts foi desabilitada" | política do Windows | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| App fecha sozinho logo ao abrir no emulador (logcat: `SIGSEGV` no thread `1.raster`) | driver de vídeo do emulador depois de voltar de um *snapshot* | Feche o emulador e ligue **do zero**: Device Manager → ⋮ → **Cold Boot Now** (ou `emulator -avd Pixel_7 -no-snapshot-load`). Visto na etapa 2; não é erro do código |
| Gradle: "Android sdkmanager did not install NDK" | o `sdkmanager` virou o novo *Android CLI* | `android sdk install ndk/28.2.13676358` (o executável fica em `Android\sdk\cmdline-tools\latest\bin`) |

## Dependências e compilação

| Sintoma | Causa | Solução |
|---|---|---|
| `pub get` falha com conflito de versão | alguém alterou um `pubspec.yaml` | `git pull`; não mude pacotes sem combinar; use o `pubspec.lock` da `main` |
| `Target of URI doesn't exist: 'package:summit_backend/...'` | `pub get` não rodado, ou arquivo ainda não criado | Tarefa **Tudo: baixar dependências**; confira o nome e o caminho do arquivo |
| CI falha em "format" mas na sua máquina passa | não rodou o formatador | Tarefa **Tudo: verificar antes do PR** e commit de novo |
| Algo estranho depois de trocar de branch (app) | cache antigo | `flutter clean; flutter pub get` |
| Rota nova do backend responde 404 | o `dart_frog dev` não viu a pasta nova | Pare (`Ctrl+C`) e inicie de novo |

## Banco de dados

| Sintoma | Causa | Solução |
|---|---|---|
| `"banco":"indisponivel"` no `GET /` | MySQL parado ou `.env` errado | `services.msc` → **MySQL84** → Iniciar; confira `DB_*` no `.env` |
| `Access denied for user 'summit_app'` | senha do `.env` ≠ senha do `criar_usuario.sql` | Rode o `ALTER USER` (fim do `criar_usuario.sql`) e atualize `DB_SENHA` |
| `Unknown database 'summit'` | schema não rodado | Rode `database/schema.sql` no Workbench |
| Erro de autenticação / SSL ao conectar | `DB_TLS=false` com MySQL 8.4 | Deixe `DB_TLS=true` |
| Porta 3306 em uso | outro MySQL/XAMPP | Pare o outro serviço, ou mude a porta e o `DB_PORTA` |
| `A coluna "x" não veio na consulta` | `SELECT` sem a coluna ou o alias esperado pelo `Mapeador` | Compare com o comentário no topo de `lib/core/db/mapeador.dart` |
| `Duplicate entry ... uk_reservas_uma_ativa_por_doacao` | segunda reserva ativa da mesma doação | É a regra funcionando ([12](12-partes-complexas.md)) |
| `Check constraint 'ck_doacoes_janela' is violated` | janela termina antes de começar | Corrija os dados enviados |
| Login do seed não funciona | seed não rodado depois de recriar o banco | Tarefa **Backend: recriar dados de exemplo (seed)** |

## Backend

| Sintoma | Causa | Solução |
|---|---|---|
| `A variável JWT_SEGREDO não está definida` | `.env` não criado ou vazio | `Copy-Item .env.example .env` e preencha ([13](13-variaveis-ambiente.md)) |
| `JWT_SEGREDO deve ter pelo menos 32 caracteres` | segredo curto | Gere com o comando do `.env.example` |
| `Port 8080 already in use` | outro `dart_frog dev` aberto | Feche o terminal antigo (lixeira no painel de terminais) |
| 401 em todas as rotas | token ausente, de outro `.env` ou expirado | Faça login de novo; tokens do `gerar_token.dart` só valem com o mesmo `JWT_SEGREDO` |
| 500 `ERRO_INTERNO` | bug no código | Leia o terminal do backend: a pilha mostra arquivo e linha |
| Reserva nunca expira | job não ligado no `main.dart` | [trilha/15](../trilha/15-backend-reservas.md), passo 5 |

## App

| Sintoma | Causa | Solução |
|---|---|---|
| "Não foi possível falar com o servidor" (emulador) | backend parado ou URL com `localhost` | Inicie o backend; use o perfil **App — API local (emulador)** (`10.0.2.2`) |
| Não conecta no celular físico | `ESCUTAR_NA_REDE=false`, IP errado, redes diferentes ou firewall | `ESCUTAR_NA_REDE=true`; IP do `ipconfig`; mesma Wi-Fi; permita o `dart.exe` no Firewall do Windows (*Permitir um aplicativo pelo Firewall*) |
| `Cleartext HTTP traffic not permitted` | build de release com `http://` | Use o build de debug para a API local ([trilha/10](../trilha/10-sprint-0-esqueleto-funcional.md), passo 3.2) |
| "Rota não encontrada no servidor (ela já foi implementada?)" | o backend daquela fatia ainda não foi mesclado | Use o modo Fake por enquanto |
| Acentos quebrados ("DoaÃ§Ã£o") | resposta decodificada sem UTF-8 | Use sempre o `ApiClient` (nunca `http.get` direto) |
| Horários 3 h errados | instante UTC mostrado sem converter | `Formatador.diaHora(...)` |
| GPS na Califórnia | emulador sem posição | *Extended controls (⋯) → Location* → `-23.5235, -46.1870` → *Set location* |
| Mapa todo cinza | sem internet no emulador ou sem `userAgentPackageName` | Teste o Chrome do emulador; mantenha o `TileLayer` da [trilha/20](../trilha/20-app-mapa.md) |
| Tela não atualiza | faltou `ListenableBuilder` ou `executar` dentro de `executar` | [trilha/16](../trilha/16-app-fundamentos.md), seção 3 |

## Git

| Sintoma | Causa | Solução |
|---|---|---|
| `rejected ... fetch first` no push | a branch remota tem commits que você não tem | `git pull` e depois `git push` |
| Conflito de merge | duas pessoas mudaram as mesmas linhas | [trilha/04](../trilha/04-git-e-github-do-zero.md); na dúvida, chame o dono do arquivo |
| Commitei o `.env` | `git add .` sem conferir | `git rm --cached desenvolvimento_app/backend/.env`, commit, e **troque os segredos** ([17](17-seguranca.md)) |
| Commitei na `main` sem querer (antes do push) | esqueceu de criar a branch | `git switch -c feat/minha-branch` (leva o commit junto); depois `git switch main; git reset --hard origin/main` |
| "Author identity unknown" | nome/e-mail não configurados | `git config --global user.name "Seu Nome"` e `user.email` |

## Quando nada disso resolver

1. Leia a mensagem de erro **inteira** (a causa costuma estar na primeira linha que menciona um arquivo **seu**).
2. Repita o passo mínimo que causa o erro.
3. Pesquise a mensagem exata (entre aspas).
4. Peça ajuda no grupo com: o que você tentou, o comando exato, a mensagem completa e um print.
