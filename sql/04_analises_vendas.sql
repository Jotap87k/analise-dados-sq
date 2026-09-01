-- =====================================================================
-- 04_ANALISES_VENDAS.SQL
-- Objetivo: responder às principais perguntas de negócio relacionadas a
-- vendas e faturamento. Utiliza GROUP BY, HAVING, agregações e JOINs.
--
-- REGRA DE NEGÓCIO aplicada em todas as consultas de faturamento:
--   - desconsiderar pedidos com status = 'Cancelado'
--   - desconsiderar itens com quantidade <= 0 (erro de lançamento)
-- =====================================================================

-- 1. Faturamento total realizado (excluindo cancelados e itens inválidos)
SELECT ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS faturamento_total
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0;

-- 2. Faturamento por mês/ano (evolução temporal)
SELECT
    STRFTIME('%Y-%m', p.data_pedido) AS mes_ano,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS faturamento
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY mes_ano
ORDER BY mes_ano;

-- 3. Mês com MAIOR faturamento
SELECT
    STRFTIME('%Y-%m', p.data_pedido) AS mes_ano,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS faturamento
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY mes_ano
ORDER BY faturamento DESC
LIMIT 1;

-- 4. Mês com MENOR faturamento
SELECT
    STRFTIME('%Y-%m', p.data_pedido) AS mes_ano,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS faturamento
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY mes_ano
ORDER BY faturamento ASC
LIMIT 1;

-- 5. Quantidade de pedidos válidos (não cancelados)
SELECT COUNT(*) AS total_pedidos_validos
FROM pedidos
WHERE status_pedido <> 'Cancelado';

-- 6. Ticket médio (faturamento total / quantidade de pedidos válidos)
SELECT
    ROUND(SUM(ip.quantidade * ip.preco_unitario) * 1.0 / COUNT(DISTINCT p.id_pedido), 2) AS ticket_medio
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0;

-- 7. Faturamento por estado (top estados que mais compram)
SELECT
    UPPER(TRIM(c.estado)) AS estado,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS faturamento
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN clientes c ON c.id_cliente = p.id_cliente
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY estado
ORDER BY faturamento DESC;

-- 8. Método de pagamento mais utilizado
SELECT
    metodo_pagamento,
    COUNT(*) AS quantidade_uso,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM pagamentos), 2) AS percentual
FROM pagamentos
GROUP BY metodo_pagamento
ORDER BY quantidade_uso DESC;

-- 9. Quantidade média de itens por pedido
SELECT
    ROUND(SUM(ip.quantidade) * 1.0 / COUNT(DISTINCT ip.id_pedido), 2) AS media_itens_por_pedido
FROM itens_pedido ip
WHERE ip.quantidade > 0;

-- 10. Faturamento por dia da semana (identificar dias de maior volume)
SELECT
    CASE STRFTIME('%w', p.data_pedido)
        WHEN '0' THEN 'Domingo'
        WHEN '1' THEN 'Segunda-feira'
        WHEN '2' THEN 'Terça-feira'
        WHEN '3' THEN 'Quarta-feira'
        WHEN '4' THEN 'Quinta-feira'
        WHEN '5' THEN 'Sexta-feira'
        WHEN '6' THEN 'Sábado'
    END AS dia_semana,
    COUNT(DISTINCT p.id_pedido) AS qtd_pedidos,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS faturamento
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY dia_semana
ORDER BY faturamento DESC;

-- 11. Faturamento por categoria de produto
SELECT
    cat.nome_categoria,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS faturamento
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN produtos pr ON pr.id_produto = ip.id_produto
JOIN categorias cat ON cat.id_categoria = pr.id_categoria
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY cat.nome_categoria
ORDER BY faturamento DESC;

-- 12. Categorias com faturamento acima da média (GROUP BY + HAVING)
SELECT
    cat.nome_categoria,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS faturamento
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN produtos pr ON pr.id_produto = ip.id_produto
JOIN categorias cat ON cat.id_categoria = pr.id_categoria
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY cat.nome_categoria
HAVING faturamento > (
    SELECT AVG(sub.faturamento_categoria)
    FROM (
        SELECT SUM(ip2.quantidade * ip2.preco_unitario) AS faturamento_categoria
        FROM itens_pedido ip2
        JOIN pedidos p2 ON p2.id_pedido = ip2.id_pedido
        JOIN produtos pr2 ON pr2.id_produto = ip2.id_produto
        WHERE p2.status_pedido <> 'Cancelado' AND ip2.quantidade > 0
        GROUP BY pr2.id_categoria
    ) sub
)
ORDER BY faturamento DESC;
