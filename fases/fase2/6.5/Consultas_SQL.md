# 6.5. Início das Consultas SQL

## 1. Visão Geral
O script `sql/queries.sql` implementa a versão inicial das consultas correspondentes às necessidades de informação **Q01–Q07** definidas na Fase 1.

## 2. Rastreabilidade e Construções SQL Utilizadas

| Questão | Objetivo | Construções SQL aplicadas |
|---|---|---|
| **Q01** | Quartos disponíveis num intervalo de datas | `JOIN`, `NOT EXISTS` (sobreposição temporal), exclusão de reservas `'cancelada'` (**RN03**) e quartos `'em_manutencao'` |
| **Q02** | Histórico de reservas de um cliente | CTEs (`WITH`) para evitar multiplicação cartesiana entre quartos, serviços e pagamentos; `STRING_AGG`, `LEFT JOIN`, `COALESCE`, `FILTER` |
| **Q03** | Faturação por método de pagamento num mês | Intervalo de datas sargável, `GROUP BY`, `HAVING`, `SUM`, `COUNT` |
| **Q04** | Número de reservas por serviço adicional | `LEFT JOIN` (preserva serviços com 0 utilizações), `COUNT(DISTINCT ...)` |
| **Q05** | Taxa de ocupação por tipo de quarto | CTEs, interseção de intervalos (`LEAST`/`GREATEST`), `SUM`, `COUNT`, `NULLIF`, `ROUND` |
| **Q06** | Reservas com check-in hoje e pagamento pendente | Múltiplos `JOIN`, `CURRENT_DATE`, `GROUP BY`, `SUM` |
| **Q07** | Hotel com maior receita total no último mês | Deduplicação `reserva_hotel` (para reservas multi-quarto), `LEFT JOIN`, `ORDER BY ... FETCH FIRST 1 ROW WITH TIES` |

## 3. Resultados Esperados sobre os Dados de Teste (`02_seed_data.sql`)
* **Q01** (`[CURRENT_DATE, CURRENT_DATE + 3[`): exclui Porto `102` (R8), Algarve `201` (R9) e Lisboa `102` (`em_manutencao`), devolvendo os restantes 9 quartos.
* **Q02** (NIF `'245678901'` — *Ana Ferreira*): lista 3 reservas (R9, R5 e R1) por ordem decrescente de check-in, com valores totais `115.00`, `799.00` e `512.00`.
* **Q03** (mês anterior): apresenta `cartao_credito` (`799.00`), `cartao_debito` (`516.00`), `paypal` (`500.00`) e `mbway` (`313.00`).
* **Q04**: `Pequeno-Almoço Buffet` em `5` reservas (apesar de ter 7 linhas em `reserva_servico`), `Acesso Spa`, `Estacionamento Privado` e `Transfer Aeroporto` em `2` reservas cada, e `Late Check-out` em `0` reservas.
* **Q05** (mês anterior): `Suite Familiar` apresenta a maior taxa (9 noites ocupadas em 3 quartos), seguida de `Duplo Standard` (3 noites em 4 quartos) e `0.00%` nos restantes tipos.
* **Q06**: devolve as reservas **R8** (`190.00` pendente) e **R9** (`65.00` pendente).
* **Q07**: devolve **Hotel UFP Porto** com `1016.00` de receita no último mês (superior a Lisboa com `799.00` e Algarve com `313.00`).

## 4. Como executar
```
psql -d hotel_bdad -v ON_ERROR_STOP=1 -f sql/03_queries.sql
```