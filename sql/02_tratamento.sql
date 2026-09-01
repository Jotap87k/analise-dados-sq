-- =====================================================================
-- 02_TRATAMENTO.SQL
-- Objetivo: identificar e demonstrar o tratamento (Data Cleaning) dos
-- principais problemas de qualidade de dados encontrados na base.
-- Cada bloco identifica um problema e, em seguida, mostra como
-- consultá-lo/corrigi-lo via SQL.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. VALORES NULOS
-- Identificar clientes sem e-mail ou telefone cadastrado.
-- ---------------------------------------------------------------------
SELECT id_cliente, nome_cliente, email, telefone
FROM clientes
WHERE email IS NULL OR telefone IS NULL;

-- Quantificar o impacto (% de clientes com dado ausente)
SELECT
    ROUND(100.0 * SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_email_nulo,
    ROUND(100.0 * SUM(CASE WHEN telefone IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_telefone_nulo
FROM clientes;

-- Tratamento: substituir nulo por um valor padrão para exibição em relatórios
SELECT
    id_cliente,
    nome_cliente,
    COALESCE(email, 'não informado') AS email_tratado,
    COALESCE(telefone, 'não informado') AS telefone_tratado
FROM clientes;

-- ---------------------------------------------------------------------
-- 2. REGISTROS DUPLICADOS
-- Identificar clientes cadastrados mais de uma vez (mesmo nome, cidade
-- e data de cadastro, sugerindo cadastro duplicado).
-- ---------------------------------------------------------------------
SELECT nome_cliente, cidade, data_cadastro, COUNT(*) AS qtd_cadastros
FROM clientes
GROUP BY nome_cliente, cidade, data_cadastro
HAVING COUNT(*) > 1;

-- Tratamento: manter apenas o primeiro registro (menor id_cliente) de cada
-- duplicidade. A view abaixo simula a base "limpa" de clientes.
SELECT MIN(id_cliente) AS id_cliente_valido, nome_cliente, cidade, data_cadastro
FROM clientes
GROUP BY nome_cliente, cidade, data_cadastro;

-- ---------------------------------------------------------------------
-- 3. TEXTOS INCONSISTENTES (espaços extras e caixa alta/baixa)
-- Cidades e estados foram cadastrados com formatação inconsistente.
-- ---------------------------------------------------------------------
SELECT DISTINCT cidade
FROM clientes
WHERE cidade <> TRIM(cidade)          -- possui espaços extras
   OR cidade <> UPPER(SUBSTR(cidade,1,1)) || LOWER(SUBSTR(cidade,2));  -- fora do padrão "Capitalizado"

-- Tratamento: padronizar cidade (remover espaços + capitalizar) e estado (maiúsculo)
SELECT
    id_cliente,
    TRIM(cidade) AS cidade_tratada,
    UPPER(TRIM(estado)) AS estado_tratado
FROM clientes;

-- ---------------------------------------------------------------------
-- 4. VALORES NEGATIVOS OU INVÁLIDOS
-- Produto cadastrado com preço negativo (erro de cadastro).
-- ---------------------------------------------------------------------
SELECT id_produto, nome_produto, preco
FROM produtos
WHERE preco <= 0;

-- Itens de pedido com quantidade zerada ou negativa (erro de lançamento)
SELECT id_item, id_pedido, id_produto, quantidade
FROM itens_pedido
WHERE quantidade <= 0;

-- Tratamento: nas análises de faturamento, excluir esses registros inválidos
-- (essa é a regra aplicada em todos os scripts de análise 04, 05, 06 e 07)
SELECT COUNT(*) AS itens_invalidos_desconsiderados
FROM itens_pedido
WHERE quantidade <= 0;

-- ---------------------------------------------------------------------
-- 5. PEDIDOS CANCELADOS
-- Pedidos cancelados não devem entrar no cálculo de faturamento realizado,
-- mas são úteis para métricas de cancelamento.
-- ---------------------------------------------------------------------
SELECT
    COUNT(*) AS total_pedidos,
    SUM(CASE WHEN status_pedido = 'Cancelado' THEN 1 ELSE 0 END) AS pedidos_cancelados,
    ROUND(100.0 * SUM(CASE WHEN status_pedido = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_cancelamento
FROM pedidos;

-- ---------------------------------------------------------------------
-- 6. CONSISTÊNCIA DE RELACIONAMENTOS (registros órfãos)
-- Verificar se existem itens de pedido apontando para pedidos ou
-- produtos inexistentes (não deveria ocorrer, dado o uso de FOREIGN KEY,
-- mas é uma boa prática de auditoria de dados).
-- ---------------------------------------------------------------------
SELECT ip.id_item
FROM itens_pedido ip
LEFT JOIN pedidos p ON ip.id_pedido = p.id_pedido
WHERE p.id_pedido IS NULL;

SELECT ip.id_item
FROM itens_pedido ip
LEFT JOIN produtos pr ON ip.id_produto = pr.id_produto
WHERE pr.id_produto IS NULL;

-- ---------------------------------------------------------------------
-- RESUMO DO TRATAMENTO APLICADO NAS PRÓXIMAS ANÁLISES:
-- 1) e-mails/telefones nulos: tratados com COALESCE quando exibidos;
-- 2) clientes duplicados: agregados por (nome, cidade, data_cadastro);
-- 3) cidade/estado: padronizados com TRIM/UPPER;
-- 4) produtos com preço <= 0 e itens com quantidade <= 0: excluídos do
--    cálculo de faturamento (WHERE quantidade > 0 AND preco_unitario > 0);
-- 5) pedidos cancelados: excluídos das métricas de faturamento realizado
--    (WHERE status_pedido <> 'Cancelado').
-- =====================================================================
