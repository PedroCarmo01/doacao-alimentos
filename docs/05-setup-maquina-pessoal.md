# 05 — Setup da máquina pessoal

O passo a passo de instalação foi movido para a **trilha**, onde cada etapa tem explicação, prints de referência e checklist:

1. **[trilha/03 — Ambiente no Windows com VS Code](../trilha/03-ambiente-windows-vscode.md)** — Git, VS Code, Flutter, Android (emulador ou celular), Dart Frog, MySQL 8.4 e Workbench.
2. **[trilha/04 — Git e GitHub do zero](../trilha/04-git-e-github-do-zero.md)** — configurar nome/e-mail, clonar, branch, commit, PR.
3. **[trilha/10 — Sprint 0](../trilha/10-sprint-0-esqueleto-funcional.md)**, passos 4 a 8 — criar o banco, o `.env`, baixar dependências, rodar o seed, a API e o app.

## Resumo para quem já tem tudo instalado

```powershell
git clone https://github.com/<usuario>/<repositorio>.git
cd <repositorio>
code .
```

No VS Code:

1. MySQL Workbench: rodar `database/schema.sql` e `database/criar_usuario.sql` (como root).
2. `cd desenvolvimento_app\backend` e `Copy-Item .env.example .env`; preencher `DB_SENHA` e `JWT_SEGREDO`.
3. Tarefa **Tudo: baixar dependências (pub get)**.
4. Tarefa **Backend: recriar dados de exemplo (seed)**.
5. Tarefa **Backend: iniciar (dart_frog dev)** → <http://localhost:8080/> mostra `"banco":"conectado"`.
6. *Run and Debug* → **App — API local (emulador)** (ou **App — dados fictícios** sem backend) → `F5`.

Deu erro? [22 — Troubleshooting](22-troubleshooting.md).

## Diferenças da máquina pessoal do Pedro (registradas na Etapa 0)

O projeto foi planejado para **MySQL 8.4 LTS** em `C:\dev\Summit`. Na máquina onde o app está sendo construído:

| Item | Planejado | Nesta máquina | Impacto |
|---|---|---|---|
| Banco | MySQL 8.4 LTS | **MySQL 8.0** (8.0.44, serviço `MySQL80`, porta 3306) | nenhum: o `schema.sql` usa só recursos que o 8.0 já tem (coluna gerada, `utf8mb4_0900_ai_ci`, TLS e o login `caching_sha2_password`) |
| Pasta do projeto | `C:\dev\Summit` | `C:\Users\user\Documents\dev\Summit` | nenhum: o caminho não tem espaço nem acento |
| NDK do Android | baixado sozinho pelo Gradle | instalado à mão: `android sdk install ndk/28.2.13676358` | só na primeira compilação (o novo *Android CLI* substituiu o `sdkmanager`) |

Quem usar MySQL 8.4 não precisa fazer nada diferente.
