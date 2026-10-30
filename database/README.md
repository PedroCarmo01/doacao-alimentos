# database/ — Scripts do banco de dados (MySQL 8.4 LTS)

Tudo o que é preciso para criar o banco do projeto na sua máquina. O passo a passo com explicações (modelo conceitual, normalização, transações) está em [trilha/08](../trilha/08-banco-de-dados-passo-a-passo.md). A referência das tabelas está em [docs/07](../docs/07-banco-de-dados.md).

## Arquivos

| Arquivo | Para que serve | Quem roda | Quando |
|---|---|---|---|
| `schema.sql` | Cria o banco `summit` e as tabelas **do zero** (apaga o que existir) | root | Primeira vez, ou para recomeçar |
| `criar_usuario.sql` | Cria o usuário `summit_app` usado pelo backend (privilégio mínimo) | root | Uma vez, depois do schema |
| `limpar_dados.sql` | Apaga os dados e mantém as tabelas | root | Quando quiser limpar tudo |
| `consultas_uteis.sql` | Consultas para explorar e conferir os dados | qualquer | Sempre que quiser |
| `migracoes/` | Mudanças de estrutura depois que todos já criaram o banco | root | Quando o grupo combinar |
| `docker-compose.yml` | **Opcional**: MySQL em Docker | — | Só se o MySQL nativo não funcionar |

> Os **dados de exemplo** (usuários, doações) não ficam em SQL: são criados por `desenvolvimento_app/backend/tool/seed.dart`, porque as senhas precisam de hash bcrypt real.

## Ordem (primeira vez)

```text
1. schema.sql          (no Workbench, conectado como root)
2. criar_usuario.sql   (troque a senha e copie para o backend/.env)
3. no terminal:        cd desenvolvimento_app/backend
                       dart run tool/seed.dart
```

## Rodando no MySQL Workbench

1. Abra o Workbench e clique na conexão **Local instance MySQL84** (usuário root).
2. Menu **File > Open SQL Script...** e escolha o arquivo.
3. Clique no **raio** (⚡, "Execute the selected portion or everything") para rodar o script inteiro.
4. Na lateral **Schemas**, clique no ícone de atualizar: o banco `summit` aparece com as 4 tabelas.

## Rodando pelo terminal (alternativa)

Funciona se a pasta `bin` do MySQL estiver no PATH (ver [trilha/03](../trilha/03-ambiente-windows-vscode.md)):

```powershell
mysql -u root -p < database/schema.sql
mysql -u root -p < database/criar_usuario.sql
```

## Recomeçar do zero

Rode `schema.sql` de novo (apaga e recria tudo). Depois rode o seed. Não é preciso rodar o `criar_usuario.sql` de novo, porque o usuário continua existindo.

## Problemas comuns

| Erro | Causa | Solução |
|---|---|---|
| `Access denied for user 'summit_app'` | Senha do `.env` diferente da usada no `criar_usuario.sql` | Rode o `ALTER USER` (no fim do `criar_usuario.sql`) e atualize o `.env` |
| `Unknown database 'summit'` | O schema ainda não foi rodado | Rode o `schema.sql` |
| `Check constraint 'ck_doacoes_janela' is violated` | Tentativa de gravar uma janela que termina antes de começar | Corrija os dados; o banco está protegendo a regra |
| `Duplicate entry ... for key 'uk_reservas_uma_ativa_por_doacao'` | Segunda reserva ativa para a mesma doação | É a regra funcionando; o backend transforma isso em erro 409 |
