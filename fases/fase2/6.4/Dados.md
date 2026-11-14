# 6.4. Dados

## 1. Visão Geral do Povoamento
O script `sql/02_seed_data.sql` povoa todas as 11 tabelas do esquema com dados diversificados e consistentes com as restrições declarativas e com as regras de negócio da Fase 1.

O script é **idempotente**: executa `TRUNCATE ... RESTART IDENTITY CASCADE` antes das inserções, garantindo que possa ser reexecutado de forma previsível sem duplicar registos.

## 2. Volume de Dados Inserido

| Tabela | Registos | Cobertura principal |
|---|---|---|
| `hotel` | 3 | Porto, Lisboa e Algarve |
| `tipo_quarto` | 4 | Capacidades de 1 a 4 hóspedes |
| `quarto` | 12 | 4 quartos por hotel; pisos `0` a `3`; estados `livre_limpo`, `em_limpeza` e `em_manutencao` |
| `servico` | 5 | Inclui 1 serviço (`Late Check-out`) sem consumos registados |
| `hotel_servico` | 12 | Oferta distinta por unidade hoteleira |
| `cliente` | 7 | Clientes nacionais e estrangeiros + 1 cliente sem reservas |
| `funcionario` | 6 | `gestor_cadeia` (`id_hotel IS NULL`), `gestor_hotel` e `rececionista` |
| `reserva` | 10 | Estados `pendente`, `confirmada`, `cancelada` e `concluida` |
| `reserva_quarto` | 11 | Inclui reserva multi-quarto (R4) |
| `reserva_servico` | 13 | Inclui mesmo serviço em vários dias (R1) e preço histórico/cortesia (R3, R5) |
| `pagamento` | 13 | Todos os 6 métodos e os 3 estados (`pendente`, `pago`, `reembolsado`) |

## 3. Casos Relevantes e Regras de Negócio Representados

* **RN03 (Cancelamentos não ocupam o quarto):** No `Hotel UFP Porto`, quarto `101`, a reserva R2 (`2026-07-01` a `2026-07-04`, `cancelada`) sobrepõe-se à reserva R3 (`2026-07-02` a `2026-07-05`, `concluida`).
* **RN04 (Capacidade máxima e multi-quarto):** A reserva R6 atinge a lotação exata da `Suite Familiar` (4 hóspedes); a reserva R4 distribui 5 hóspedes por 2 quartos (`Duplo Standard` + `Suite Familiar`, capacidade combinada 6).
* **RN06 e D5 (Valores monetários `>= 0` e histórico de preço):** A reserva R3 regista um serviço com `preco_aplicado = 0.00` (cortesia), e a R5 regista `Acesso Spa` com tarifa promocional (`22.00` face ao preçário `25.00`).
* **RN08 (Cargo vs. Hotel):** `Beatriz Almeida` (`gestor_cadeia`) possui `id_hotel = NULL`, enquanto os restantes cargos estão afetos a um hotel específico.
* **D1 (Numeração de quartos por hotel):** O número `101` repete-se nos três hotéis sem conflito.
* **D7 (Reservas sem funcionário):** As reservas R2 e R9 simulam reservas diretas online (`id_funcionario IS NULL`).
* **Q01–Q07:** Existem reservas com `data_checkin = CURRENT_DATE` e pagamento `pendente` (R8, R9 para **Q06**), faturação distribuída pelos três hotéis no mês anterior (R5, R6, R7 para **Q07**), um cliente sem reservas (`Mariana Lopes` para **Q02**) e um serviço não consumido (`Late Check-out` para **Q04**).