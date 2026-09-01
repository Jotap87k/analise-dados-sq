"""
gerar_dados.py
==============
Script responsável por:
1. Criar o banco de dados SQLite (database/banco.db) a partir do schema.sql
2. Popular o banco com dados realistas de uma loja de e-commerce fictícia
3. Inserir propositalmente algumas inconsistências de dados
   (nulos, duplicados, textos inconsistentes) para permitirmos demonstrar
   o processo de Data Cleaning em SQL.
4. Exportar os dados brutos gerados para data/raw/ em formato CSV.

Uso:
    python scripts/gerar_dados.py

Não depende de nenhuma biblioteca externa (apenas biblioteca padrão do Python).
"""

import csv
import os
import random
import sqlite3
from datetime import date, datetime, timedelta

# ---------------------------------------------------------------------------
# Configurações gerais
# ---------------------------------------------------------------------------
random.seed(42)  # reprodutibilidade: sempre gera os mesmos dados

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(BASE_DIR, "database", "banco.db")
SCHEMA_PATH = os.path.join(BASE_DIR, "database", "schema.sql")
RAW_DIR = os.path.join(BASE_DIR, "data", "raw")

DATA_INICIO = date(2023, 1, 1)
DATA_FIM = date(2024, 12, 31)

N_CLIENTES = 180
N_PRODUTOS = 90
N_PEDIDOS = 3200

# ---------------------------------------------------------------------------
# Dados de referência (listas realistas em português)
# ---------------------------------------------------------------------------
CATEGORIAS = [
    "Eletrônicos", "Informática", "Celulares e Smartphones", "Moda Masculina",
    "Moda Feminina", "Casa e Decoração", "Eletrodomésticos", "Esporte e Lazer",
    "Livros", "Beleza e Perfumaria", "Brinquedos", "Papelaria",
]

PRODUTOS_POR_CATEGORIA = {
    "Eletrônicos": ["Fone de Ouvido Bluetooth", "Caixa de Som Portátil", "Smartwatch",
                    "TV LED 43''", "TV LED 50''", "Soundbar", "Câmera de Segurança",
                    "Carregador Portátil 10000mAh"],
    "Informática": ["Notebook 15''", "Mouse sem Fio", "Teclado Mecânico", "Monitor 24''",
                    "SSD 480GB", "HD Externo 1TB", "Webcam Full HD", "Cadeira Gamer"],
    "Celulares e Smartphones": ["Smartphone 128GB", "Smartphone 256GB", "Capinha de Celular",
                                 "Película de Vidro", "Fone com Fio", "Carregador Turbo"],
    "Moda Masculina": ["Camiseta Básica", "Calça Jeans", "Jaqueta Corta-Vento", "Bermuda",
                        "Tênis Casual", "Boné"],
    "Moda Feminina": ["Vestido Casual", "Blusa Feminina", "Calça Legging", "Sandália",
                       "Bolsa Transversal", "Óculos de Sol"],
    "Casa e Decoração": ["Jogo de Panelas", "Kit de Toalhas", "Luminária de Mesa",
                          "Almofada Decorativa", "Tapete para Sala", "Organizador de Gaveta"],
    "Eletrodomésticos": ["Liquidificador", "Air Fryer 4L", "Cafeteira Elétrica",
                          "Ferro de Passar", "Aspirador de Pó Portátil", "Ventilador de Mesa"],
    "Esporte e Lazer": ["Bicicleta Aro 29", "Bola de Futebol", "Kit Halteres",
                         "Tapete de Yoga", "Garrafa Térmica", "Mochila Esportiva"],
    "Livros": ["Romance Best-seller", "Livro de Autoajuda", "Livro Técnico de TI",
               "Quadrinhos", "Livro Infantil"],
    "Beleza e Perfumaria": ["Perfume 100ml", "Kit Shampoo e Condicionador",
                             "Creme Hidratante", "Batom Matte", "Secador de Cabelo"],
    "Brinquedos": ["Boneca Articulada", "Carrinho de Controle Remoto", "Quebra-Cabeça 500pçs",
                   "Jogo de Tabuleiro", "Pelúcia Grande"],
    "Papelaria": ["Caderno Universitário", "Kit de Canetas", "Mochila Escolar",
                  "Agenda 2024", "Estojo Escolar"],
}

NOMES = ["Ana", "Bruno", "Carla", "Daniel", "Eduarda", "Felipe", "Gabriela", "Hugo",
         "Isabela", "João", "Karina", "Lucas", "Mariana", "Nicolas", "Otávio", "Patrícia",
         "Rafael", "Sabrina", "Thiago", "Vanessa", "William", "Yasmin", "Alexandre",
         "Beatriz", "Caio", "Débora", "Enzo", "Fernanda", "Gustavo", "Helena", "Igor",
         "Juliana", "Kevin", "Larissa", "Marcelo", "Natália", "Paulo", "Renata", "Samuel",
         "Tatiane"]

SOBRENOMES = ["Silva", "Santos", "Oliveira", "Souza", "Rodrigues", "Ferreira", "Alves",
              "Pereira", "Lima", "Gomes", "Costa", "Ribeiro", "Martins", "Carvalho",
              "Almeida", "Lopes", "Soares", "Fernandes", "Vieira", "Barbosa"]

CIDADES_ESTADOS = [
    ("São Paulo", "SP"), ("Rio de Janeiro", "RJ"), ("Belo Horizonte", "MG"),
    ("Salvador", "BA"), ("Curitiba", "PR"), ("Porto Alegre", "RS"),
    ("Recife", "PE"), ("Fortaleza", "CE"), ("Brasília", "DF"),
    ("Manaus", "AM"), ("Goiânia", "GO"), ("Belém", "PA"),
    ("Campinas", "SP"), ("Florianópolis", "SC"), ("Vitória", "ES"),
    ("Natal", "RN"), ("João Pessoa", "PB"), ("Uberlândia", "MG"),
]

STATUS_PEDIDO = ["Entregue"] * 70 + ["Enviado"] * 12 + ["Em processamento"] * 10 + ["Cancelado"] * 8
METODOS_PAGAMENTO = ["Cartão de Crédito"] * 45 + ["Pix"] * 35 + ["Boleto"] * 12 + ["Cartão de Débito"] * 8
STATUS_PAGAMENTO_OK = ["Aprovado"] * 95 + ["Pendente"] * 5


def data_aleatoria(inicio, fim):
    """Gera uma data aleatória entre duas datas, com leve sazonalidade
    (mais vendas em maio, novembro (Black Friday) e dezembro)."""
    delta = (fim - inicio).days
    for _ in range(5):
        offset = random.randint(0, delta)
        d = inicio + timedelta(days=offset)
        peso = 1.0
        if d.month == 11:
            peso = 2.2  # Black Friday
        elif d.month == 12:
            peso = 1.6  # Natal
        elif d.month == 5:
            peso = 1.3  # Dia das mães
        if random.random() < peso / 2.2:
            return d
    return inicio + timedelta(days=random.randint(0, delta))


def gerar_clientes(cursor):
    clientes = []
    nomes_usados = set()
    for i in range(1, N_CLIENTES + 1):
        nome = f"{random.choice(NOMES)} {random.choice(SOBRENOMES)}"
        cidade, estado = random.choice(CIDADES_ESTADOS)

        # e-mail: às vezes nulo (problema proposital de dado ausente)
        if random.random() < 0.06:
            email = None
        else:
            email = f"{nome.lower().replace(' ', '.')}{i}@email.com"

        # telefone: às vezes nulo
        telefone = None if random.random() < 0.08 else f"(11) 9{random.randint(1000,9999)}-{random.randint(1000,9999)}"

        # inconsistência proposital de texto: cidade/estado às vezes com
        # espaços extras, caixa alta ou minúscula
        cidade_txt = cidade
        estado_txt = estado
        r = random.random()
        if r < 0.05:
            cidade_txt = cidade.upper()
        elif r < 0.10:
            cidade_txt = f" {cidade.lower()} "
        if random.random() < 0.05:
            estado_txt = estado.lower()

        data_cad = data_aleatoria(DATA_INICIO, DATA_FIM).isoformat()

        clientes.append((nome, email, telefone, cidade_txt, estado_txt, data_cad))
        nomes_usados.add(nome)

    # duplicidade proposital: duplicar alguns clientes (cadastro repetido)
    duplicados = random.sample(clientes, 6)
    clientes.extend(duplicados)

    cursor.executemany(
        """INSERT INTO clientes (nome_cliente, email, telefone, cidade, estado, data_cadastro)
           VALUES (?, ?, ?, ?, ?, ?)""",
        clientes,
    )
    return len(clientes)


def gerar_categorias_e_produtos(cursor):
    cat_ids = {}
    for nome_cat in CATEGORIAS:
        cursor.execute("INSERT INTO categorias (nome_categoria) VALUES (?)", (nome_cat,))
        cat_ids[nome_cat] = cursor.lastrowid

    produtos = []
    for nome_cat, lista_produtos in PRODUTOS_POR_CATEGORIA.items():
        for nome_prod in lista_produtos:
            preco_base = round(random.uniform(19.9, 3499.9), 2)
            ativo = 1 if random.random() > 0.05 else 0  # ~5% de produtos inativos
            produtos.append((nome_prod, cat_ids[nome_cat], preco_base, ativo))

    # completar até N_PRODUTOS reaproveitando produtos com variações de nome
    while len(produtos) < N_PRODUTOS:
        nome_cat = random.choice(CATEGORIAS)
        base = random.choice(PRODUTOS_POR_CATEGORIA[nome_cat])
        variacao = random.choice(["Premium", "Compacto", "Pro", "Slim", "2.0", "Plus"])
        nome_prod = f"{base} {variacao}"
        preco_base = round(random.uniform(19.9, 3499.9), 2)
        ativo = 1 if random.random() > 0.05 else 0
        produtos.append((nome_prod, cat_ids[nome_cat], preco_base, ativo))

    # um produto propositalmente com preço negativo (erro de cadastro)
    produtos.append(("Produto com Erro de Cadastro", cat_ids[CATEGORIAS[0]], -49.9, 1))

    cursor.executemany(
        "INSERT INTO produtos (nome_produto, id_categoria, preco, ativo) VALUES (?, ?, ?, ?)",
        produtos,
    )
    return len(produtos)


def gerar_pedidos_itens_pagamentos(cursor, n_clientes, n_produtos):
    # busca ids reais de clientes e produtos ativos com preço válido para venda
    cursor.execute("SELECT id_cliente FROM clientes")
    clientes_ids = [r[0] for r in cursor.fetchall()]

    cursor.execute("SELECT id_produto, preco FROM produtos WHERE ativo = 1 AND preco > 0")
    produtos_validos = cursor.fetchall()

    pedidos_batch = []
    for _ in range(N_PEDIDOS):
        id_cliente = random.choice(clientes_ids)
        d = data_aleatoria(DATA_INICIO, DATA_FIM).isoformat()
        status = random.choice(STATUS_PEDIDO)
        pedidos_batch.append((id_cliente, d, status))

    cursor.executemany(
        "INSERT INTO pedidos (id_cliente, data_pedido, status_pedido) VALUES (?, ?, ?)",
        pedidos_batch,
    )

    cursor.execute("SELECT id_pedido, status_pedido FROM pedidos")
    pedidos_criados = cursor.fetchall()

    itens_batch = []
    pagamentos_batch = []

    for id_pedido, status_pedido in pedidos_criados:
        n_itens = random.choices([1, 2, 3, 4, 5], weights=[35, 30, 18, 10, 7])[0]
        valor_total_pedido = 0.0
        produtos_do_pedido = random.sample(produtos_validos, min(n_itens, len(produtos_validos)))

        for id_produto, preco in produtos_do_pedido:
            quantidade = random.choices([1, 2, 3, 4], weights=[60, 25, 10, 5])[0]

            # erro proposital: alguns itens com quantidade zerada/negativa (registro inválido)
            if random.random() < 0.01:
                quantidade = random.choice([0, -1])

            preco_unit = preco
            itens_batch.append((id_pedido, id_produto, quantidade, preco_unit))
            if quantidade > 0:
                valor_total_pedido += quantidade * preco_unit

        # pagamento: cancelados tendem a estar Recusado/Pendente
        metodo = random.choice(METODOS_PAGAMENTO)
        if status_pedido == "Cancelado":
            status_pag = random.choice(["Recusado", "Pendente"])
        else:
            status_pag = random.choice(STATUS_PAGAMENTO_OK)

        valor_pago = round(valor_total_pedido, 2)
        pagamentos_batch.append((id_pedido, metodo, valor_pago, status_pag))

    cursor.executemany(
        """INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_unitario)
           VALUES (?, ?, ?, ?)""",
        itens_batch,
    )
    cursor.executemany(
        """INSERT INTO pagamentos (id_pedido, metodo_pagamento, valor_pago, status_pagamento)
           VALUES (?, ?, ?, ?)""",
        pagamentos_batch,
    )

    return len(pedidos_criados), len(itens_batch), len(pagamentos_batch)


def exportar_csv(cursor):
    os.makedirs(RAW_DIR, exist_ok=True)
    tabelas = ["categorias", "produtos", "clientes", "pedidos", "itens_pedido", "pagamentos"]
    for tabela in tabelas:
        cursor.execute(f"SELECT * FROM {tabela}")
        colunas = [desc[0] for desc in cursor.description]
        linhas = cursor.fetchall()
        caminho_csv = os.path.join(RAW_DIR, f"{tabela}.csv")
        with open(caminho_csv, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(colunas)
            writer.writerows(linhas)


def main():
    print("=" * 60)
    print("Gerando o banco de dados: analise-dados-sql")
    print("=" * 60)

    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        print(f"Banco antigo removido: {DB_PATH}")

    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    print("1/5 - Criando estrutura do banco (schema.sql)...")
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        cursor.executescript(f.read())

    print("2/5 - Gerando clientes...")
    n_clientes = gerar_clientes(cursor)
    print(f"      {n_clientes} clientes inseridos.")

    print("3/5 - Gerando categorias e produtos...")
    n_produtos = gerar_categorias_e_produtos(cursor)
    print(f"      {len(CATEGORIAS)} categorias e {n_produtos} produtos inseridos.")

    print("4/5 - Gerando pedidos, itens e pagamentos...")
    n_pedidos, n_itens, n_pagamentos = gerar_pedidos_itens_pagamentos(cursor, n_clientes, n_produtos)
    print(f"      {n_pedidos} pedidos, {n_itens} itens e {n_pagamentos} pagamentos inseridos.")

    conn.commit()

    print("5/5 - Exportando dados brutos para data/raw/ (CSV)...")
    exportar_csv(cursor)

    conn.close()
    print("-" * 60)
    print(f"Banco de dados criado com sucesso em: {DB_PATH}")
    print("Projeto pronto para ser explorado com os scripts em sql/")
    print("=" * 60)


if __name__ == "__main__":
    main()
