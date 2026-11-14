# 6.3. Implementação PostgreSQL

## 1. Estrutura e Reprodutibilidade
O esquema físico encontra-se no script `sql/01_schema.sql`.
Para garantir que a base de dados possa ser recriada de forma previsível e atómica:
- O script inicia com `DROP TABLE IF EXISTS ... CASCADE` pela ordem inversa das dependências referenciais.
- Toda a criação de tabelas e restrições decorre dentro de uma transação (`BEGIN; ... COMMIT;`).
- As chaves primárias artificiais utilizam `GENERATED ALWAYS AS IDENTITY` (padrão SQL suportado pelo PostgreSQL).
- Todas as restrições (`PK`, `FK`, `UNIQUE`, `CHECK`) possuem nomes explícitos (`pk_*`, `fk_*`, `uq_*`, `chk_*`) para facilitar o diagnóstico e os testes de integridade.

## 2. Opções de Implementação
- **Domínios enumerados com `VARCHAR` + `CHECK`:** Optou-se por `VARCHAR(20)` com restrições `CHECK (... IN (...))` em vez de `CREATE TYPE ... AS ENUM`, mantendo total aderência às restrições declarativas padrão e evitando dependências rígidas de tipos na recriação e evolução do esquema.
- **Identificadores em `snake_case` sem aspas:** Evita a obrigatoriedade de usar aspas duplas em consultas SQL devido à sensibilidade a maiúsculas/minúsculas do PostgreSQL.

## 3. Rastreabilidade das Regras de Negócio (Declarativas vs. Fase 3)

| Regra / Consistência | Tratamento na Fase 2 (Declarativo) | Observações |
|---|---|---|
| **RN01** | `reserva.id_cliente NOT NULL` + `fk_reserva_cliente` | Garantida declarativamente. |
| **RN02** | `chk_reserva_datas` (`data_checkout > data_checkin`) | Garantida declarativamente. |
| **RN03** | *Reservada para a Fase 3 (trigger)* | Envolve junção entre `reserva` (datas e estado) e `reserva_quarto` (`id_quarto`), não sendo expressável por restrição declarativa de uma única tabela. |
| **RN04** | *Reservada para a Fase 3 (trigger)* | Requer agregação (`SUM(capacidade_maxima)`) sobre várias tabelas (`reserva_quarto`, `quarto`, `tipo_quarto`). |
| **RN05** | `uq_cliente_nif` e `uq_cliente_doc` | Garantida declarativamente. |
| **RN06** | `chk_tipo_quarto_preco`, `chk_servico_preco`, `chk_reserva_servico_preco`, `chk_pagamento_valor` (`> 0`) | Garantida declarativamente. |
| **RN07** | Coluna escalar `pagamento.metodo_pagamento` + `chk_pagamento_metodo` | Cada registo admite apenas um método. |
| **RN08** | `chk_funcionario_hotel_cargo` | Garantida declarativamente com `CHECK` multi-coluna. |
| **Mesmo hotel / serviço oferecido** | *Reservada para a Fase 3 (triggers)* | Verificação inter-tabelas (quartos da mesma reserva no mesmo hotel; serviço incluído na oferta `hotel_servico` desse hotel). |

## 4. Como executar
```
createdb hotel_bdad
psql -d hotel_bdad -v ON_ERROR_STOP=1 -f sql/01_schema.sql
```
