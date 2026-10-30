# Migrações do banco

Quando o grupo precisar **mudar a estrutura** do banco depois que todos já rodaram o `schema.sql` (por exemplo, criar uma coluna), a mudança vai para um arquivo **novo** nesta pasta. Nunca edite um script que os colegas já executaram: eles não saberiam que precisam rodar de novo.

## Regras

1. Um arquivo por mudança, numerado em sequência: `002_adiciona_foto_doacao.sql`, `003_...`.
2. O arquivo deve poder rodar no banco de quem já tem a versão anterior (use `ALTER TABLE`, não `DROP`).
3. **Também** atualize o `schema.sql`, para quem for criar o banco do zero.
4. Abra um PR com o rótulo `banco` e avise no grupo: "rodem a migração 002".
5. Registre no `CHANGELOG.md`.

## Exemplo

```sql
-- 002_adiciona_foto_doacao.sql
USE summit;
ALTER TABLE doacoes ADD COLUMN foto_url VARCHAR(500) NULL AFTER descricao;
```

> A versão 001 é o próprio `../schema.sql`.
