-- =====================================================================
-- Consultas úteis para explorar o banco no MySQL Workbench.
-- Rode uma de cada vez: cursor na linha + Ctrl+Enter.
-- =====================================================================

USE summit;

-- 1) Usuários e suas organizações (JOIN 1:1)
SELECT u.id, u.tipo, u.email, p.nome_organizacao, p.latitude, p.longitude
FROM usuarios u
JOIN perfis p ON p.usuario_id = u.id
ORDER BY u.tipo, u.id;

-- 2) Doações com o nome do doador
SELECT d.id, d.titulo, d.status, d.validade, d.janela_fim, p.nome_organizacao AS doador
FROM doacoes d
JOIN perfis p ON p.usuario_id = d.doador_id
ORDER BY d.criado_em DESC;

-- 3) Quantas doações em cada status (GROUP BY)
SELECT status, COUNT(*) AS total
FROM doacoes
GROUP BY status;

-- 4) Reservas ativas e quanto falta para expirar (em minutos)
SELECT r.id, d.titulo, p.nome_organizacao AS ong, r.expira_em,
       TIMESTAMPDIFF(MINUTE, UTC_TIMESTAMP(), r.expira_em) AS minutos_restantes
FROM reservas r
JOIN doacoes d ON d.id = r.doacao_id
JOIN perfis  p ON p.usuario_id = r.ong_id
WHERE r.status = 'ativa';

-- 5) Doações disponíveis a até 10 km de um ponto (Haversine).
--    Troque as coordenadas pelas de uma ONG cadastrada (consulta 1).
SET @lat = -23.5229, @lng = -46.1880, @raio_km = 10;
SELECT d.id, d.titulo,
       ROUND(6371 * ACOS(LEAST(1, GREATEST(-1,
         COS(RADIANS(@lat)) * COS(RADIANS(d.latitude)) *
         COS(RADIANS(d.longitude) - RADIANS(@lng)) +
         SIN(RADIANS(@lat)) * SIN(RADIANS(d.latitude))
       ))), 2) AS distancia_km
FROM doacoes d
WHERE d.status = 'disponivel'
HAVING distancia_km <= @raio_km
ORDER BY distancia_km;

-- 6) Prova da regra "uma reserva ativa por doação":
--    deve voltar VAZIO. Se aparecer algo, há um bug grave.
SELECT doacao_id, COUNT(*) AS reservas_ativas
FROM reservas
WHERE status = 'ativa'
GROUP BY doacao_id
HAVING COUNT(*) > 1;

-- 7) Ver a estrutura de uma tabela (colunas, tipos, chaves)
SHOW CREATE TABLE reservas;
