-- =====================================================================
-- 07_ANALISES_AVANCADAS.SQL
-- Objetivo: demonstrar SQL avançado (CTEs, subqueries, CASE WHEN e
-- funções de janela) sempre respondendo a uma pergunta de negócio real.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. RANKING DOS PRODUTOS por receita, usando RANK() e DENSE_RANK()
-- ---------------------------------------------------------------------
WITH receita_produtos AS (
    SELECT
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
    RANK() OVER (ORDER BY receita DESC) AS ranking,
    DENSE_RANK() OVER (ORDER BY receita DESC) AS ranking_denso
FROM receita_produtos
ORDER BY ranking
LIMIT 15;

-- ---------------------------------------------------------------------
-- 2. TOP 10 CLIENTES por faturamento, com ROW_NUMBER()
-- ---------------------------------------------------------------------
WITH gasto_clientes AS (
    SELECT
        c.nome_cliente,
        SUM(ip.quantidade * ip.preco_unitario) AS total_gasto
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    JOIN clientes c ON c.id_cliente = p.id_cliente
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY c.id_cliente, c.nome_cliente
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_gasto DESC) AS posicao,
    nome_cliente,
    ROUND(total_gasto, 2) AS total_gasto
FROM gasto_clientes
ORDER BY posicao
LIMIT 10;

-- ---------------------------------------------------------------------
-- 3. CRESCIMENTO MENSAL DO FATURAMENTO (LAG para comparar com mês anterior)
-- ---------------------------------------------------------------------
WITH faturamento_mensal AS (
    SELECT
        STRFTIME('%Y-%m', p.data_pedido) AS mes_ano,
        SUM(ip.quantidade * ip.preco_unitario) AS faturamento
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY mes_ano
)
SELECT
    mes_ano,
    ROUND(faturamento, 2) AS faturamento,
    ROUND(LAG(faturamento) OVER (ORDER BY mes_ano), 2) AS faturamento_mes_anterior,
    ROUND(
        100.0 * (faturamento - LAG(faturamento) OVER (ORDER BY mes_ano))
        / LAG(faturamento) OVER (ORDER BY mes_ano), 2
    ) AS crescimento_percentual
FROM faturamento_mensal
ORDER BY mes_ano;

-- ---------------------------------------------------------------------
-- 4. COMPARAÇÃO COM O PRÓXIMO MÊS (LEAD) -- útil para prever tendência
-- ---------------------------------------------------------------------
WITH faturamento_mensal AS (
    SELECT
        STRFTIME('%Y-%m', p.data_pedido) AS mes_ano,
        SUM(ip.quantidade * ip.preco_unitario) AS faturamento
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY mes_ano
)
SELECT
    mes_ano,
    ROUND(faturamento, 2) AS faturamento,
    ROUND(LEAD(faturamento) OVER (ORDER BY mes_ano), 2) AS faturamento_proximo_mes
FROM faturamento_mensal
ORDER BY mes_ano;

-- ---------------------------------------------------------------------
-- 5. PARTICIPAÇÃO PERCENTUAL DE CADA CATEGORIA NO FATURAMENTO TOTAL
-- ---------------------------------------------------------------------
WITH receita_categoria AS (
    SELECT
        cat.nome_categoria,
        SUM(ip.quantidade * ip.preco_unitario) AS receita
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    JOIN produtos pr ON pr.id_produto = ip.id_produto
    JOIN categorias cat ON cat.id_categoria = pr.id_categoria
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY cat.nome_categoria
)
SELECT
    nome_categoria,
    ROUND(receita, 2) AS receita,
    ROUND(100.0 * receita / SUM(receita) OVER (), 2) AS pct_participacao
FROM receita_categoria
ORDER BY receita DESC;

-- ---------------------------------------------------------------------
-- 6. RANKING DE PRODUTOS POR CATEGORIA (PARTITION BY)
-- Top 3 produtos mais vendidos DENTRO de cada categoria.
-- ---------------------------------------------------------------------
WITH vendas_produto_categoria AS (
    SELECT
        cat.nome_categoria,
        pr.nome_produto,
        SUM(ip.quantidade) AS qtd_vendida,
        SUM(ip.quantidade * ip.preco_unitario) AS receita
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    JOIN produtos pr ON pr.id_produto = ip.id_produto
    JOIN categorias cat ON cat.id_categoria = pr.id_categoria
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY cat.nome_categoria, pr.id_produto, pr.nome_produto
),
ranking AS (
    SELECT
        nome_categoria,
        nome_produto,
        qtd_vendida,
        ROUND(receita, 2) AS receita,
        RANK() OVER (PARTITION BY nome_categoria ORDER BY receita DESC) AS posicao_na_categoria
    FROM vendas_produto_categoria
)
SELECT *
FROM ranking
WHERE posicao_na_categoria <= 3
ORDER BY nome_categoria, posicao_na_categoria;

-- ---------------------------------------------------------------------
-- 7. CURVA ABC DE PRODUTOS (participação acumulada na receita)
-- Classifica produtos em A (até 80% da receita), B (até 95%) e C (restante),
-- técnica clássica de análise de portfólio de produtos.
-- ---------------------------------------------------------------------
WITH receita_produtos AS (
    SELECT
        pr.nome_produto,
        SUM(ip.quantidade * ip.preco_unitario) AS receita
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    JOIN produtos pr ON pr.id_produto = ip.id_produto
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY pr.id_produto, pr.nome_produto
),
receita_acumulada AS (
    SELECT
        nome_produto,
        receita,
        SUM(receita) OVER (ORDER BY receita DESC ROWS UNBOUNDED PRECEDING) AS receita_acumulada,
        SUM(receita) OVER () AS receita_total
    FROM receita_produtos
)
SELECT
    nome_produto,
    ROUND(receita, 2) AS receita,
    ROUND(100.0 * receita_acumulada / receita_total, 2) AS pct_acumulado,
    CASE
        WHEN 100.0 * receita_acumulada / receita_total <= 80 THEN 'A'
        WHEN 100.0 * receita_acumulada / receita_total <= 95 THEN 'B'
        ELSE 'C'
    END AS curva_abc
FROM receita_acumulada
ORDER BY receita DESC;

-- ---------------------------------------------------------------------
-- 8. PARTICIPAÇÃO DOS TOP 10 CLIENTES NO FATURAMENTO (subquery escalar)
-- ---------------------------------------------------------------------
WITH gasto_clientes AS (
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
)
SELECT
    nome_cliente,
    ROUND(total_gasto, 2) AS total_gasto,
    ROUND(100.0 * total_gasto / (SELECT SUM(total_gasto) FROM gasto_clientes), 2) AS pct_do_faturamento_total
FROM gasto_clientes
ORDER BY total_gasto DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- 9. CLASSIFICAÇÃO DE CLIENTES POR FAIXA DE GASTO (CASE WHEN)
-- Segmenta os clientes em Bronze, Prata, Ouro e Diamante.
-- ---------------------------------------------------------------------
WITH gasto_clientes AS (
    SELECT
        c.nome_cliente,
        SUM(ip.quantidade * ip.preco_unitario) AS total_gasto
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    JOIN clientes c ON c.id_cliente = p.id_cliente
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY c.id_cliente, c.nome_cliente
)
SELECT
    CASE
        WHEN total_gasto >= 3000 THEN 'Diamante'
        WHEN total_gasto >= 1500 THEN 'Ouro'
        WHEN total_gasto >= 500  THEN 'Prata'
        ELSE 'Bronze'
    END AS segmento,
    COUNT(*) AS qtd_clientes,
    ROUND(SUM(total_gasto), 2) AS receita_segmento,
    ROUND(AVG(total_gasto), 2) AS gasto_medio_segmento
FROM gasto_clientes
GROUP BY segmento
ORDER BY receita_segmento DESC;

-- ---------------------------------------------------------------------
-- 10. MÉDIA MÓVEL DE 3 MESES DO FATURAMENTO (janela deslizante)
-- Suaviza a sazonalidade para visualizar melhor a tendência de vendas.
-- ---------------------------------------------------------------------
WITH faturamento_mensal AS (
    SELECT
        STRFTIME('%Y-%m', p.data_pedido) AS mes_ano,
        SUM(ip.quantidade * ip.preco_unitario) AS faturamento
    FROM itens_pedido ip
    JOIN pedidos p ON p.id_pedido = ip.id_pedido
    WHERE p.status_pedido <> 'Cancelado'
      AND ip.quantidade > 0
    GROUP BY mes_ano
)
SELECT
    mes_ano,
    ROUND(faturamento, 2) AS faturamento,
    ROUND(
        AVG(faturamento) OVER (ORDER BY mes_ano ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2
    ) AS media_movel_3_meses
FROM faturamento_mensal
ORDER BY mes_ano;
