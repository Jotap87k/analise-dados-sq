-- =====================================================================
-- SCHEMA.SQL
-- Projeto: Análise de Dados com SQL (E-commerce)
-- Banco: SQLite
-- Descrição: criação das tabelas, chaves primárias, chaves estrangeiras
--            e relacionamentos do banco de dados.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- Tabela: categorias
-- Armazena as categorias de produtos vendidos pela loja.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS categorias;
CREATE TABLE categorias (
    id_categoria     INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_categoria   TEXT NOT NULL
);

-- ---------------------------------------------------------------------
-- Tabela: produtos
-- Armazena os produtos disponíveis para venda.
-- Relaciona-se com categorias (N:1).
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS produtos;
CREATE TABLE produtos (
    id_produto       INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_produto     TEXT NOT NULL,
    id_categoria     INTEGER NOT NULL,
    preco            REAL NOT NULL,
    ativo            INTEGER NOT NULL DEFAULT 1,  -- 1 = ativo / 0 = inativo
    FOREIGN KEY (id_categoria) REFERENCES categorias (id_categoria)
);

-- ---------------------------------------------------------------------
-- Tabela: clientes
-- Armazena os clientes cadastrados na loja.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS clientes;
CREATE TABLE clientes (
    id_cliente       INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_cliente     TEXT NOT NULL,
    email            TEXT,
    telefone         TEXT,
    cidade           TEXT,
    estado           TEXT,
    data_cadastro    TEXT NOT NULL      -- formato YYYY-MM-DD
);

-- ---------------------------------------------------------------------
-- Tabela: pedidos
-- Armazena os pedidos realizados pelos clientes.
-- Relaciona-se com clientes (N:1).
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS pedidos;
CREATE TABLE pedidos (
    id_pedido        INTEGER PRIMARY KEY AUTOINCREMENT,
    id_cliente       INTEGER NOT NULL,
    data_pedido      TEXT NOT NULL,     -- formato YYYY-MM-DD
    status_pedido    TEXT NOT NULL,     -- Entregue, Cancelado, Em processamento, Enviado
    FOREIGN KEY (id_cliente) REFERENCES clientes (id_cliente)
);

-- ---------------------------------------------------------------------
-- Tabela: itens_pedido
-- Armazena os itens (produtos) de cada pedido.
-- Relaciona-se com pedidos (N:1) e produtos (N:1).
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS itens_pedido;
CREATE TABLE itens_pedido (
    id_item          INTEGER PRIMARY KEY AUTOINCREMENT,
    id_pedido        INTEGER NOT NULL,
    id_produto       INTEGER NOT NULL,
    quantidade       INTEGER NOT NULL,
    preco_unitario   REAL NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos (id_pedido),
    FOREIGN KEY (id_produto) REFERENCES produtos (id_produto)
);

-- ---------------------------------------------------------------------
-- Tabela: pagamentos
-- Armazena a forma de pagamento de cada pedido.
-- Relaciona-se com pedidos (1:1).
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS pagamentos;
CREATE TABLE pagamentos (
    id_pagamento         INTEGER PRIMARY KEY AUTOINCREMENT,
    id_pedido            INTEGER NOT NULL,
    metodo_pagamento     TEXT NOT NULL,   -- Cartão de Crédito, Pix, Boleto, Cartão de Débito
    valor_pago           REAL NOT NULL,
    status_pagamento     TEXT NOT NULL,   -- Aprovado, Pendente, Recusado
    FOREIGN KEY (id_pedido) REFERENCES pedidos (id_pedido)
);

-- ---------------------------------------------------------------------
-- Índices para melhorar a performance das consultas mais comuns
-- ---------------------------------------------------------------------
CREATE INDEX idx_pedidos_cliente ON pedidos (id_cliente);
CREATE INDEX idx_pedidos_data ON pedidos (data_pedido);
CREATE INDEX idx_itens_pedido ON itens_pedido (id_pedido);
CREATE INDEX idx_itens_produto ON itens_pedido (id_produto);
CREATE INDEX idx_produtos_categoria ON produtos (id_categoria);
CREATE INDEX idx_pagamentos_pedido ON pagamentos (id_pedido);
