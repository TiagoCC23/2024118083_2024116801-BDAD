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
    id_hotel INTEGER GENERATED ALWAYS AS IDENTITY,
    nome_hotel VARCHAR(150) NOT NULL,
    morada VARCHAR(200) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    pais VARCHAR(100) NOT NULL,
    telemovel VARCHAR(20)  NOT NULL,

    CONSTRAINT pk_hotel PRIMARY KEY (id_hotel),
    CONSTRAINT uq_hotel_nome UNIQUE (nome_hotel),
    CONSTRAINT chk_hotel_nome_nao_vazio CHECK (BTRIM(nome_hotel) <> ''),
    CONSTRAINT chk_hotel_telemovel_nao_vazio CHECK (BTRIM(telemovel) <> '')
);

--------------------
--     QUARTO
--------------------

--------------------
--   TIPO_QUARTO
--------------------

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
    CONSTRAINT chk_funcionario_telemovel_nao_vazio CHECK (BTRIM(telemovel) <> '')
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

    CONSTRAINT chk_datas_reserva CHECK (data_checkin < data_checkout),

)

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