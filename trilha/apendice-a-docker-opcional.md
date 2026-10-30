# Apêndice A — Docker (opcional)

> **Você provavelmente NÃO precisa deste apêndice.** O caminho padrão do projeto é o MySQL 8.4 instalado no Windows ([trilha/03](03-ambiente-windows-vscode.md)). Use o Docker só se o MySQL nativo não instalar de jeito nenhum na sua máquina. A justificativa está em [docs/23, seção 5](../docs/23-analise-tecnica.md) e no [ADR-003](../docs/adr/ADR-003-mysql-84-nativo-docker-opcional.md).

## O que é o Docker, em palavras simples

Um **container** é como uma "caixinha" com um programa já instalado e configurado (aqui, o MySQL 8.4). Você liga e desliga a caixinha sem instalar nada no Windows. O **Docker Desktop** é o programa que roda essas caixinhas.

| Vantagem | Custo |
|---|---|
| MySQL idêntico em qualquer máquina | Exige WSL2 e virtualização ligada na BIOS |
| Apagar e recriar o banco em segundos | Usa cerca de 2 GB de RAM, competindo com o emulador Android |
| Não mexe no Windows | Mais uma ferramenta para aprender |

## Passo 1 — Instalar o Docker Desktop

1. Confira se a virtualização está ligada: `Ctrl+Shift+Esc` → aba **Desempenho** → **CPU** → "Virtualização: **Habilitado**". Se estiver desabilitado, é preciso ligar na BIOS (procure no YouTube "habilitar virtualização BIOS" + a marca do seu notebook).
2. No PowerShell **como administrador**: `wsl --install` e reinicie o computador.
3. Baixe e instale o Docker Desktop: <https://www.docker.com/products/docker-desktop/>.
4. Abra o Docker Desktop e espere o ícone da baleia ficar verde ("Engine running").
5. Teste no terminal do VS Code:

```powershell
docker --version
docker run --rm hello-world
```

## Passo 2 — Subir o MySQL do projeto

O arquivo pronto é `database/docker-compose.yml`. Na **raiz** do projeto:

```powershell
docker compose -f database/docker-compose.yml up -d
```

Na primeira vez ele baixa a imagem `mysql:8.4` (alguns minutos) e **cria as tabelas sozinho** rodando o `schema.sql`. O usuário `summit_app` também é criado pelo próprio container, então **não** rode o `criar_usuario.sql`.

Confira:

```powershell
docker compose -f database/docker-compose.yml ps
```

A coluna `STATUS` deve mostrar `healthy` depois de uns 30 segundos.

## Passo 3 — Configurar o backend

No `desenvolvimento_app/backend/.env`, use exatamente:

```text
DB_HOST=127.0.0.1
DB_PORTA=3306
DB_NOME=summit
DB_USUARIO=summit_app
DB_SENHA=TroqueEstaSenha_123
DB_TLS=true
```

Depois, o mesmo de sempre: tarefa **Backend: recriar dados de exemplo (seed)** e **Backend: iniciar**.

## Passo 4 — Conectar o MySQL Workbench (opcional)

Workbench → **+** (nova conexão) → Hostname `127.0.0.1`, Port `3306`, Username `root`, senha `root_dev_123` (está no `docker-compose.yml`; serve só para desenvolvimento).

## Comandos do dia a dia

| Quero... | Comando (na raiz) |
|---|---|
| Ligar o banco | `docker compose -f database/docker-compose.yml up -d` |
| Desligar (mantém os dados) | `docker compose -f database/docker-compose.yml down` |
| **Zerar** tudo e recriar as tabelas | `docker compose -f database/docker-compose.yml down -v` e depois `up -d` |
| Ver os logs do MySQL | `docker compose -f database/docker-compose.yml logs -f` |
| Abrir o console do MySQL | `docker exec -it doacoes-mysql mysql -u root -proot_dev_123 summit` |

> **Mudou o `schema.sql`?** O container só roda o schema na **primeira** vez. Para aplicar mudanças, use `down -v` (apaga os dados) e `up -d`, ou rode a migração pelo Workbench.

## Problemas comuns

| Erro | Causa | Solução |
|---|---|---|
| `port 3306 is already allocated` | Já existe um MySQL nativo rodando | Pare o serviço `MySQL84` (`services.msc`) ou mude a porta para `"3307:3306"` e `DB_PORTA=3307` |
| `WSL 2 installation is incomplete` | WSL não instalado | `wsl --install` como administrador e reinicie |
| Emulador muito lento com o Docker ligado | Pouca RAM | Desligue o banco quando não estiver usando o backend, ou use o app no modo Fake |
| `Access denied for user 'summit_app'` | Senha do `.env` diferente da `MYSQL_PASSWORD` | Deixe as duas iguais e rode `down -v` / `up -d` |

## E o deploy com Docker?

Para publicar o backend num servidor (opcional), o próprio Dart Frog gera um `Dockerfile`:

```powershell
cd desenvolvimento_app\backend
dart_frog build
```

Isso cria `build/` com um `Dockerfile` pronto. Como o backend depende do pacote `shared_models` (pasta vizinha), confira o [docs/19-deploy.md](../docs/19-deploy.md) antes de tentar: o build precisa enxergar as duas pastas.
