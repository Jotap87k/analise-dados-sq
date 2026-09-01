-- =====================================================================
-- 01_EXPLORACAO.SQL
-- Objetivo: fazer uma exploração inicial da base de dados (Data Overview)
-- para entender volume, período e abrangência dos dados antes de
-- qualquer análise mais aprofundada.
-- =====================================================================

-- 1. Quantidade de clientes cadastrados
SELECT COUNT(*) AS total_clientes
FROM clientes;

-- 2. Quantidade de produtos cadastrados
SELECT COUNT(*) AS total_produtos
FROM produtos;

-- 3. Quantidade de produtos ativos x inativos
SELECT ativo, COUNT(*) AS quantidade
FROM produtos
GROUP BY ativo;

-- 4. Quantidade de categorias existentes
SELECT COUNT(DISTINCT id_categoria) AS total_categorias
FROM categorias;

-- 5. Lista de categorias disponíveis
SELECT DISTINCT nome_categoria
FROM categorias
ORDER BY nome_categoria;

-- 6. Quantidade total de pedidos realizados
SELECT COUNT(*) AS total_pedidos
FROM pedidos;

-- 7. Período coberto pelos dados (primeira e última venda)
SELECT
    MIN(data_pedido) AS primeira_venda,
    MAX(data_pedido) AS ultima_venda
FROM pedidos;

-- 8. Distribuição dos pedidos por status
SELECT status_pedido, COUNT(*) AS quantidade
FROM pedidos
GROUP BY status_pedido
ORDER BY quantidade DESC;

-- 9. Quantidade total de itens vendidos (linhas em itens_pedido)
SELECT COUNT(*) AS total_itens_pedido
FROM itens_pedido;

-- 10. Faturamento bruto total (sem nenhum tratamento ainda, incluindo cancelados)
SELECT ROUND(SUM(quantidade * preco_unitario), 2) AS faturamento_bruto_total
FROM itens_pedido;

-- 11. Faixa de preços dos produtos (mínimo, máximo e médio)
SELECT
    ROUND(MIN(preco), 2) AS menor_preco,
    ROUND(MAX(preco), 2) AS maior_preco,
    ROUND(AVG(preco), 2) AS preco_medio
FROM produtos
WHERE preco > 0;  -- ignorando registro com erro de cadastro (preço negativo)

-- 12. Estados presentes na base de clientes
SELECT DISTINCT estado
FROM clientes
ORDER BY estado;

-- 13. Cidades com mais clientes cadastrados (top 10 - visão preliminar, sem tratamento)
SELECT cidade, COUNT(*) AS qtd_clientes
FROM clientes
GROUP BY cidade
ORDER BY qtd_clientes DESC
LIMIT 10;

-- 14. Métodos de pagamento existentes na base
SELECT DISTINCT metodo_pagamento
FROM pagamentos;

-- 15. Amostra rápida dos primeiros pedidos cadastrados
SELECT *
FROM pedidos
ORDER BY id_pedido
LIMIT 10;
