-- =====================================================================
-- 05_ANALISES_CLIENTES.SQL
-- Objetivo: analisar o comportamento dos clientes -- quem mais compra,
-- quem mais gasta, ticket médio por cliente, clientes inativos, etc.
-- =====================================================================

-- 1. Top 10 clientes que mais compraram (por quantidade de pedidos válidos)
SELECT
    c.nome_cliente,
    COUNT(DISTINCT p.id_pedido) AS qtd_pedidos
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
WHERE p.status_pedido <> 'Cancelado'
GROUP BY c.id_cliente, c.nome_cliente
ORDER BY qtd_pedidos DESC
LIMIT 10;

-- 2. Top 10 clientes que mais gastaram (por faturamento gerado)
SELECT
    c.nome_cliente,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS total_gasto
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN clientes c ON c.id_cliente = p.id_cliente
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY c.id_cliente, c.nome_cliente
ORDER BY total_gasto DESC
LIMIT 10;

-- 3. Ticket médio por cliente (somente clientes com pelo menos 1 pedido válido)
SELECT
    c.nome_cliente,
    COUNT(DISTINCT p.id_pedido) AS qtd_pedidos,
    ROUND(SUM(ip.quantidade * ip.preco_unitario) * 1.0 / COUNT(DISTINCT p.id_pedido), 2) AS ticket_medio
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN clientes c ON c.id_cliente = p.id_cliente
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY c.id_cliente, c.nome_cliente
ORDER BY ticket_medio DESC
LIMIT 10;

-- 4. Clientes ativos (realizaram pelo menos 1 compra nos últimos 90 dias
--    considerando a última data presente na base como "hoje")
WITH ultima_data AS (
    SELECT MAX(data_pedido) AS hoje FROM pedidos
)
SELECT
    c.nome_cliente,
    MAX(p.data_pedido) AS ultima_compra
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
CROSS JOIN ultima_data
WHERE p.status_pedido <> 'Cancelado'
GROUP BY c.id_cliente, c.nome_cliente
HAVING JULIANDAY((SELECT hoje FROM ultima_data)) - JULIANDAY(MAX(p.data_pedido)) <= 90
ORDER BY ultima_compra DESC;

-- 5. Clientes sem compras recentes (mais de 180 dias sem comprar - risco de churn)
WITH ultima_data AS (
    SELECT MAX(data_pedido) AS hoje FROM pedidos
)
SELECT
    c.nome_cliente,
    MAX(p.data_pedido) AS ultima_compra,
    ROUND(JULIANDAY((SELECT hoje FROM ultima_data)) - JULIANDAY(MAX(p.data_pedido))) AS dias_sem_comprar
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
CROSS JOIN ultima_data
WHERE p.status_pedido <> 'Cancelado'
GROUP BY c.id_cliente, c.nome_cliente
HAVING dias_sem_comprar > 180
ORDER BY dias_sem_comprar DESC;

-- 6. Ranking geral dos clientes por faturamento (RANK / DENSE_RANK)
SELECT
    c.nome_cliente,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS total_gasto,
    RANK() OVER (ORDER BY SUM(ip.quantidade * ip.preco_unitario) DESC) AS ranking
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN clientes c ON c.id_cliente = p.id_cliente
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY c.id_cliente, c.nome_cliente
ORDER BY ranking
LIMIT 20;

-- 7. Participação dos 10 maiores clientes no faturamento total da empresa
WITH faturamento_por_cliente AS (
    SELECT
        c.id_cliente,
        c.nome_cliente,
        SUM(ip.quantidade * ip.preco_unitario) AS total_gasto
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    JOIN clientes c ON c.id_cliente = p.id_cliente
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY c.id_cliente, c.nome_cliente
),
top_10 AS (
    SELECT * FROM faturamento_por_cliente
    ORDER BY total_gasto DESC
    LIMIT 10
)
SELECT
    ROUND(SUM(top_10.total_gasto), 2) AS faturamento_top10,
    ROUND((SELECT SUM(total_gasto) FROM faturamento_por_cliente), 2) AS faturamento_total,
    ROUND(100.0 * SUM(top_10.total_gasto) / (SELECT SUM(total_gasto) FROM faturamento_por_cliente), 2) AS pct_participacao_top10
FROM top_10;

-- 8. Novos clientes cadastrados por mês (evolução da base de clientes)
SELECT
    STRFTIME('%Y-%m', data_cadastro) AS mes_ano,
    COUNT(*) AS novos_clientes
FROM (
    -- remove duplicidades de cadastro (ver 02_tratamento.sql)
    SELECT MIN(id_cliente) AS id_cliente, nome_cliente, cidade, data_cadastro
    FROM clientes
    GROUP BY nome_cliente, cidade, data_cadastro
)
GROUP BY mes_ano
ORDER BY mes_ano;
