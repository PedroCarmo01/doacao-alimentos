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
