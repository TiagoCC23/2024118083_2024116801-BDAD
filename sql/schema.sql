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

--------------------
--  HOTEL_SERVICO
--------------------

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