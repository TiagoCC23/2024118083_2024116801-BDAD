--psql -U postgres -d hotel_db -f seed.sql

-- ============================================================================
-- 6.4. Dados — Povoamento inicial da base de dados
-- Contexto A: Cadeia de Hotéis
-- SGBD: PostgreSQL
-- Pré-requisito: executar sql/schema.sql
-- ============================================================================

BEGIN;

-- Limpeza idempotente com reinício das sequências IDENTITY
TRUNCATE TABLE
    pagamento,
    reserva_servico,
    reserva_quarto,
    reserva,
    funcionario,
    cliente,
    hotel_servico,
    servico,
    quarto,
    tipo_quarto,
    hotel
RESTART IDENTITY CASCADE;

-- ----------------------------------------------------------------------------
-- 1. HOTEL (3 unidades da cadeia)
-- ----------------------------------------------------------------------------
INSERT INTO hotel (nome_hotel, morada, cidade, pais, telefone) VALUES
    ('Hotel UFP Porto',   'Rua da Boavista, 420',       'Porto',    'Portugal', '+351220100100'),
    ('Hotel UFP Lisboa',  'Av. da Liberdade, 185',      'Lisboa',   'Portugal', '+351210200200'),
    ('Hotel UFP Algarve', 'Av. Infante de Sagres, 78',  'Quarteira','Portugal', '+351289300300');

-- ----------------------------------------------------------------------------
-- 2. TIPO_QUARTO (4 tipologias com capacidades e tarifas distintas)
-- ----------------------------------------------------------------------------
INSERT INTO tipo_quarto (nome_tipo, descricao, capacidade_maxima, preco_noite) VALUES
    ('Single Standard', 'Quarto individual funcional com secretária',                 1,  65.00),
    ('Duplo Standard',  'Quarto com cama de casal e casa de banho privativa',         2,  95.00),
    ('Twin Superior',   'Quarto com duas camas individuais e varanda',                2, 115.00),
    ('Suite Familiar',  'Suite ampla com quarto principal, sala de estar e sofá-cama',4, 180.00);

-- ----------------------------------------------------------------------------
-- 3. QUARTO (12 quartos; reutilização de num_quarto entre hotéis - D1)
-- ----------------------------------------------------------------------------
INSERT INTO quarto (id_hotel, id_tipo_quarto, num_quarto, piso, estado_manutencao) VALUES
    -- Hotel UFP Porto
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Porto'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Single Standard'), '101', 1, 'livre_limpo'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Porto'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Duplo Standard'),  '102', 1, 'livre_limpo'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Porto'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Twin Superior'),   '201', 2, 'em_limpeza'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Porto'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Suite Familiar'),  '301', 3, 'livre_limpo'),

    -- Hotel UFP Lisboa (inclui piso 0 e quarto em manutenção)
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Lisboa'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Single Standard'), '001', 0, 'livre_limpo'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Lisboa'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Duplo Standard'),  '101', 1, 'livre_limpo'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Lisboa'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Twin Superior'),   '102', 1, 'em_manutencao'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Lisboa'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Suite Familiar'),  '201', 2, 'livre_limpo'),

    -- Hotel UFP Algarve
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Algarve'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Duplo Standard'),  '101', 1, 'livre_limpo'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Algarve'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Duplo Standard'),  '102', 1, 'livre_limpo'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Algarve'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Twin Superior'),   '201', 2, 'livre_limpo'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Algarve'),
     (SELECT id_tipo_quarto FROM tipo_quarto WHERE nome_tipo = 'Suite Familiar'),  '202', 2, 'livre_limpo');

-- ----------------------------------------------------------------------------
-- 4. SERVICO (5 serviços; 'Late Check-out' fica sem reservas para testar Q04)
-- ----------------------------------------------------------------------------
INSERT INTO servico (nome_servico, preco_unitario) VALUES
    ('Pequeno-Almoço Buffet',  14.00),
    ('Transfer Aeroporto',     35.00),
    ('Acesso Spa',             25.00),
    ('Estacionamento Privado', 12.00),
    ('Late Check-out',         30.00);

-- ----------------------------------------------------------------------------
-- 5. HOTEL_SERVICO (oferta diferenciada por unidade hoteleira - D6)
-- ----------------------------------------------------------------------------
INSERT INTO hotel_servico (id_hotel, id_servico)
SELECT h.id_hotel, s.id_servico
FROM hotel h
JOIN servico s ON (
    (h.nome_hotel = 'Hotel UFP Porto'   AND s.nome_servico IN ('Pequeno-Almoço Buffet', 'Transfer Aeroporto', 'Estacionamento Privado', 'Late Check-out'))
    OR
    (h.nome_hotel = 'Hotel UFP Lisboa'  AND s.nome_servico IN ('Pequeno-Almoço Buffet', 'Transfer Aeroporto', 'Acesso Spa', 'Estacionamento Privado', 'Late Check-out'))
    OR
    (h.nome_hotel = 'Hotel UFP Algarve' AND s.nome_servico IN ('Pequeno-Almoço Buffet', 'Acesso Spa', 'Estacionamento Privado'))
);

-- ----------------------------------------------------------------------------
-- 6. CLIENTE (clientes nacionais e estrangeiros + cliente sem reservas)
-- ----------------------------------------------------------------------------
INSERT INTO cliente (nome, nif, doc_identificacao, email, telefone, pais) VALUES
    ('Ana Ferreira',   '245678901',     'CC14589012',   'ana.ferreira@email.pt',     '+351912345001', 'Portugal'),
    ('Bruno Costa',    '234567892',     'CC22334455',   'bruno.costa@email.pt',      '+351912345002', 'Portugal'),
    ('Carla Mendes',   '256789013',     'CC33445566',   'carla.mendes@email.pt',     '+351912345003', 'Portugal'),
    ('Carlos García',  'ESX9876543A',   'PASS-ES-8821', 'carlos.garcia@correo.es',   '+34611223344',  'Espanha'),
    ('Sophie Martin',  'FR77889900112', 'PASS-FR-4410', 'sophie.martin@mail.fr',     '+33612345678',  'França'),
    ('John Smith',     'GB554433221',   'PASS-UK-9901', 'john.smith@example.co.uk',  '+447700900123', 'Reino Unido'),
    ('Mariana Lopes',  '267890124',     'CC44556677',   'mariana.lopes@email.pt',    '+351912345007', 'Portugal');

-- ----------------------------------------------------------------------------
-- 7. FUNCIONARIO (cobrindo os 3 cargos da RN08)
-- ----------------------------------------------------------------------------
INSERT INTO funcionario (id_hotel, nome, nif, email, telefone, cargo, data_contratacao) VALUES
    -- gestor_cadeia com id_hotel NULL (RN08)
    (NULL, 'Beatriz Almeida', '211111111', 'beatriz.almeida@hotelufp.pt', '+351910000001', 'gestor_cadeia', '2022-01-10'),
    -- restantes cargos com id_hotel obrigatório (RN08)
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Porto'),
     'Diogo Nogueira',  '222222222', 'diogo.nogueira@hotelufp.pt',  '+351910000002', 'gestor_hotel', '2022-03-01'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Porto'),
     'Inês Carvalho',   '233333333', 'ines.carvalho@hotelufp.pt',   '+351910000003', 'rececionista', '2023-06-15'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Lisboa'),
     'Tiago Pereira',   '244444444', 'tiago.pereira@hotelufp.pt',   '+351910000004', 'gestor_hotel', '2022-05-20'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Lisboa'),
     'Sofia Ribeiro',   '255555555', 'sofia.ribeiro@hotelufp.pt',   '+351910000005', 'rececionista', '2024-02-01'),
    ((SELECT id_hotel FROM hotel WHERE nome_hotel = 'Hotel UFP Algarve'),
     'Miguel Tavares',  '266666666', 'miguel.tavares@hotelufp.pt',  '+351910000006', 'rececionista', '2024-04-10');

-- ----------------------------------------------------------------------------
-- 8. RESERVA (10 reservas cobrindo todos os estados e cenários de teste)
-- ----------------------------------------------------------------------------
INSERT INTO reserva (id_cliente, id_funcionario, data_criacao, data_checkin, data_checkout, estado_reserva, num_hospedes) VALUES
    -- R1: Porto, concluída, pagamentos fracionados
    ((SELECT id_cliente FROM cliente WHERE nif = '245678901'),
     (SELECT id_funcionario FROM funcionario WHERE email = 'ines.carvalho@hotelufp.pt'),
     '2026-05-20', '2026-06-10', '2026-06-14', 'concluida', 2),

    -- R2: Porto, cancelada, reserva online sem funcionário (D7) e reembolsada
    ((SELECT id_cliente FROM cliente WHERE nif = '234567892'),
     NULL,
     '2026-06-15', '2026-07-01', '2026-07-04', 'cancelada', 1),

    -- R3: Porto, concluída nas mesmas datas de R2 (valida que cancelada não ocupa quarto - RN03)
    ((SELECT id_cliente FROM cliente WHERE nif = '256789013'),
     (SELECT id_funcionario FROM funcionario WHERE email = 'ines.carvalho@hotelufp.pt'),
     '2026-06-20', '2026-07-02', '2026-07-05', 'concluida', 1),

    -- R4: Lisboa, concluída, reserva multi-quarto (5 hóspedes em 2 quartos)
    ((SELECT id_cliente FROM cliente WHERE nif = 'ESX9876543A'),
     (SELECT id_funcionario FROM funcionario WHERE email = 'sofia.ribeiro@hotelufp.pt'),
     '2026-07-15', '2026-08-10', '2026-08-15', 'concluida', 5),

    -- R5: Lisboa, concluída no último mês (para Q07)
    ((SELECT id_cliente FROM cliente WHERE nif = '245678901'),
     (SELECT id_funcionario FROM funcionario WHERE email = 'sofia.ribeiro@hotelufp.pt'),
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '25 days')::DATE,
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '20 days')::DATE,
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '16 days')::DATE,
     'concluida', 3),

    -- R6: Porto, concluída no último mês, lotação máxima exata de 4 hóspedes (Q07)
    ((SELECT id_cliente FROM cliente WHERE nif = 'FR77889900112'),
     (SELECT id_funcionario FROM funcionario WHERE email = 'ines.carvalho@hotelufp.pt'),
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '22 days')::DATE,
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '15 days')::DATE,
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '10 days')::DATE,
     'concluida', 4),

    -- R7: Algarve, concluída no último mês (Q07)
    ((SELECT id_cliente FROM cliente WHERE nif = 'GB554433221'),
     (SELECT id_funcionario FROM funcionario WHERE email = 'miguel.tavares@hotelufp.pt'),
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '18 days')::DATE,
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 days')::DATE,
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '9 days')::DATE,
     'concluida', 2),

    -- R8: Porto, pendente, check-in HOJE com pagamento pendente (Q06)
    ((SELECT id_cliente FROM cliente WHERE nif = '234567892'),
     (SELECT id_funcionario FROM funcionario WHERE email = 'ines.carvalho@hotelufp.pt'),
     CURRENT_DATE - 3, CURRENT_DATE, CURRENT_DATE + 2, 'pendente', 2),

    -- R9: Algarve, confirmada, check-in HOJE, 1 noite, pagamento parcialmente pendente (Q06 e D7)
    ((SELECT id_cliente FROM cliente WHERE nif = '245678901'),
     NULL,
     CURRENT_DATE - 1, CURRENT_DATE, CURRENT_DATE + 1, 'confirmada', 2),

    -- R10: Lisboa, confirmada para o futuro (Q01)
    ((SELECT id_cliente FROM cliente WHERE nif = 'ESX9876543A'),
     (SELECT id_funcionario FROM funcionario WHERE email = 'sofia.ribeiro@hotelufp.pt'),
     CURRENT_DATE, CURRENT_DATE + 15, CURRENT_DATE + 18, 'confirmada', 1);

-- ----------------------------------------------------------------------------
-- 9. RESERVA_QUARTO
-- ----------------------------------------------------------------------------
INSERT INTO reserva_quarto (id_reserva, id_quarto) VALUES
    -- R1 -> Porto 102
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = '2026-06-10'),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Porto' AND q.num_quarto = '102')),

    -- R2 -> Porto 101 (cancelada)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '234567892' AND r.data_checkin = '2026-07-01'),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Porto' AND q.num_quarto = '101')),

    -- R3 -> Porto 101 (ativa no mesmo período de R2)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '256789013' AND r.data_checkin = '2026-07-02'),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Porto' AND q.num_quarto = '101')),

    -- R4 -> Lisboa 101 + Lisboa 201 (multi-quarto: capacidade 2 + 4 = 6 >= 5 hóspedes)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'ESX9876543A' AND r.data_checkin = '2026-08-10'),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Lisboa' AND q.num_quarto = '101')),
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'ESX9876543A' AND r.data_checkin = '2026-08-10'),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Lisboa' AND q.num_quarto = '201')),

    -- R5 -> Lisboa 201
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '20 days')::DATE),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Lisboa' AND q.num_quarto = '201')),

    -- R6 -> Porto 301
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'FR77889900112' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '15 days')::DATE),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Porto' AND q.num_quarto = '301')),

    -- R7 -> Algarve 101
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'GB554433221' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 days')::DATE),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Algarve' AND q.num_quarto = '101')),

    -- R8 -> Porto 102
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '234567892' AND r.data_checkin = CURRENT_DATE),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Porto' AND q.num_quarto = '102')),

    -- R9 -> Algarve 201
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = CURRENT_DATE),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Algarve' AND q.num_quarto = '201')),

    -- R10 -> Lisboa 001
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'ESX9876543A' AND r.data_checkin = CURRENT_DATE + 15),
     (SELECT q.id_quarto FROM quarto q JOIN hotel h ON h.id_hotel = q.id_hotel
      WHERE h.nome_hotel = 'Hotel UFP Lisboa' AND q.num_quarto = '001'));

-- ----------------------------------------------------------------------------
-- 10. RESERVA_SERVICO (apenas serviços oferecidos pelo respetivo hotel)
-- ----------------------------------------------------------------------------
INSERT INTO reserva_servico (id_reserva, id_servico, data_servico, quantidade, preco_aplicado) VALUES
    -- R1 (Porto): Pequeno-almoço em 3 dias distintos (testa COUNT DISTINCT em Q04) + Estacionamento
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = '2026-06-10'),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Pequeno-Almoço Buffet'), '2026-06-11', 2, 14.00),
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = '2026-06-10'),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Pequeno-Almoço Buffet'), '2026-06-12', 2, 14.00),
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = '2026-06-10'),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Pequeno-Almoço Buffet'), '2026-06-13', 2, 14.00),
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = '2026-06-10'),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Estacionamento Privado'), '2026-06-10', 4, 12.00),

    -- R3 (Porto): Transfer cortesia (preco_aplicado = 0.00 -> fronteira RN06 e histórico D5)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '256789013' AND r.data_checkin = '2026-07-02'),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Transfer Aeroporto'), '2026-07-02', 1, 0.00),

    -- R4 (Lisboa): Pequeno-almoço + Spa
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'ESX9876543A' AND r.data_checkin = '2026-08-10'),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Pequeno-Almoço Buffet'), '2026-08-11', 5, 14.00),
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'ESX9876543A' AND r.data_checkin = '2026-08-10'),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Acesso Spa'), '2026-08-12', 2, 25.00),

    -- R5 (Lisboa, último mês): Spa com tarifa promocional (22.00 vs 25.00) + Transfer
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '20 days')::DATE),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Acesso Spa'),
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '19 days')::DATE, 2, 22.00),
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '20 days')::DATE),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Transfer Aeroporto'),
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '20 days')::DATE, 1, 35.00),

    -- R6 (Porto, último mês): Pequeno-almoço + Estacionamento
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'FR77889900112' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '15 days')::DATE),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Pequeno-Almoço Buffet'),
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '14 days')::DATE, 4, 14.00),
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'FR77889900112' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '15 days')::DATE),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Estacionamento Privado'),
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '15 days')::DATE, 5, 12.00),

    -- R7 (Algarve, último mês): Pequeno-almoço
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'GB554433221' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 days')::DATE),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Pequeno-Almoço Buffet'),
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '11 days')::DATE, 2, 14.00),

    -- R10 (Lisboa, futura): Pequeno-almoço
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'ESX9876543A' AND r.data_checkin = CURRENT_DATE + 15),
     (SELECT id_servico FROM servico WHERE nome_servico = 'Pequeno-Almoço Buffet'),
     CURRENT_DATE + 16, 1, 14.00);

-- ----------------------------------------------------------------------------
-- 11. PAGAMENTO (cobrindo todos os métodos, estados e prestações)
-- ----------------------------------------------------------------------------
INSERT INTO pagamento (id_reserva, numero_prestacao, valor_prestacao, metodo_pagamento, estado_pagamento, data_prevista, data_pagamento) VALUES
    -- R1 (512.00 em 2 prestações pagas com métodos distintos)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = '2026-06-10'),
     1, 256.00, 'mbway', 'pago', '2026-05-20', '2026-05-20'),
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = '2026-06-10'),
     2, 256.00, 'cartao_credito', 'pago', '2026-06-10', '2026-06-10'),

    -- R2 (reembolsado após cancelamento)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '234567892' AND r.data_checkin = '2026-07-01'),
     1, 195.00, 'cartao_credito', 'reembolsado', '2026-06-15', '2026-06-15'),

    -- R3 (pago em dinheiro)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '256789013' AND r.data_checkin = '2026-07-02'),
     1, 195.00, 'dinheiro', 'pago', '2026-07-02', '2026-07-02'),

    -- R4 (pago por transferência bancária)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'ESX9876543A' AND r.data_checkin = '2026-08-10'),
     1, 1495.00, 'transferencia', 'pago', '2026-08-01', '2026-08-01'),

    -- R5 (Lisboa, último mês: 799.00 pago)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '20 days')::DATE),
     1, 799.00, 'cartao_credito', 'pago',
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '20 days')::DATE,
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '20 days')::DATE),

    -- R6 (Porto, último mês: 1016.00 em 2 prestações pagas — paypal + cartao_debito)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'FR77889900112' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '15 days')::DATE),
     1, 500.00, 'paypal', 'pago',
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '22 days')::DATE,
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '22 days')::DATE),
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'FR77889900112' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '15 days')::DATE),
     2, 516.00, 'cartao_debito', 'pago',
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '15 days')::DATE,
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '15 days')::DATE),

    -- R7 (Algarve, último mês: 313.00 pago)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'GB554433221' AND r.data_checkin = (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 days')::DATE),
     1, 313.00, 'mbway', 'pago',
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 days')::DATE,
     (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '12 days')::DATE),

    -- R8 (check-in HOJE, pagamento pendente)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '234567892' AND r.data_checkin = CURRENT_DATE),
     1, 190.00, NULL, 'pendente', CURRENT_DATE, NULL),

    -- R9 (check-in HOJE, sinal pago + 2ª prestação pendente)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = CURRENT_DATE),
     1, 50.00, 'mbway', 'pago', CURRENT_DATE - 1, CURRENT_DATE - 1),
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = '245678901' AND r.data_checkin = CURRENT_DATE),
     2, 65.00, NULL, 'pendente', CURRENT_DATE, NULL),

    -- R10 (futura, paga)
    ((SELECT r.id_reserva FROM reserva r JOIN cliente c ON c.id_cliente = r.id_cliente
      WHERE c.nif = 'ESX9876543A' AND r.data_checkin = CURRENT_DATE + 15),
     1, 209.00, 'cartao_credito', 'pago', CURRENT_DATE, CURRENT_DATE);

COMMIT;