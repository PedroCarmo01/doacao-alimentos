-- =====================================================================
-- Banco da plataforma de doação de alimentos — MySQL 8.4 LTS
-- (também funciona no MySQL 8.0.16 ou mais novo; veja o README da raiz)
--
-- Cria (ou RECRIA DO ZERO) o banco "summit" e TODAS as tabelas do app
-- (veja docs/07-banco-de-dados.md). As tabelas de etapas futuras
-- (notificações, chat, comunidade) já ficam prontas, para não ser preciso
-- mexer no banco de novo.
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
--   * Os valores dos ENUM são iguais aos nomes dos enums do Dart
--     (ex.: 'produtorRural', 'canceladaOng'). Assim o backend converte
--     com TipoEstabelecimento.values.byName(...), sem tabela de tradução.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS summit
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE summit;

-- Remove na ordem "filhas antes das mães" por causa das chaves estrangeiras.
-- (doadores e ongs são tabelas de uma versão antiga do projeto, se existirem.)
DROP TABLE IF EXISTS denuncias;
DROP TABLE IF EXISTS apoios;
DROP TABLE IF EXISTS fotos_publicacao;
DROP TABLE IF EXISTS publicacoes;
DROP TABLE IF EXISTS mensagens;
DROP TABLE IF EXISTS dispositivos;
DROP TABLE IF EXISTS notificacoes;
DROP TABLE IF EXISTS bloqueios_doacao;
DROP TABLE IF EXISTS reservas;
DROP TABLE IF EXISTS fotos_doacao;
DROP TABLE IF EXISTS doacoes;
DROP TABLE IF EXISTS ongs;
DROP TABLE IF EXISTS doadores;
DROP TABLE IF EXISTS perfis;
DROP TABLE IF EXISTS usuarios;

-- =====================================================================
-- CONTAS
-- =====================================================================

-- ---------------------------------------------------------------------
-- usuarios: identidade e autenticação. RN01: cada conta é doador OU ong.
-- ---------------------------------------------------------------------
CREATE TABLE usuarios (
  id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  nome        VARCHAR(120)  NOT NULL COMMENT 'Nome do responsável',
  email       VARCHAR(160)  NOT NULL,
  senha_hash  VARCHAR(100)  NOT NULL COMMENT 'Hash bcrypt; nunca a senha em texto',
  tipo        ENUM('doador', 'ong') NOT NULL,
  criado_em   DATETIME      NOT NULL COMMENT 'UTC',
  CONSTRAINT pk_usuarios PRIMARY KEY (id),
  CONSTRAINT uk_usuarios_email UNIQUE (email)               -- RN04
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- perfis: dados da organização (estabelecimento doador ou ONG).
-- Relação 1:1 com usuarios usando CHAVE PRIMÁRIA COMPARTILHADA:
-- perfis.usuario_id é ao mesmo tempo PK e FK. Doador e ONG ficam na mesma
-- tabela; as colunas que são só de um tipo aceitam NULL ou têm padrão.
-- ---------------------------------------------------------------------
CREATE TABLE perfis (
  usuario_id            INT UNSIGNED  NOT NULL,
  nome_organizacao      VARCHAR(160)  NOT NULL,
  tipo_estabelecimento  ENUM('supermercado', 'hortifruti', 'feira', 'padaria',
                             'restaurante', 'produtorRural', 'outro')
                        NULL COMMENT 'Só doador',
  tipo_documento        ENUM('cnpj', 'cpf') NOT NULL,
  documento             VARCHAR(14)   NOT NULL COMMENT 'Só números',
  razao_social          VARCHAR(200)  NULL COMMENT 'Da BrasilAPI',
  verificacao           ENUM('verificada', 'pendente')
                        NOT NULL DEFAULT 'pendente' COMMENT 'RN03',
  telefone              VARCHAR(20)   NULL,
  endereco              VARCHAR(255)  NULL,
  cep                   CHAR(8)       NULL,
  latitude              DECIMAL(9, 6) NOT NULL,
  longitude             DECIMAL(9, 6) NOT NULL,
  familias_atendidas    INT UNSIGNED  NULL COMMENT 'Só ONG',
  transporte            ENUM('aPe', 'carro', 'van') NULL COMMENT 'Só ONG',
  busca_ativa           BOOLEAN       NOT NULL DEFAULT TRUE COMMENT 'Só ONG',
  raio_km               DECIMAL(5, 2) NOT NULL DEFAULT 10.00 COMMENT 'Só ONG',
  suspensa_ate          DATETIME      NULL COMMENT 'Só ONG; RN24 (UTC)',
  info_extra            VARCHAR(255)  NULL COMMENT 'Feira e dias, qual tipo, horários',
  -- T50: quais avisos a pessoa quer receber (migração 002).
  avisar_doacoes        BOOLEAN       NOT NULL DEFAULT TRUE
                        COMMENT 'T50: doação nova / disponível de novo',
  avisar_mensagens      BOOLEAN       NOT NULL DEFAULT TRUE
                        COMMENT 'T50: mensagem nova no chat',
  avisar_comunidade     BOOLEAN       NOT NULL DEFAULT TRUE
                        COMMENT 'T50: apoio numa publicação minha',
  CONSTRAINT pk_perfis PRIMARY KEY (usuario_id),
  CONSTRAINT fk_perfis_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT uk_perfis_documento UNIQUE (documento),       -- RN04
  CONSTRAINT ck_perfis_latitude  CHECK (latitude  BETWEEN -90  AND 90),
  CONSTRAINT ck_perfis_longitude CHECK (longitude BETWEEN -180 AND 180),
  CONSTRAINT ck_perfis_raio      CHECK (raio_km > 0),
  INDEX idx_perfis_verificacao (verificacao)
) ENGINE = InnoDB;

-- =====================================================================
-- DOAÇÕES E RETIRADAS
-- =====================================================================

-- ---------------------------------------------------------------------
-- doacoes: excedente anunciado por um usuário do tipo "doador".
-- (O tipo do usuário é conferido pelo backend, na camada Service.)
-- ---------------------------------------------------------------------
CREATE TABLE doacoes (
  id                   INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  doador_id            INT UNSIGNED   NOT NULL,
  titulo               VARCHAR(120)   NOT NULL,
  descricao            VARCHAR(500)   NULL,
  categoria            ENUM('hortifruti', 'padaria', 'laticinios', 'mercearia',
                            'refeicoesProntas', 'carnesFrios', 'bebidas',
                            'outros') NOT NULL,
  quantidade_numero    DECIMAL(10, 2) NOT NULL,
  unidade              ENUM('kg', 'unidades', 'caixas', 'pacotes', 'litros')
                       NOT NULL,
  peso_kg              DECIMAL(8, 2)  NOT NULL COMMENT 'Soma no painel de impacto',
  conservacao          ENUM('ambiente', 'refrigerado', 'congelado') NOT NULL,
  precisa_veiculo      ENUM('sacola', 'carro', 'van') NULL,
  validade             DATE           NOT NULL COMMENT 'Somente o dia',
  preparado_em         DATETIME       NULL COMMENT 'Refeições prontas (UTC)',
  janela_inicio        DATETIME       NOT NULL COMMENT 'UTC',
  janela_fim           DATETIME       NOT NULL COMMENT 'UTC',
  endereco             VARCHAR(255)   NULL,
  latitude             DECIMAL(9, 6)  NOT NULL,
  longitude            DECIMAL(9, 6)  NOT NULL,
  status               ENUM('disponivel', 'reservada', 'concluida',
                            'cancelada', 'expirada')
                       NOT NULL DEFAULT 'disponivel',
  motivo_cancelamento  VARCHAR(255)   NULL COMMENT 'RN12',
  criado_em            DATETIME       NOT NULL COMMENT 'UTC',
  CONSTRAINT pk_doacoes PRIMARY KEY (id),
  CONSTRAINT fk_doacoes_doador
    FOREIGN KEY (doador_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
  CONSTRAINT ck_doacoes_janela     CHECK (janela_fim > janela_inicio),
  CONSTRAINT ck_doacoes_quantidade CHECK (quantidade_numero > 0),
  CONSTRAINT ck_doacoes_peso       CHECK (peso_kg > 0),
  CONSTRAINT ck_doacoes_latitude   CHECK (latitude  BETWEEN -90  AND 90),
  CONSTRAINT ck_doacoes_longitude  CHECK (longitude BETWEEN -180 AND 180),
  INDEX idx_doacoes_status_janela (status, janela_fim),
  INDEX idx_doacoes_doador (doador_id),
  INDEX idx_doacoes_localizacao (latitude, longitude)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- fotos_doacao: até 3 fotos por doação. O arquivo fica na pasta
-- backend/arquivos/ com um nome aleatório (<uuid>.jpg).
-- ---------------------------------------------------------------------
CREATE TABLE fotos_doacao (
  id         INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  doacao_id  INT UNSIGNED     NOT NULL,
  arquivo    VARCHAR(80)      NOT NULL,
  ordem      TINYINT UNSIGNED NOT NULL COMMENT '1 a 3',
  CONSTRAINT pk_fotos_doacao PRIMARY KEY (id),
  CONSTRAINT fk_fotos_doacao_doacao
    FOREIGN KEY (doacao_id) REFERENCES doacoes (id) ON DELETE RESTRICT,
  CONSTRAINT uk_fotos_doacao_ordem UNIQUE (doacao_id, ordem),
  CONSTRAINT ck_fotos_doacao_ordem CHECK (ordem BETWEEN 1 AND 3)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- reservas: uma ONG aceita uma doação e tem um prazo para retirar.
-- ---------------------------------------------------------------------
CREATE TABLE reservas (
  id                 INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  doacao_id          INT UNSIGNED     NOT NULL,
  ong_id             INT UNSIGNED     NOT NULL,
  status             ENUM('ativa', 'concluida', 'expirada',
                          'canceladaOng', 'canceladaDoador')
                     NOT NULL DEFAULT 'ativa',
  codigo_retirada    CHAR(4)          NOT NULL COMMENT 'RN26',
  tentativas_codigo  TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'RN27',
  bloqueado_ate      DATETIME         NULL COMMENT 'RN27: 5 erros → 10 min (UTC)',
  reservado_em       DATETIME         NOT NULL COMMENT 'UTC',
  expira_em          DATETIME         NOT NULL COMMENT 'UTC; RN21',
  encerrada_em       DATETIME         NULL COMMENT 'Quando saiu de ativa (UTC)',
  motivo             VARCHAR(255)     NULL COMMENT 'Motivo do cancelamento',
  conta_desistencia  BOOLEAN          NOT NULL DEFAULT FALSE COMMENT 'RN22–RN24',
  -- Coluna GERADA pelo próprio MySQL: vale doacao_id enquanto a reserva
  -- está ativa e NULL nos outros status. O índice UNIQUE aceita vários NULL,
  -- mas recusa duas reservas ATIVAS para a mesma doação. É a garantia final,
  -- no banco, de que duas ONGs nunca ficam com a mesma doação (RN20).
  doacao_ativa_id    INT UNSIGNED
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
  INDEX idx_reservas_ong_status (ong_id, status),
  INDEX idx_reservas_desistencias (ong_id, conta_desistencia, encerrada_em),
  INDEX idx_reservas_doacao (doacao_id)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- bloqueios_doacao: RN22. Depois de deixar o prazo acabar (ou desistir
-- fora da tolerância), a ONG não pode aceitar a MESMA doação de novo.
-- ---------------------------------------------------------------------
CREATE TABLE bloqueios_doacao (
  ong_id     INT UNSIGNED NOT NULL,
  doacao_id  INT UNSIGNED NOT NULL,
  criado_em  DATETIME     NOT NULL COMMENT 'UTC',
  CONSTRAINT pk_bloqueios_doacao PRIMARY KEY (ong_id, doacao_id),
  CONSTRAINT fk_bloqueios_ong
    FOREIGN KEY (ong_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
  CONSTRAINT fk_bloqueios_doacao
    FOREIGN KEY (doacao_id) REFERENCES doacoes (id) ON DELETE RESTRICT
) ENGINE = InnoDB;

-- =====================================================================
-- NOTIFICAÇÕES (seção 9 da especificação)
-- =====================================================================

-- ---------------------------------------------------------------------
-- notificacoes: o servidor SEMPRE grava aqui. O app busca as novas com
-- GET /notificacoes?depois=<id> (agora) ou recebe por push (futuro).
-- ---------------------------------------------------------------------
CREATE TABLE notificacoes (
  id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  usuario_id  INT UNSIGNED  NOT NULL,
  tipo        ENUM('doacaoNova', 'doacaoAceita', 'prazoAcabando',
                   'prazoAcabouOng', 'prazoAcabouDoador',
                   'doacaoDisponivelDeNovo', 'retiradaConfirmada',
                   'mensagemNova', 'doacaoCancelada', 'suspensao',
                   'apoioNovo')
              NOT NULL,
  titulo      VARCHAR(120)  NOT NULL,
  corpo       VARCHAR(500)  NOT NULL,
  doacao_id   INT UNSIGNED  NULL,
  reserva_id  INT UNSIGNED  NULL,
  lida        BOOLEAN       NOT NULL DEFAULT FALSE,
  criado_em   DATETIME      NOT NULL COMMENT 'UTC',
  CONSTRAINT pk_notificacoes PRIMARY KEY (id),
  CONSTRAINT fk_notificacoes_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
  CONSTRAINT fk_notificacoes_doacao
    FOREIGN KEY (doacao_id) REFERENCES doacoes (id) ON DELETE RESTRICT,
  CONSTRAINT fk_notificacoes_reserva
    FOREIGN KEY (reserva_id) REFERENCES reservas (id) ON DELETE RESTRICT,
  INDEX idx_notificacoes_usuario_id (usuario_id, id)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- dispositivos: identificador do celular para o push real (Firebase),
-- usado numa etapa futura. A rota POST /dispositivos já existe.
-- ---------------------------------------------------------------------
CREATE TABLE dispositivos (
  id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  usuario_id     INT UNSIGNED  NOT NULL,
  token          VARCHAR(255)  NOT NULL,
  plataforma     ENUM('android') NOT NULL DEFAULT 'android',
  atualizado_em  DATETIME      NOT NULL COMMENT 'UTC',
  CONSTRAINT pk_dispositivos PRIMARY KEY (id),
  CONSTRAINT fk_dispositivos_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT uk_dispositivos_token UNIQUE (token)
) ENGINE = InnoDB;

-- =====================================================================
-- CHAT (RN30, RN31)
-- =====================================================================

-- ---------------------------------------------------------------------
-- mensagens: conversa entre o doador e a ONG de UMA reserva.
-- autor_id NULL = mensagem do sistema ("ONG X aceitou a doação às 14:10").
-- ---------------------------------------------------------------------
CREATE TABLE mensagens (
  id          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  reserva_id  INT UNSIGNED   NOT NULL,
  autor_id    INT UNSIGNED   NULL,
  texto       VARCHAR(1000)  NOT NULL,
  criado_em   DATETIME       NOT NULL COMMENT 'UTC',
  lida_em     DATETIME       NULL COMMENT 'UTC',
  CONSTRAINT pk_mensagens PRIMARY KEY (id),
  CONSTRAINT fk_mensagens_reserva
    FOREIGN KEY (reserva_id) REFERENCES reservas (id) ON DELETE RESTRICT,
  CONSTRAINT fk_mensagens_autor
    FOREIGN KEY (autor_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
  INDEX idx_mensagens_reserva_id (reserva_id, id)
) ENGINE = InnoDB;

-- =====================================================================
-- COMUNIDADE (RN40–RN42)
-- =====================================================================

CREATE TABLE publicacoes (
  id                 INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  autor_id           INT UNSIGNED   NOT NULL,
  texto              VARCHAR(1000)  NOT NULL,
  doacao_id          INT UNSIGNED   NULL COMMENT 'Doação concluída ligada',
  familias_ajudadas  INT UNSIGNED   NULL,
  refeicoes          INT UNSIGNED   NULL,
  oculta             BOOLEAN        NOT NULL DEFAULT FALSE COMMENT 'RN42',
  criado_em          DATETIME       NOT NULL COMMENT 'UTC',
  CONSTRAINT pk_publicacoes PRIMARY KEY (id),
  CONSTRAINT fk_publicacoes_autor
    FOREIGN KEY (autor_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
  CONSTRAINT fk_publicacoes_doacao
    FOREIGN KEY (doacao_id) REFERENCES doacoes (id) ON DELETE RESTRICT,
  INDEX idx_publicacoes_feed (oculta, id)
) ENGINE = InnoDB;

CREATE TABLE fotos_publicacao (
  id              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  publicacao_id   INT UNSIGNED     NOT NULL,
  arquivo         VARCHAR(80)      NOT NULL,
  ordem           TINYINT UNSIGNED NOT NULL COMMENT '1 a 3',
  CONSTRAINT pk_fotos_publicacao PRIMARY KEY (id),
  CONSTRAINT fk_fotos_publicacao_publicacao
    FOREIGN KEY (publicacao_id) REFERENCES publicacoes (id) ON DELETE RESTRICT,
  CONSTRAINT uk_fotos_publicacao_ordem UNIQUE (publicacao_id, ordem),
  CONSTRAINT ck_fotos_publicacao_ordem CHECK (ordem BETWEEN 1 AND 3)
) ENGINE = InnoDB;

-- apoios: RN41. A chave composta impede a mesma conta de apoiar 2 vezes.
CREATE TABLE apoios (
  publicacao_id  INT UNSIGNED NOT NULL,
  usuario_id     INT UNSIGNED NOT NULL,
  criado_em      DATETIME     NOT NULL COMMENT 'UTC',
  CONSTRAINT pk_apoios PRIMARY KEY (publicacao_id, usuario_id),
  CONSTRAINT fk_apoios_publicacao
    FOREIGN KEY (publicacao_id) REFERENCES publicacoes (id) ON DELETE RESTRICT,
  CONSTRAINT fk_apoios_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE = InnoDB;

-- denuncias: RN42. Uma por conta; com 3 de contas diferentes, a
-- publicação fica oculta.
CREATE TABLE denuncias (
  publicacao_id  INT UNSIGNED NOT NULL,
  usuario_id     INT UNSIGNED NOT NULL,
  motivo         ENUM('improprio', 'falso', 'outro') NOT NULL,
  criado_em      DATETIME     NOT NULL COMMENT 'UTC',
  CONSTRAINT pk_denuncias PRIMARY KEY (publicacao_id, usuario_id),
  CONSTRAINT fk_denuncias_publicacao
    FOREIGN KEY (publicacao_id) REFERENCES publicacoes (id) ON DELETE RESTRICT,
  CONSTRAINT fk_denuncias_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE = InnoDB;

-- Pronto. Próximos passos:
--   1) criar_usuario.sql  (usuário do backend, com privilégio mínimo)
--   2) dados de exemplo:  cd desenvolvimento_app/backend && dart run tool/seed.dart
