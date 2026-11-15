-- psql -U postgres -d hotel_db -f schema.sql

BEGIN;

----------------------------------------------------------------------------
--    Limpeza para garantir recriação previsível da base de dados
----------------------------------------------------------------------------
DROP TABLE IF EXISTS pagamento CASCADE;
DROP TABLE IF EXISTS reserva_servico CASCADE;
DROP TABLE IF EXISTS reserva_quarto CASCADE;
DROP TABLE IF EXISTS reserva CASCADE;
DROP TABLE IF EXISTS funcionario CASCADE;
DROP TABLE IF EXISTS cliente CASCADE;
DROP TABLE IF EXISTS hotel_servico CASCADE;
DROP TABLE IF EXISTS servico CASCADE;
DROP TABLE IF EXISTS quarto CASCADE;
DROP TABLE IF EXISTS tipo_quarto CASCADE;
DROP TABLE IF EXISTS hotel CASCADE;

------------------
--    HOTEL
------------------
CREATE TABLE hotel (
    -- 'ALWAYS' impede que um INSERT manual dessincronize a contagem automática
    id_hotel INTEGER GENERATED ALWAYS AS IDENTITY,
    -- 'NOT NULL' garante que nenhum hotel seja cadastrado sem informações essenciais
    nome_hotel VARCHAR(150) NOT NULL,
    -- 'NOT NULL' protege de valores nulos
    morada VARCHAR(200) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    pais VARCHAR(100) NOT NULL,
    -- 'VARCHAR' para preservar o "+"
    telemovel VARCHAR(20) NOT NULL,

    CONSTRAINT pk_hotel PRIMARY KEY (id_hotel),
    -- 'UNIQUE' evita cadastro duplicado do nome hotel
    CONSTRAINT uq_hotel_nome UNIQUE (nome_hotel),
    -- 'BTRIM' remove espaços das pontas e garante que exista texto real preenchido
    CONSTRAINT chk_hotel_nome_nao_vazio CHECK (BTRIM(nome_hotel) != ''),
    CONSTRAINT chk_hotel_telemovel_nao_vazio CHECK (BTRIM(telemovel) != '')
);

--------------------
--     QUARTO
--------------------
CREATE TABLE quarto (
    id_quarto INTEGER GENERATED ALWAYS AS IDENTITY,
    id_hotel INTEGER NOT NULL,
    id_tipo_quarto INTEGER NOT NULL,
    num_quarto VARCHAR(10) NOT NULL,
    piso SMALLINT NOT NULL,
    estado_manutencao VARCHAR(20) NOT NULL DEFAULT 'livre_limpo',

    CONSTRAINT pk_quarto PRIMARY KEY (id_quarto),
    CONSTRAINT uq_quarto_hotel_num UNIQUE (id_hotel, num_quarto), --> D1
    CONSTRAINT fk_quarto_hotel FOREIGN KEY (id_hotel)
        REFERENCES hotel (id_hotel)
        ON DELETE RESTRICT
        ON UPDATE NO ACTION,
    CONSTRAINT fk_quarto_tipo_quarto FOREIGN KEY (id_tipo_quarto)
        REFERENCES tipo_quarto (id_tipo_quarto)
        ON DELETE RESTRICT
        ON UPDATE NO ACTION,
    CONSTRAINT chk_quarto_num_nao_vazio CHECK (BTRIM(num_quarto) != ''),
    CONSTRAINT chk_quarto_estado_manutencao CHECK (
        estado_manutencao IN ('livre_limpo', 'em_limpeza', 'em_manutencao') --> D10
    )
);

--------------------
--   TIPO_QUARTO
--------------------
CREATE TABLE tipo_quarto (
    id_tipo_quarto INTEGER GENERATED ALWAYS AS IDENTITY,
    nome_tipo VARCHAR(100) NOT NULL,
    descricao TEXT,
    capacidade_maxima INTEGER NOT NULL,
    preco_noite NUMERIC(10, 2) NOT NULL,

    CONSTRAINT pk_tipo_quarto PRIMARY KEY (id_tipo_quarto),
    CONSTRAINT uq_tipo_quarto_nome UNIQUE (nome_tipo),
    CONSTRAINT chk_tipo_quarto_capacidade CHECK (capacidade_maxima >= 1),
    CONSTRAINT chk_tipo_quarto_preco CHECK (preco_noite > 0) -- RN06
);

--------------------
--    SERVICO
--------------------
CREATE TABLE servico (
    id_servico INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    nome_servico VARCHAR(100) NOT NULL,
    preco_unitario NUMERIC(10, 2) NOT NULL CHECK (preco_unitario > 0),

    CONSTRAINT uq_servico_nome UNIQUE (nome_servico),
    CONSTRAINT chk_servico_nome_nao_vazio CHECK (BTRIM(nome_servico) <> '')
);

--------------------
--  HOTEL_SERVICO
--------------------
CREATE TABLE hotel_servico (
    id_hotel INTEGER NOT NULL,
    id_servico INTEGER NOT NULL,

    CONSTRAINT pk_hotel_servico PRIMARY KEY (id_hotel, id_servico),
    CONSTRAINT fk_hotel_servico_hotel FOREIGN KEY (id_hotel)
        REFERENCES hotel (id_hotel)
        ON DELETE CASCADE
        ON UPDATE NO ACTION,
    CONSTRAINT fk_hotel_servico_servico FOREIGN KEY (id_servico)
        REFERENCES servico (id_servico)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
);

--------------------
--    CLIENTE
--------------------
CREATE TABLE cliente (
    id_cliente INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    nome VARCHAR(150) NOT NULL,
    pais VARCHAR(100) NOT NULL,
    doc_identificacao VARCHAR(30) NOT NULL UNIQUE,
    nif VARCHAR(20) NOT NULL UNIQUE CHECK (nif ~ '^[0-9]+$'),
    email VARCHAR(100) NOT NULL UNIQUE CHECK (email LIKE '%@%'),
    telemovel VARCHAR(20) NOT NULL,

    CONSTRAINT chk_cliente_nome_nao_vazio CHECK (BTRIM(nome) <> ''),
    CONSTRAINT chk_cliente_telemovel_nao_vazio CHECK (BTRIM(telemovel) <> '')
);
--------------------
--   FUNCIONARIO
--------------------
CREATE TABLE funcionario (
    id_funcionario INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_hotel INTEGER NOT NULL REFERENCES hotel(id_hotel) ON DELETE RESTRICT,

    nome VARCHAR(150) NOT NULL,
    cargo VARCHAR(100) NOT NULL,
    data_contratacao DATE NOT NULL,
    nif VARCHAR(20) NOT NULL UNIQUE CHECK (nif ~ '^[0-9]+$'),
    email VARCHAR(100) NOT NULL UNIQUE CHECK (email LIKE '%@%'),
    telemovel VARCHAR(20) NOT NULL,

    CONSTRAINT chk_funcionario_nome_nao_vazio CHECK (BTRIM(nome) <> ''),
    CONSTRAINT chk_funcionario_telemovel_nao_vazio CHECK (BTRIM(telemovel) <> ''),
    CONSTRAINT chk_cargo_hotel CHECK (
        (Cargo = 'gestor_cadeia' AND ID_Hotel IS NULL) OR
        (Cargo IN ('rececionista', 'gestor_hotel') AND ID_Hotel IS NOT NULL)
    )

);

--------------------
--    RESERVA
--------------------
CREATE TABLE reserva (
    id_reserva INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente INTEGER NOT NULL REFERENCES cliente(id_cliente) ON DELETE RESTRICT,
    id_funcionario INTEGER NOT NULL REFERENCES funcionario(id_funcionario) ON DELETE SET NULL,
    num_quarto INTEGER NOT NULL REFERENCES quarto(num_quarto) ON DELETE CASCADE,

    estado_reserva  VARCHAR(20) NOT NULL DEFAULT 'pendente' 
    CHECK (Estado_Reserva IN ('pendente', 'confirmada', 'cancelada', 'concluida')),
    num_hospedes INTEGER NOT NULL CHECK (num_hospedes > 0 AND num_hospedes <= capacidade_maxima),
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_DATE,
    data_checkin DATE NOT NULL,
    data_checkout DATE NOT NULL,

    CONSTRAINT chk_datas_reserva CHECK (data_checkin < data_checkout)

);

--------------------
-- RESERVA_QUARTO
--------------------
CREATE TABLE reserva_quarto (
    id_reserva INTEGER NOT NULL REFERENCES reserva(id_reserva) ON DELETE CASCADE,
    num_quarto INTEGER NOT NULL REFERENCES quarto(num_quarto) ON DELETE CASCADE,

    PRIMARY KEY (id_reserva, num_quarto)
);

--------------------
-- RESERVA_SERVICO
--------------------
CREATE TABLE reserva_servico (
    id_reserva INTEGER NOT NULL REFERENCES reserva(id_reserva) ON DELETE CASCADE,
    id_servico INTEGER NOT NULL REFERENCES servico(id_servico) ON DELETE RESTRICT,

    data_servico DATE NOT NULL,
    quantidade INTEGER NOT NULL CHECK (quantidade >= 1),
    preco_aplicado DECIMAL(10, 2) NOT NULL CHECK (preco_aplicado > 0),

    PRIMARY KEY (id_reserva, id_servico)
);

--------------------
--    PAGAMENTO
--------------------
CREATE TABLE pagamento (
    id_pagamento INTEGER GENERATED ALWAYS AS IDENTITY,
    id_reserva INTEGER NOT NULL,
    numero_prestacao INTEGER NOT NULL,
    valor_prestacao NUMERIC(10, 2) NOT NULL,
    metodo_pagamento VARCHAR(20),
    estado_pagamento VARCHAR(20) NOT NULL DEFAULT 'pendente',
    data_prevista DATE NOT NULL,
    data_pagamento DATE,

    CONSTRAINT pk_pagamento PRIMARY KEY (id_pagamento),
    CONSTRAINT uq_pagamento_reserva_prestacao UNIQUE (id_reserva, numero_prestacao),
    CONSTRAINT fk_pagamento_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON DELETE RESTRICT
        ON UPDATE NO ACTION,
    CONSTRAINT chk_pagamento_prestacao CHECK (numero_prestacao >= 1),
    CONSTRAINT chk_pagamento_valor CHECK (valor_prestacao >= 0), -- RN06
    CONSTRAINT chk_pagamento_metodo CHECK (
        metodo_pagamento IS NULL OR metodo_pagamento IN (
            'dinheiro', 'cartao_credito', 'cartao_debito',
            'mbway', 'paypal', 'transferencia'
        )
    ),
    CONSTRAINT chk_pagamento_estado CHECK (
        estado_pagamento IN ('pendente', 'pago', 'reembolsado')
    ),
    CONSTRAINT chk_pagamento_pago_campos CHECK (
        estado_pagamento = 'pendente'
        OR (data_pagamento IS NOT NULL AND metodo_pagamento IS NOT NULL)
    )
);

COMMIT;