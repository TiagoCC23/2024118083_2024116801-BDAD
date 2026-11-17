--psql -U postgres -d hotel_db -f queries.sql

--------------------------------------------------------------------------------------------------
-- Q01: Quais são os quartos disponíveis (não reservados) para um determinado intervalo de datas?
--------------------------------------------------------------------------------------------------
SELECT
    h.nome_hotel,
    q.id_quarto,
    q.num_quarto,
    q.piso,
    tq.nome_tipo,
    tq.capacidade_maxima,
    tq.preco_noite,
    q.estado_manutencao
FROM quarto q
JOIN hotel h ON h.id_hotel = q.id_hotel
JOIN tipo_quarto tq ON tq.id_tipo_quarto = q.id_tipo_quarto
WHERE q.estado_manutencao <> 'em_manutencao'
  AND NOT EXISTS (
      SELECT 1
      FROM reserva_quarto rq
      JOIN reserva r ON r.id_reserva = rq.id_reserva
      WHERE rq.id_quarto = q.id_quarto
        AND r.estado_reserva <> 'cancelada'
        AND r.data_checkin < CURRENT_DATE + 3
        AND r.data_checkout > CURRENT_DATE
  )
ORDER BY h.nome_hotel, q.num_quarto;

-----------------------------------------------------------------------------
-- Q02: Qual é o histórico de reservas efetuadas por um determinado cliente?
-----------------------------------------------------------------------------
SELECT
    c.nome AS cliente,
    r.id_reserva,
    rq.nome_hotel,
    rq.quartos,
    r.data_criacao,
    r.data_checkin,
    r.data_checkout,
    r.data_checkout - r.data_checkin AS num_noites,
    r.num_hospedes,
    r.estado_reserva,
    (r.data_checkout - r.data_checkin) * rq.tarifa_diaria
        + COALESCE((SELECT SUM(rs.quantidade * rs.preco_aplicado) -- Devolve o primeiro valor não nulo
                    FROM reserva_servico rs
                    WHERE rs.id_reserva = r.id_reserva), 0) AS valor_total_estadia,
    COALESCE((SELECT SUM(p.valor_prestacao) -- Devolve o primeiro valor não nulo 
              FROM pagamento p
              WHERE p.id_reserva = r.id_reserva
                AND p.estado_pagamento = 'pago'), 0) AS total_pago
FROM cliente c
JOIN reserva r ON r.id_cliente = c.id_cliente
CROSS JOIN LATERAL (
    SELECT
        MIN(h.nome_hotel) AS nome_hotel,
        STRING_AGG(DISTINCT q.num_quarto, ', ' ORDER BY q.num_quarto) AS quartos,
        SUM(tq.preco_noite) AS tarifa_diaria
    FROM reserva_quarto x
    JOIN quarto q ON q.id_quarto = x.id_quarto
    JOIN hotel h ON h.id_hotel = q.id_hotel
    JOIN tipo_quarto tq ON tq.id_tipo_quarto = q.id_tipo_quarto
    WHERE x.id_reserva = r.id_reserva
) rq
WHERE c.nif = '245678901' -- NIF exemplo
ORDER BY r.data_checkin DESC;

-------------------------------------------------------------------------------------------------
-- Q03: Qual é o valor total de faturação acumulado por método de pagamento num determinado mês?
-------------------------------------------------------------------------------------------------
SELECT
    metodo_pagamento,
    COUNT(*) AS num_pagamentos,
    SUM(valor_prestacao) AS total_faturado
FROM pagamento
WHERE estado_pagamento = 'pago'
  AND data_pagamento >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
  AND data_pagamento <  DATE_TRUNC('month', CURRENT_DATE)
GROUP BY metodo_pagamento
ORDER BY total_faturado DESC;

-----------------------------------------------------------------
-- Q04: Em quantas reservas foi incluído cada serviço adicional? 
-----------------------------------------------------------------
SELECT s.id_servico, s.nome_servico, COUNT(DISTINCT r.id_reserva) AS total_reservas, -- nao conta as reservas repetidas
COALESCE(SUM(rs.quantidade), 0) AS total_unidades_consumidas -- passa as reservas a null para 0 para a contagem
FROM servico s
LEFT JOIN reserva_servico rs ON s.id_servico = rs.id_servico -- mantem no resultado os serviços com 0 reservas associadas (um join normal apagava os serviços)
LEFT JOIN reserva r ON rs.id_reserva = r.id_reserva -- filtro de estado fica no ON para não eliminar serviços sem reservas válidas
    AND r.estado_reserva <> 'cancelada'
GROUP BY s.id_servico, s.nome_servico
ORDER BY total_reservas DESC, s.nome_servico;

---------------------------------------------------------------------------------------------------
-- Q05: Qual é a taxa de ocupação dos quartos agrupada por tipo de quarto num determinado período?
---------------------------------------------------------------------------------------------------
WITH periodo AS ( -- Cria uma tabela auxiliar periodo para descobirmos a taxa de ocupação
    SELECT -- intervalo de análise
    DATE '2026-07-01' AS data_inicio,
    DATE '2026-07-31' AS data_fim
)
SELECT tq.id_tipo_quarto, tq.nome_tipo,
    COUNT(DISTINCT q.id_quarto) AS total_quartos,  -- conta cada quarto
    COALESCE(SUM( -- noites em que cada tipo de quarto esteve ocupado dentro do período analisado (ignora osdias da mesma reserva fora desse intervalo) E devolvel 0 se não ouver reserva
    CASE WHEN r.id_reserva IS NOT NULL THEN
        GREATEST(0, LEAST(r.data_checkout, p.data_fim + 1) - GREATEST(r.data_checkin, p.data_inicio)) -- (menor dia entre o último da reserva e do periodo - maior dia entre o primeiro da reserva e do periodo)
    ELSE 0 END
), 0) AS total_dias_ocupados, -- soma os dias pertencentes ao intervalo
ROUND(
   COALESCE(SUM(
        CASE WHEN r.id_reserva IS NOT NULL THEN
            GREATEST(0, LEAST(r.data_checkout, p.data_fim + 1) - GREATEST(r.data_checkin, p.data_inicio))
        ELSE 0 END
    ), 0)::NUMERIC / NULLIF(COUNT(DISTINCT q.id_quarto) * (p.data_fim - p.data_inicio + 1), 0) * 100, -- capacidade total (count...) e multiplica pelo número de dias do intervalo
2) AS taxa_ocupacao -- (noites ocupadas/ (capacidade total)) *100
FROM tipo_quarto tq
CROSS JOIN periodo p -- cross join para não duplicar dados (junta cada tipo do quarto com a única linha da CTE periodo)
LEFT JOIN quarto q ON tq.id_tipo_quarto = q.id_tipo_quarto -- liga cada tipo aos quartos físicos que pertencem a essa categoria. (inner join apagava a tipologia do resultado)
LEFT JOIN reserva_quarto rq ON q.id_quarto = rq.id_quarto -- descobre em que reservas cada quarto físico foi alocado (um inner join para caso o quarto não existisse, apagava o quarto)
LEFT JOIN reserva r ON rq.id_reserva = r.id_reserva -- filtra apenas reservas confirmadas/concluídas que intersetam o período (se fosse where, ele apagava quartos sem ocupação)
    AND r.estado_reserva IN ('confirmada', 'concluida')
    AND r.data_checkin < p.data_fim
    AND r.data_checkout > p.data_inicio
GROUP BY tq.id_tipo_quarto, tq.nome_tipo, p.data_inicio, p.data_fim
ORDER BY taxa_ocupacao DESC, tq.nome_tipo;

---------------------------------------------------------------------------------------------
-- Q06: Quais são as reservas pendentes de pagamento cuja data de check-in é no próprio dia?
---------------------------------------------------------------------------------------------
SELECT
    r.id_reserva,
    c.nome AS nome_cliente,
    c.telemovel,
    c.email,
    r.data_checkin,
    r.data_checkout,
    r.estado_reserva,
    COALESCE(SUM(p.valor_prestacao), 0) AS montante_pendente -- soma as prestaçoes pendentes
FROM reserva r
JOIN cliente c ON r.id_cliente = c.id_cliente
LEFT JOIN pagamento p ON r.id_reserva = p.id_reserva -- apanha as reservas que nao tem pagamentos associados (LEFT JOIN) e filtra apenas os pagamentos pendentes
    AND p.estado_pagamento = 'pendente'
WHERE r.data_checkin = CURRENT_DATE -- filtra os check-ins marcados para o dia de hoje
    AND r.estado_reserva IN ('pendente', 'confirmada')
    AND (
        p.id_pagamento IS NOT NULL OR NOT EXISTS ( -- existe pelo menos uma prestação 'pendente' OU não existe nenhuma prestação 'paga'
            SELECT 1
            FROM pagamento p2
            WHERE p2.id_reserva = r.id_reserva
              AND p2.estado_pagamento = 'pago' -- nao existe nenhuma prestação ja paga para esta reserva
        )
    )
GROUP BY r.id_reserva, c.nome, c.telemovel, c.email, r.data_checkin, r.data_checkout, r.estado_reserva
ORDER BY r.data_checkin;

---------------------------------------------------------------------
-- Q07: Qual hotel da cadeia teve maior receita total no último mês?
---------------------------------------------------------------------
WITH reserva_hotel AS(
    SELECT DISTINCT -- associa cada reserva ao hotel correspondente, sem duplicar
        rq.id_reserva,
        q.id_hotel
    FROM reserva_quarto rq
    JOIN quarto q ON rq.id_quarto = q.id_quarto
) SELECT
    h.id_hotel,
    h.nome_hotel,
    h.cidade,
    COUNT(DISTINCT p.id_reserva) AS total_reservas, -- conta as reservas que têm pagamentos efetuados
    COALESCE(SUM(p.valor_prestacao), 0) AS receita_total -- soma apenas as prestaçoes pagas
FROM hotel h
LEFT JOIN reserva_hotel rh ON h.id_hotel = rh.id_hotel -- garante que todos os hotéis aparecem no ranking, mesmo que um hotel não tenha tido nenhuma reserva no último mês 
                                                                                                            --(um join normal, com dados a null, desaparecia)
LEFT JOIN pagamento p ON rh.id_reserva = p.id_reserva -- junta apenas as prestaçoes pagas
    AND p.estado_pagamento = 'pago'
    AND p.data_pagamento >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
AND p.data_pagamento <  DATE_TRUNC('month', CURRENT_DATE)
GROUP BY h.id_hotel, h.nome_hotel, h.cidade
ORDER BY receita_total DESC, h.nome_hotel;