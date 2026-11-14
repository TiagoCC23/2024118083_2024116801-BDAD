# 6.2 Normalização

## 1. Método

Para cada relação:

1. identificam-se as chaves candidatas (CK) a partir das regras de negócio (RN05 e outras) e do modelo relacional (6.1);
2. enunciam-se as dependências funcionais (DF) **não triviais** que decorrem da semântica do domínio, e não da coincidência dos dados de exemplo;
3. aplicam-se os critérios:
   - **1NF**: atributos atómicos, sem grupos repetitivos, com PK definida;
   - **2NF**: 1NF e nenhum atributo não-primo depende de parte de uma CK;
   - **3NF**: 2NF e, para cada DF `X → A` não trivial, `X` é superchave **ou** `A` é primo (pertence a alguma CK);
   - **BCNF**: para cada DF `X → A` não trivial, `X` é superchave.

> Um atributo é *primo* se pertence a alguma chave candidata.

## 2. Dependências funcionais e chaves por relação

Notação: `X → Y` significa que `X` determina `Y`. Todas as DF `CK → (restantes atributos)` são omitidas das tabelas abaixo quando não acrescentam informação. As DF listadas "para além das chaves" são as que se podem discutir.

| Relação | Chaves candidatas | DF (todas têm uma CK à esquerda) |
|---|---|---|
| HOTEL | `ID_Hotel`; `Nome_Hotel` | `ID_Hotel → Nome_Hotel, Morada, Cidade, Pais, Telefone`; `Nome_Hotel → ID_Hotel, …` |
| TIPO_QUARTO | `ID_TipoQuarto`; `Nome_Tipo` | `ID_TipoQuarto → Nome_Tipo, Descricao, Capacidade_Maxima, Preco_Noite`; `Nome_Tipo → ID_TipoQuarto, …` |
| QUARTO | `ID_Quarto`; `(ID_Hotel, Num_Quarto)` | `ID_Quarto → ID_Hotel, ID_TipoQuarto, Num_Quarto, Piso, Estado_Manutencao`; `(ID_Hotel, Num_Quarto) → ID_Quarto, ID_TipoQuarto, Piso, Estado_Manutencao` |
| SERVICO | `ID_Servico`; `Nome_Servico` | `ID_Servico → Nome_Servico, Preco_Unitario`; `Nome_Servico → ID_Servico, Preco_Unitario` |
| HOTEL_SERVICO | `(ID_Hotel, ID_Servico)` | nenhuma não trivial (todos os atributos são chave) |
| CLIENTE | `ID_Cliente`; `NIF`; `Doc_Identificacao`; `Email` | cada CK determina todos os restantes atributos |
| FUNCIONARIO | `ID_Funcionario`; `NIF`; `Email` | cada CK determina todos os restantes atributos |
| RESERVA | `ID_Reserva` | `ID_Reserva → ID_Cliente, ID_Funcionario, Data_Criacao, Data_CheckIn, Data_CheckOut, Estado_Reserva, Num_Hospedes` |
| RESERVA_QUARTO | `(ID_Reserva, ID_Quarto)` | nenhuma não trivial |
| RESERVA_SERVICO | `(ID_Reserva, ID_Servico, Data_Servico)` | `(ID_Reserva, ID_Servico, Data_Servico) → Quantidade, Preco_Aplicado` |
| PAGAMENTO | `ID_Pagamento`; `(ID_Reserva, Numero_Prestacao)` | `ID_Pagamento → ID_Reserva, Numero_Prestacao, Valor_Prestacao, Metodo_Pagamento, Estado_Pagamento, Data_Prevista, Data_Pagamento`; `(ID_Reserva, Numero_Prestacao) → ID_Pagamento, …` |

## 3. 1NF

- **Atomicidade.** Nenhum atributo guarda listas. Um quarto de uma reserva não é uma lista de quartos numa string: está em `RESERVA_QUARTO`. Cada serviço prestado é uma linha de `RESERVA_SERVICO`. Cada prestação é uma linha de `PAGAMENTO`.
- **Sem grupos repetitivos.** Não existem colunas do tipo `Quarto_1, Quarto_2` nem `Prestacao_1, Prestacao_2`.
- **`Morada` e `Telefone`** são tratados como atómicos no contexto do domínio: nenhuma necessidade de informação (Q01–Q07) exige consultar rua ou número separadamente, e cada entidade tem um único telefone. Se fossem necessários vários contactos, deveriam passar a uma relação própria.
- **Chave primária.** Todas as relações têm PK definida (6.1).

> ***Todas as relações estão em 1NF.***

## 4. 2NF

A 2NF só pode ser violada em relações com chave **composta**. Para as restantes, basta que a CK seja simples.

| Relação | Chaves compostas | Atributos não-primos | Dependência parcial? |
|---|---|---|---|
| QUARTO | `(ID_Hotel, Num_Quarto)` | `ID_TipoQuarto`, `Piso`, `Estado_Manutencao` | **Não.** O quarto 101 do hotel A e o do hotel B têm tipo, piso e estado diferentes. Nenhum depende só de `ID_Hotel` ou só de `Num_Quarto`. `ID_Hotel` e `Num_Quarto` são primos. |
| HOTEL_SERVICO | `(ID_Hotel, ID_Servico)` | nenhum | Não pode existir. |
| RESERVA_QUARTO | `(ID_Reserva, ID_Quarto)` | nenhum | Não pode existir. |
| RESERVA_SERVICO | `(ID_Reserva, ID_Servico, Data_Servico)` | `Quantidade`, `Preco_Aplicado` | **Não.** Dependem de uma prestação concreta: de `ID_Reserva` sozinho não se sabe qual o serviço; de `ID_Servico` sozinho não se sabe a reserva nem o preço histórico; sem `Data_Servico` não se distingue a mesma prestação em dias diferentes. |
| PAGAMENTO | `(ID_Reserva, Numero_Prestacao)` | `Valor_Prestacao`, `Metodo_Pagamento`, `Estado_Pagamento`, `Data_Prevista`, `Data_Pagamento` | **Não.** Cada prestação tem valor e datas próprios. Nenhum depende só de `ID_Reserva` ou só de `Numero_Prestacao`. |

As restantes relações (HOTEL, TIPO_QUARTO, SERVICO, CLIENTE, FUNCIONARIO, RESERVA) têm chaves simples, logo estão em 2NF.

> ***Todas as relações estão em 2NF.***

## 5. 3NF e BCNF

Para cada DF `X → A` não trivial listada na secção 2, verifica-se que `X` é superchave. Todos os determinantes são chaves candidatas, por isso o teste da BCNF é satisfeito e, em consequência, o da 3NF.

| Relação | Todos os determinantes são superchaves? | Resultado |
|---|---|---|
| HOTEL | Sim (`ID_Hotel`, `Nome_Hotel`) | BCNF |
| TIPO_QUARTO | Sim (`ID_TipoQuarto`, `Nome_Tipo`) | BCNF |
| QUARTO | Sim (`ID_Quarto`, `(ID_Hotel, Num_Quarto)`) | BCNF |
| SERVICO | Sim (`ID_Servico`, `Nome_Servico`) | BCNF |
| HOTEL_SERVICO | Só DF triviais | BCNF |
| CLIENTE | Sim (as quatro CK) | BCNF |
| FUNCIONARIO | Sim (as três CK) | BCNF |
| RESERVA | Sim (`ID_Reserva`) | BCNF |
| RESERVA_QUARTO | Só DF triviais | BCNF |
| RESERVA_SERVICO | Sim (a chave composta) | BCNF |
| PAGAMENTO | Sim (`ID_Pagamento`, `(ID_Reserva, Numero_Prestacao)`) | BCNF |

### Porque é que o esquema chega a este estado

Os casos em que a 3NF seria violada foram evitados no mapeamento (6.1), e não corrigidos depois:

- **Quarto / Tipo_Quarto:** Se `Capacidade_Maxima` e `Preco_Noite` estivessem em `QUARTO`, existiria `ID_Quarto → ID_TipoQuarto → (Capacidade_Maxima, Preco_Noite)`, uma dependência transitiva com redundância em todos os quartos do mesmo tipo.
- **Funcionario / Hotel:** Se `FUNCIONARIO` guardasse a morada ou cidade do hotel, haveria `ID_Funcionario → ID_Hotel → Morada`.
- **Reserva / Cliente:** Guardar `Nome` ou `NIF` do cliente em `RESERVA` criaria `ID_Reserva → ID_Cliente → (Nome, NIF)`.

## 6. Casos discutíveis

1. **`Cidade → Pais` em HOTEL.** Não é uma DF do domínio: o nome de uma cidade não identifica o país (existem cidades com o mesmo nome em países diferentes). Por isso não se cria uma tabela `Cidade`. Seria uma decomposição artificial, que o enunciado desaconselha, e que só faria sentido se existissem cidades normalizadas com identificador próprio.
2. **`Preco_Aplicado` em RESERVA_SERVICO vs `Preco_Unitario` em SERVICO.** Não há DF `ID_Servico → Preco_Aplicado`: o preço cobrado depende do momento da prestação, não só do serviço (o catálogo pode mudar). O atributo depende da chave completa. A redundância aparente é **intencional**, pois preserva o histórico de faturação.
3. **`Pais` em CLIENTE.** O país do cliente é um atributo do cliente, não determinado por `Doc_Identificacao` na prática (a emissão de documentos de vários países não está modelada), por isso não há dependência a decompor.
4. **Valor total da reserva.** Não é guardado. Obtém-se por soma das noites × `Preco_Noite` dos tipos dos quartos, mais os serviços, mais as prestações. Guardá-lo criaria redundância calculável. É calculado em consultas ou vistas (Fase 3).
5. **`Estado_Manutencao` sem `ocupado`.** A ocupação de um quarto num dado dia deriva de `RESERVA` e `RESERVA_QUARTO`. Guardá-la em `QUARTO` duplicaria informação e permitiria inconsistências. Está justificado no mapeamento (6.1, D10).
6. **`Num_Hospedes` vs `Capacidade_Maxima` (RN04).** É uma restrição entre tabelas (um valor tem de ser menor ou igual a um agregado de outra), não uma DF. Não afeta a normalização e é tratada na Fase 3.
7. **`Estado_Pagamento = 'pago'` e `Data_Pagamento`.** É uma restrição condicional (a data só existe se estiver pago), e não uma dependência funcional. É tratada por `CHECK`.

## 7. Conclusão

O esquema de 11 relações encontra-se em **1NF, 2NF, 3NF e BCNF**. **Não foi necessária nenhuma decomposição adicional** além das já resultantes do mapeamento do modelo ER:

- `RESERVA_QUARTO`, `RESERVA_SERVICO` e `HOTEL_SERVICO` resolvem os relacionamentos N:M (*Afeta*, *Inclui* e *Oferece*);
- `TIPO_QUARTO` e `HOTEL` já estavam separados como entidades próprias.

As redundâncias que subsistem (`Preco_Aplicado`, `Pais` em CLIENTE e HOTEL) estão justificadas na secção 6.