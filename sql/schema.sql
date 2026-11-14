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

--------------------
--   FUNCIONARIO
--------------------

--------------------
--    RESERVA
--------------------

--------------------
-- RESERVA_QUARTO
--------------------

--------------------
-- RESERVA_SERVICO
--------------------

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