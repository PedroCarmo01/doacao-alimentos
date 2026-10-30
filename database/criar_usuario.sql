-- =====================================================================
-- Cria o usuário que o BACKEND usa para acessar o banco.
--
-- Princípio do PRIVILÉGIO MÍNIMO: o backend só pode ler e gravar dados.
-- Ele NÃO pode apagar tabelas nem criar usuários (isso fica com o root).
--
-- Rode UMA vez, conectado como root, DEPOIS do schema.sql.
-- 1) Troque a senha abaixo (nas duas linhas CREATE USER).
-- 2) Coloque a MESMA senha em desenvolvimento_app/backend/.env (DB_SENHA).
--
-- São criados dois "hosts" porque o MySQL trata "localhost" e "127.0.0.1"
-- como origens diferentes.
-- =====================================================================

CREATE USER IF NOT EXISTS 'summit_app'@'localhost' IDENTIFIED BY 'TroqueEstaSenha_123';
CREATE USER IF NOT EXISTS 'summit_app'@'127.0.0.1' IDENTIFIED BY 'TroqueEstaSenha_123';

GRANT SELECT, INSERT, UPDATE, DELETE ON summit.* TO 'summit_app'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON summit.* TO 'summit_app'@'127.0.0.1';

-- Esqueceu a senha ou quer trocar? Rode (como root):
--   ALTER USER 'summit_app'@'localhost' IDENTIFIED BY 'NovaSenha_123';
--   ALTER USER 'summit_app'@'127.0.0.1' IDENTIFIED BY 'NovaSenha_123';
