-- =====================================================================
-- Banco da plataforma de doação de alimentos — MySQL 8.4 LTS
--
-- Cria (ou RECRIA DO ZERO) o banco "summit" e todas as tabelas.
-- ATENÇÃO: apaga as tabelas e os dados existentes. Uso em desenvolvimento.
--
-- Como rodar (conectado como root):
--   MySQL Workbench: File > Open SQL Script... > schema.sql > ícone do raio
--   Terminal:        mysql -u root -p < database/schema.sql
--
-- Convenções:
--   * Todo DATETIME guarda um instante em UTC, enviado pelo backend
--     (nada de NOW() ou CURRENT_TIMESTAMP; veja docs/adr/ADR-010).
--   * Registros de negócio não são apagados: mudam de "status"
--     (exclusão lógica). Por isso as chaves estrangeiras usam RESTRICT.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS summit
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE summit;

-- Remove na ordem "filhas antes das mães" por causa das chaves estrangeiras.
-- (doadores e ongs são tabelas de uma versão antiga do projeto, se existirem.)
DROP TABLE IF EXISTS reservas;
DROP TABLE IF EXISTS doacoes;
DROP TABLE IF EXISTS ongs;
DROP TABLE IF EXISTS doadores;
DROP TABLE IF EXISTS perfis;
DROP TABLE IF EXISTS usuarios;

-- ---------------------------------------------------------------------
-- usuarios: identidade e autenticação.
-- ---------------------------------------------------------------------
CREATE TABLE usuarios (
  id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  nome        VARCHAR(120)  NOT NULL,
  email       VARCHAR(160)  NOT NULL,
  senha_hash  VARCHAR(100)  NOT NULL COMMENT 'Hash bcrypt; nunca a senha em texto',
  tipo        ENUM('doador', 'ong') NOT NULL,
  criado_em   DATETIME      NOT NULL COMMENT 'UTC',
  CONSTRAINT pk_usuarios PRIMARY KEY (id),
  CONSTRAINT uk_usuarios_email UNIQUE (email)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- perfis: dados da organização (estabelecimento doador ou ONG).
-- Relação 1:1 com usuarios usando CHAVE PRIMÁRIA COMPARTILHADA:
-- perfis.usuario_id é ao mesmo tempo PK e FK. Doador e ONG têm os mesmos
-- atributos, por isso uma única tabela (o tipo já está em usuarios).
-- ---------------------------------------------------------------------
CREATE TABLE perfis (
  usuario_id        INT UNSIGNED  NOT NULL,
  nome_organizacao  VARCHAR(160)  NOT NULL,
  telefone          VARCHAR(20)   NULL,
  endereco          VARCHAR(255)  NULL,
  latitude          DECIMAL(9, 6) NOT NULL,
  longitude         DECIMAL(9, 6) NOT NULL,
  CONSTRAINT pk_perfis PRIMARY KEY (usuario_id),
  CONSTRAINT fk_perfis_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT ck_perfis_latitude  CHECK (latitude  BETWEEN -90  AND 90),
  CONSTRAINT ck_perfis_longitude CHECK (longitude BETWEEN -180 AND 180)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- doacoes: excedente anunciado por um usuário do tipo "doador".
-- (O tipo do usuário é conferido pelo backend, na camada Service.)
-- ---------------------------------------------------------------------
CREATE TABLE doacoes (
  id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  doador_id      INT UNSIGNED  NOT NULL,
  titulo         VARCHAR(120)  NOT NULL,
  descricao      VARCHAR(500)  NULL,
  categoria      ENUM('hortifruti', 'padaria', 'laticinios', 'mercearia',
                      'refeicoesProntas', 'outros') NOT NULL,
  quantidade     VARCHAR(60)   NOT NULL,
  validade       DATE          NOT NULL COMMENT 'Somente o dia',
  janela_inicio  DATETIME      NOT NULL COMMENT 'UTC',
  janela_fim     DATETIME      NOT NULL COMMENT 'UTC',
  endereco       VARCHAR(255)  NULL,
  latitude       DECIMAL(9, 6) NOT NULL,
  longitude      DECIMAL(9, 6) NOT NULL,
  status         ENUM('disponivel', 'reservada', 'concluida', 'cancelada')
                 NOT NULL DEFAULT 'disponivel',
  criado_em      DATETIME      NOT NULL COMMENT 'UTC',
  CONSTRAINT pk_doacoes PRIMARY KEY (id),
  CONSTRAINT fk_doacoes_doador
    FOREIGN KEY (doador_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
  CONSTRAINT ck_doacoes_janela    CHECK (janela_fim > janela_inicio),
  CONSTRAINT ck_doacoes_latitude  CHECK (latitude  BETWEEN -90  AND 90),
  CONSTRAINT ck_doacoes_longitude CHECK (longitude BETWEEN -180 AND 180),
  INDEX idx_doacoes_status_janela (status, janela_fim),
  INDEX idx_doacoes_doador (doador_id),
  INDEX idx_doacoes_localizacao (latitude, longitude)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- reservas: uma ONG reserva uma doação por um prazo.
-- ---------------------------------------------------------------------
CREATE TABLE reservas (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  doacao_id        INT UNSIGNED NOT NULL,
  ong_id           INT UNSIGNED NOT NULL,
  status           ENUM('ativa', 'concluida', 'expirada', 'cancelada')
                   NOT NULL DEFAULT 'ativa',
  reservado_em     DATETIME     NOT NULL COMMENT 'UTC',
  expira_em        DATETIME     NOT NULL COMMENT 'UTC',
  retirado_em      DATETIME     NULL     COMMENT 'UTC',
  -- Coluna GERADA pelo próprio MySQL: vale doacao_id enquanto a reserva
  -- está ativa e NULL nos outros status. O índice UNIQUE aceita vários NULL,
  -- mas recusa duas reservas ATIVAS para a mesma doação. É a garantia final,
  -- no banco, de que duas ONGs nunca ficam com a mesma doação.
  doacao_ativa_id  INT UNSIGNED
                   GENERATED ALWAYS AS (IF(status = 'ativa', doacao_id, NULL))
                   STORED,
  CONSTRAINT pk_reservas PRIMARY KEY (id),
  CONSTRAINT fk_reservas_doacao
    FOREIGN KEY (doacao_id) REFERENCES doacoes (id) ON DELETE RESTRICT,
  CONSTRAINT fk_reservas_ong
    FOREIGN KEY (ong_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
  CONSTRAINT ck_reservas_prazo CHECK (expira_em > reservado_em),
  CONSTRAINT uk_reservas_uma_ativa_por_doacao UNIQUE (doacao_ativa_id),
  INDEX idx_reservas_status_expira (status, expira_em),
  INDEX idx_reservas_ong (ong_id),
  INDEX idx_reservas_doacao (doacao_id)
) ENGINE = InnoDB;

-- Pronto. Próximos passos:
--   1) criar_usuario.sql  (usuário do backend, com privilégio mínimo)
--   2) dados de exemplo:  cd desenvolvimento_app/backend && dart run tool/seed.dart
