-- =====================================================================
-- Apaga TODOS os dados, mantendo as tabelas, e reinicia os ids em 1.
-- Rode conectado como root (TRUNCATE exige privilégio que o summit_app
-- não tem). Para recarregar os dados de exemplo depois:
--   cd desenvolvimento_app/backend && dart run tool/seed.dart
-- =====================================================================

USE summit;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE denuncias;
TRUNCATE TABLE apoios;
TRUNCATE TABLE fotos_publicacao;
TRUNCATE TABLE publicacoes;
TRUNCATE TABLE mensagens;
TRUNCATE TABLE dispositivos;
TRUNCATE TABLE notificacoes;
TRUNCATE TABLE bloqueios_doacao;
TRUNCATE TABLE reservas;
TRUNCATE TABLE fotos_doacao;
TRUNCATE TABLE doacoes;
TRUNCATE TABLE perfis;
TRUNCATE TABLE usuarios;
SET FOREIGN_KEY_CHECKS = 1;
