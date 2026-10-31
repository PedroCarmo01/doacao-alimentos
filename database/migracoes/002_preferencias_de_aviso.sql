-- =====================================================================
-- 002 — Preferências de aviso (etapa 7, tela T50 — Perfil)
--
-- O que muda:
--   1) perfis ganha 3 colunas: quais avisos a pessoa quer receber.
--      Todas começam LIGADAS (DEFAULT TRUE), então quem já tem conta
--      continua recebendo tudo, como antes.
--   2) notificacoes.tipo ganha o valor 'apoioNovo' (alguém apoiou uma
--      publicação sua na Comunidade).
--
-- Não apaga nada: só ACRESCENTA. Pode rodar no banco de quem já tem a
-- versão anterior (o schema.sql também já foi atualizado).
--
-- Como rodar (PowerShell, na raiz do projeto):
--   Get-Content database\migracoes\002_preferencias_de_aviso.sql |
--     mysql -u root -p
-- =====================================================================

USE summit;

ALTER TABLE perfis
  ADD COLUMN avisar_doacoes    BOOLEAN NOT NULL DEFAULT TRUE
    COMMENT 'T50: doação nova / disponível de novo' AFTER info_extra,
  ADD COLUMN avisar_mensagens  BOOLEAN NOT NULL DEFAULT TRUE
    COMMENT 'T50: mensagem nova no chat' AFTER avisar_doacoes,
  ADD COLUMN avisar_comunidade BOOLEAN NOT NULL DEFAULT TRUE
    COMMENT 'T50: apoio numa publicação minha' AFTER avisar_mensagens;

ALTER TABLE notificacoes
  MODIFY COLUMN tipo ENUM('doacaoNova', 'doacaoAceita', 'prazoAcabando',
                          'prazoAcabouOng', 'prazoAcabouDoador',
                          'doacaoDisponivelDeNovo', 'retiradaConfirmada',
                          'mensagemNova', 'doacaoCancelada', 'suspensao',
                          'apoioNovo')
                     NOT NULL;
