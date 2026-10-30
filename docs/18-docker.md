# 18 — Docker (opcional)

**O Docker não é necessário neste projeto.** O caminho padrão é o MySQL 8.4 instalado no Windows ([trilha/03](../trilha/03-ambiente-windows-vscode.md)). A justificativa está em [23 — Análise técnica, seção 5](23-analise-tecnica.md) e no [ADR-003](adr/ADR-003-mysql-84-nativo-docker-opcional.md).

Ele continua disponível como **plano B** para quem não conseguir instalar o MySQL:

- Arquivo: [`database/docker-compose.yml`](../database/docker-compose.yml) (MySQL 8.4, cria as tabelas na primeira subida).
- Passo a passo completo, comandos do dia a dia e problemas comuns: **[trilha/apêndice A](../trilha/apendice-a-docker-opcional.md)**.

Resumo:

```powershell
docker compose -f database/docker-compose.yml up -d     # liga
docker compose -f database/docker-compose.yml down      # desliga (mantém os dados)
docker compose -f database/docker-compose.yml down -v   # zera tudo
```

No `backend/.env`: `DB_USUARIO=summit_app` e `DB_SENHA` igual a `MYSQL_PASSWORD` do compose.
