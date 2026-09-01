-- =====================================================================
-- 03_CONSULTAS_BASICAS.SQL
-- Objetivo: demonstrar domínio de SELECT, WHERE, ORDER BY, LIMIT,
-- DISTINCT, BETWEEN, IN, LIKE, IS NULL / IS NOT NULL, sempre com
-- contexto real de negócio.
-- =====================================================================

-- 1. Clientes de São Paulo (SP)
SELECT nome_cliente, cidade, estado
FROM clientes
WHERE estado = 'SP'
ORDER BY nome_cliente;

-- 2. Produtos com preço entre R$100 e R$500 (BETWEEN)
SELECT nome_produto, preco
FROM produtos
WHERE preco BETWEEN 100 AND 500
ORDER BY preco DESC;

-- 3. Pedidos realizados nos estados do Sudeste (IN)
SELECT p.id_pedido, c.nome_cliente, c.estado, p.data_pedido
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
WHERE c.estado IN ('SP', 'RJ', 'MG', 'ES')
ORDER BY p.data_pedido DESC
LIMIT 20;

-- 4. Produtos cujo nome contém "Smartphone" (LIKE)
SELECT nome_produto, preco
FROM produtos
WHERE nome_produto LIKE '%Smartphone%';

-- 5. Clientes sem e-mail cadastrado (IS NULL)
SELECT nome_cliente, cidade
FROM clientes
WHERE email IS NULL;

-- 6. Clientes com e-mail cadastrado (IS NOT NULL)
SELECT COUNT(*) AS clientes_com_email
FROM clientes
WHERE email IS NOT NULL;

-- 7. Lista de estados distintos com clientes cadastrados (DISTINCT)
SELECT DISTINCT estado
FROM clientes
ORDER BY estado;

-- 8. Os 10 produtos mais caros do catálogo (ORDER BY + LIMIT)
SELECT nome_produto, preco
FROM produtos
WHERE preco > 0
ORDER BY preco DESC
LIMIT 10;

-- 9. Os 10 produtos mais baratos do catálogo
SELECT nome_produto, preco
FROM produtos
WHERE preco > 0
ORDER BY preco ASC
LIMIT 10;

-- 10. Pedidos cancelados no ano de 2024
SELECT id_pedido, id_cliente, data_pedido, status_pedido
FROM pedidos
WHERE status_pedido = 'Cancelado'
  AND data_pedido BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY data_pedido;

-- 11. Pagamentos realizados via Pix
SELECT pg.id_pagamento, pg.id_pedido, pg.valor_pago, pg.status_pagamento
FROM pagamentos pg
WHERE pg.metodo_pagamento = 'Pix'
ORDER BY pg.valor_pago DESC
LIMIT 15;
