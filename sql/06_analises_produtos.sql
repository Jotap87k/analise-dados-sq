-- =====================================================================
-- 06_ANALISES_PRODUTOS.SQL
-- Objetivo: analisar o desempenho dos produtos e categorias -- mais
-- vendidos, mais lucrativos, com baixa performance, etc.
-- =====================================================================

-- 1. Top 10 produtos mais vendidos (por quantidade)
SELECT
    pr.nome_produto,
    SUM(ip.quantidade) AS quantidade_vendida
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN produtos pr ON pr.id_produto = ip.id_produto
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY pr.id_produto, pr.nome_produto
ORDER BY quantidade_vendida DESC
LIMIT 10;

-- 2. Top 10 produtos que mais geram receita
SELECT
    pr.nome_produto,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS receita
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN produtos pr ON pr.id_produto = ip.id_produto
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY pr.id_produto, pr.nome_produto
ORDER BY receita DESC
LIMIT 10;

-- 3. Produtos menos vendidos (excluindo os que nunca venderam - ver consulta 7)
SELECT
    pr.nome_produto,
    SUM(ip.quantidade) AS quantidade_vendida
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN produtos pr ON pr.id_produto = ip.id_produto
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY pr.id_produto, pr.nome_produto
ORDER BY quantidade_vendida ASC
LIMIT 10;

-- 4. Categorias mais lucrativas (receita total por categoria)
SELECT
    cat.nome_categoria,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS receita_categoria
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN produtos pr ON pr.id_produto = ip.id_produto
JOIN categorias cat ON cat.id_categoria = pr.id_categoria
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY cat.nome_categoria
ORDER BY receita_categoria DESC;

-- 5. Quantidade vendida por categoria
SELECT
    cat.nome_categoria,
    SUM(ip.quantidade) AS quantidade_total
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN produtos pr ON pr.id_produto = ip.id_produto
JOIN categorias cat ON cat.id_categoria = pr.id_categoria
WHERE p.status_pedido <> 'Cancelado'
  AND ip.quantidade > 0
GROUP BY cat.nome_categoria
ORDER BY quantidade_total DESC;

-- 6. Participação de cada produto na receita total (percentual)
WITH receita_produtos AS (
    SELECT
        pr.id_produto,
        pr.nome_produto,
        SUM(ip.quantidade * ip.preco_unitario) AS receita
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    JOIN produtos pr ON pr.id_produto = ip.id_produto
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY pr.id_produto, pr.nome_produto
)
SELECT
    nome_produto,
    ROUND(receita, 2) AS receita,
    ROUND(100.0 * receita / (SELECT SUM(receita) FROM receita_produtos), 2) AS pct_receita_total
FROM receita_produtos
ORDER BY receita DESC
LIMIT 15;

-- 7. Produtos ativos que NUNCA foram vendidos (baixa performance / encalhe)
SELECT
    pr.nome_produto,
    cat.nome_categoria,
    pr.preco
FROM produtos pr
JOIN categorias cat ON cat.id_categoria = pr.id_categoria
LEFT JOIN itens_pedido ip ON ip.id_produto = pr.id_produto AND ip.quantidade > 0
WHERE pr.ativo = 1
  AND pr.preco > 0
  AND ip.id_item IS NULL;

-- 8. Preço médio de venda por categoria
SELECT
    cat.nome_categoria,
    ROUND(AVG(ip.preco_unitario), 2) AS preco_medio_vendido
FROM itens_pedido ip
JOIN produtos pr ON pr.id_produto = ip.id_produto
JOIN categorias cat ON cat.id_categoria = pr.id_categoria
WHERE ip.quantidade > 0
GROUP BY cat.nome_categoria
ORDER BY preco_medio_vendido DESC;

-- 9. Produtos com queda de vendas entre os dois anos da base (2023 vs 2024)
WITH vendas_ano AS (
    SELECT
        pr.id_produto,
        pr.nome_produto,
        STRFTIME('%Y', p.data_pedido) AS ano,
        SUM(ip.quantidade) AS qtd_vendida
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    JOIN produtos pr ON pr.id_produto = ip.id_produto
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY pr.id_produto, pr.nome_produto, ano
)
SELECT
    v23.nome_produto,
    v23.qtd_vendida AS vendido_2023,
    COALESCE(v24.qtd_vendida, 0) AS vendido_2024,
    COALESCE(v24.qtd_vendida, 0) - v23.qtd_vendida AS variacao
FROM vendas_ano v23
LEFT JOIN vendas_ano v24 ON v24.id_produto = v23.id_produto AND v24.ano = '2024'
WHERE v23.ano = '2023'
ORDER BY variacao ASC
LIMIT 10;
