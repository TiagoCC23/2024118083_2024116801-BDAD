# 6.1. Modelo Relacional

Notação utilizada: **PK** — chave primária (sublinhada no esquema), **FK** — chave estrangeira (em *itálico* no esquema), **CK** — chave candidata, `?` — atributo opcional (admite `NULL`).

## 1. Decisões de Mapeamento (Modelo ER → Modelo Relacional)

A conversão do modelo conceptual da Fase 1 para o esquema relacional seguiu as regras padrão de derivação, incorporando correções e refinamentos necessários para garantir a coerência com os requisitos (`RD01–RD08`), as regras de negócio (`RN01–RN08`) e as necessidades de informação (`Q01–Q07`):

| # | Decisão | Justificação |
|---|---------|--------------|
| D1 | `QUARTO` recebe chave primária artificial `ID_Quarto` e chave candidata `UNIQUE (ID_Hotel, Num_Quarto)`. | No modelo ER da Fase 1, `Num_Quarto` surgia como identificador isolado. Contudo, numa cadeia hoteleira o mesmo número (ex.: `101`) repete-se em hotéis diferentes. A chave artificial simplifica as FK em `RESERVA_QUARTO`, mantendo `(ID_Hotel, Num_Quarto)` como chave candidata. |
| D2 | `RESERVA` ↔ `QUARTO` (*Afeta*) é N:M, originando a tabela associativa `RESERVA_QUARTO`. | Conforme definido no âmbito do projeto, uma reserva pode abranger um ou mais quartos e um quarto participa em várias reservas ao longo do tempo. Assim, `Num_Quarto` é removido da tabela `RESERVA`. |
| D3 | `RESERVA` 1:N `PAGAMENTO` (*Apresenta*), com FK obrigatória `ID_Reserva` em `PAGAMENTO`. | O modelo prevê pagamentos fracionados (`Numero_Prestacao`, `Valor_Prestacao`, `Data_Prevista`). `Reserva_ID`, que aparecia como atributo no ER da Fase 1, passa formalmente a FK `ID_Reserva`. |
| D4 | `HOTEL` 1:N `FUNCIONARIO` (*Emprega*), com FK opcional `ID_Hotel` `?` em `FUNCIONARIO`. | Pela **RN08**, o cargo `gestor_cadeia` não está afeto a um hotel específico (`ID_Hotel IS NULL`), enquanto `rececionista` e `gestor_hotel` exigem hotel (`ID_Hotel IS NOT NULL`). A participação de `FUNCIONARIO` passa a `(0,1)`. |
| D5 | `RESERVA` ↔ `SERVICO` (*Inclui*) é N:M, originando `RESERVA_SERVICO` com `Data_Servico`, `Quantidade` e `Preco_Aplicado`. | `Quantidade` é um atributo próprio do relacionamento. `Preco_Aplicado` regista o preço efetivamente praticado na data da prestação (por omissão igual a `SERVICO.Preco_Unitario`), protegendo o histórico de faturação face a alterações futuras do preçário. |
| D6 | `HOTEL` ↔ `SERVICO` (*Oferece*) é N:M, originando `HOTEL_SERVICO`. | O catálogo de serviços é global (`SERVICO`), permitindo que cada unidade hoteleira defina quais os serviços adicionais que disponibiliza. |
| D7 | `FUNCIONARIO` 0:N `RESERVA` (*Processa*), com FK opcional `ID_Funcionario` `?` em `RESERVA`. | A participação de `RESERVA` é `(0,1)`, permitindo reservas realizadas diretamente pelo cliente (ex.: canal online) sem intervenção imediata de um funcionário. |
| D8 | `QUARTO` N:1 `TIPO_QUARTO` (*Pertence*), com FK obrigatória `ID_TipoQuarto` em `QUARTO`. | Participação total de `QUARTO` `(1,1)`. |
| D9 | `CLIENTE` 1:N `RESERVA` (*Realiza*), com FK obrigatória `ID_Cliente` em `RESERVA`. | Garante a **RN01** (toda a reserva pertence a um único cliente registado). |
| D10 | Remoção do valor `'ocupado'` do domínio de `Estado_Manutencao` em `QUARTO`. | A ocupação de um quarto num determinado período é informação derivável a partir de `RESERVA` e `RESERVA_QUARTO`. Armazená-la em `QUARTO` introduziria redundância e risco de inconsistência temporal. O estado passa a refletir apenas a condição física: `{'livre_limpo', 'em_limpeza', 'em_manutencao'}`. |
| D11 | `Telemovel` deixa de ser chave candidata em `CLIENTE` e `FUNCIONARIO`. | Ao contrário de `NIF`, `Doc_Identificacao` (**RN05**) e `Email`, o número de telemovel pode ser partilhado (ex.: agregados familiares ou extensões empresariais). |

## 2. Domínios Relevantes

| Domínio | Tipo / Regra | Aplicação |
|---------|--------------|-----------|
| Identificadores (`ID_*`) | `INTEGER` (gerado sequencialmente / `GENERATED ALWAYS AS IDENTITY`) | Chaves primárias e estrangeiras artificiais |
| `NIF` | `VARCHAR(20)` (único, não nulo) | `CLIENTE`, `FUNCIONARIO` *(acomoda NIF nacional de 9 dígitos e identificadores fiscais estrangeiros, dado o atributo `Pais`)* |
| `Doc_Identificacao` | `VARCHAR(30)` (único, não nulo) | `CLIENTE` |
| `Email` | `VARCHAR(100)` (único, contém `@`) | `CLIENTE`, `FUNCIONARIO` |
| `Telemovel` | `VARCHAR(20)` | `HOTEL`, `CLIENTE`, `FUNCIONARIO` |
| `NUM_QUARTO `| `VARCHAR(10)` (não nulo; único por hotel com `ID_Hotel`) | Permite números de quartos com zeros à esquerda ou letras (ex.: '101', '101A') |
| Nomes e moradas | `VARCHAR(100)` a `VARCHAR(200)` | `Nome`, `Nome_Hotel`, `Morada`, `Cidade`, `Pais`, `Nome_Tipo`, `Nome_Servico` |
| Descrições | `TEXT` | `TIPO_QUARTO.Descricao` |
| Valores monetários | `NUMERIC(10,2)`, `> 0` | `Preco_Noite`, `Preco_Unitario`, `Preco_Aplicado`, `Valor_Prestacao` |
| Datas | `DATE` | `Data_Contratacao`, `Data_Criacao`, `Data_CheckIn`, `Data_CheckOut`, `Data_Servico`, `Data_Prevista`, `Data_Pagamento` |
| Contadores positivos | `INTEGER`, `>= 1` | `Capacidade_Maxima`, `Num_Hospedes`, `Quantidade`, `Numero_Prestacao` |
| `Piso` | `SMALLINT` | `QUARTO.Piso` *(admite `0` para rés-do-chão e valores negativos para pisos inferiores)* |
| `Cargo` | `{'rececionista', 'gestor_hotel', 'gestor_cadeia'}` | `FUNCIONARIO.Cargo` |
| `Estado_Reserva` | `{'pendente', 'confirmada', 'cancelada', 'concluida'}` | `RESERVA.Estado_Reserva` |
| `Metodo_Pagamento` | `{'dinheiro', 'cartao_credito', 'cartao_debito', 'mbway', 'paypal', 'transferencia'}` | `PAGAMENTO.Metodo_Pagamento` |
| `Estado_Pagamento` | `{'pendente', 'pago', 'reembolsado'}` | `PAGAMENTO.Estado_Pagamento` |
| `Estado_Manutencao` | `{'livre_limpo', 'em_limpeza', 'em_manutencao'}` | `QUARTO.Estado_Manutencao` |

## 3. Esquema Relacional

* **HOTEL** (<u>ID_Hotel</u>, Nome_Hotel, Morada, Cidade, Pais, Telemovel)
* **TIPO_QUARTO** (<u>ID_TipoQuarto</u>, Nome_Tipo, Descricao`?`, Capacidade_Maxima, Preco_Noite)
* **QUARTO** (<u>ID_Quarto</u>, *ID_Hotel*, *ID_TipoQuarto*, Num_Quarto, Piso, Estado_Manutencao)
* **SERVICO** (<u>ID_Servico</u>, Nome_Servico, Preco_Unitario)
* **HOTEL_SERVICO** (<u>*ID_Hotel*, *ID_Servico*</u>)
* **CLIENTE** (<u>ID_Cliente</u>, Nome, NIF, Doc_Identificacao, Email, Telemovel, Pais)
* **FUNCIONARIO** (<u>ID_Funcionario</u>, *ID_Hotel`?`*, Nome, NIF, Email, Telemovel, Cargo, Data_Contratacao)
* **RESERVA** (<u>ID_Reserva</u>, *ID_Cliente*, *ID_Funcionario`?`*, Data_Criacao, Data_CheckIn, Data_CheckOut, Estado_Reserva, Num_Hospedes)
* **RESERVA_QUARTO** (<u>*ID_Reserva*, *ID_Quarto*</u>)
* **RESERVA_SERVICO** (<u>*ID_Reserva*, *ID_Servico*, Data_Servico</u>, Quantidade, Preco_Aplicado)
* **PAGAMENTO** (<u>ID_Pagamento</u>, *ID_Reserva*, Numero_Prestacao, Valor_Prestacao, Metodo_Pagamento`?`, Estado_Pagamento, Data_Prevista, Data_Pagamento`?`)

## 4. Especificação das Relações e Chaves

| Relação | Chave Primária (PK) | Chaves Candidatas (CK / `UNIQUE`) | Chaves Estrangeiras (FK) |
|---------|---------------------|-----------------------------------|--------------------------|
| **HOTEL** | `ID_Hotel` | `Nome_Hotel` | — |
| **TIPO_QUARTO** | `ID_TipoQuarto` | `Nome_Tipo` | — |
| **QUARTO** | `ID_Quarto` | `(ID_Hotel, Num_Quarto)` | `ID_Hotel` → `HOTEL`<br>`ID_TipoQuarto` → `TIPO_QUARTO` |
| **SERVICO** | `ID_Servico` | `Nome_Servico` | — |
| **HOTEL_SERVICO** | `(ID_Hotel, ID_Servico)` | — | `ID_Hotel` → `HOTEL`<br>`ID_Servico` → `SERVICO` |
| **CLIENTE** | `ID_Cliente` | `NIF`, `Doc_Identificacao`, `Email` | — |
| **FUNCIONARIO** | `ID_Funcionario` | `NIF`, `Email` | `ID_Hotel` → `HOTEL` |
| **RESERVA** | `ID_Reserva` | — | `ID_Cliente` → `CLIENTE`<br>`ID_Funcionario` → `FUNCIONARIO` |
| **RESERVA_QUARTO** | `(ID_Reserva, ID_Quarto)` | — | `ID_Reserva` → `RESERVA`<br>`ID_Quarto` → `QUARTO` |
| **RESERVA_SERVICO** | `(ID_Reserva, ID_Servico, Data_Servico)` | — | `ID_Reserva` → `RESERVA`<br>`ID_Servico` → `SERVICO` |
| **PAGAMENTO** | `ID_Pagamento` | `(ID_Reserva, Numero_Prestacao)` | `ID_Reserva` → `RESERVA` |

*(Nota sobre `RESERVA_SERVICO`: assume-se que utilizações do mesmo serviço na mesma reserva e no mesmo dia são acumuladas em `Quantidade`.)*

## 5. Restrições de Integridade

### 5.1. Integridade de Entidade
Todas as chaves primárias são únicas e não admitem valores `NULL`.

### 5.2. Integridade Referencial (`ON DELETE` e `ON UPDATE`)

Como todas as chaves primárias referenciadas são artificiais e imutáveis, define-se `ON UPDATE NO ACTION` (comportamento por omissão) em todas as chaves estrangeiras.

| Chave Estrangeira | Tabela Origem | Tabela Destino | `ON DELETE` | Justificação |
|-------------------|---------------|----------------|-------------|--------------|
| `ID_Hotel` | `QUARTO` | `HOTEL` | `RESTRICT` | Impede eliminar um hotel que ainda possua quartos registados. |
| `ID_TipoQuarto` | `QUARTO` | `TIPO_QUARTO` | `RESTRICT` | Impede eliminar tipologias associadas a quartos existentes. |
| `ID_Hotel` | `FUNCIONARIO` | `HOTEL` | `RESTRICT` | Impede eliminar um hotel com funcionários afetos. |
| `ID_Cliente` | `RESERVA` | `CLIENTE` | `RESTRICT` | Preserva o histórico de estadias e faturação do cliente. |
| `ID_Funcionario` | `RESERVA` | `FUNCIONARIO` | `SET NULL` | A saída/remoção de um funcionário não deve bloquear nem apagar o histórico de reservas. |
| `ID_Reserva` | `RESERVA_QUARTO` | `RESERVA` | `CASCADE` | A alocação de quartos não tem sentido sem a respetiva reserva. |
| `ID_Quarto` | `RESERVA_QUARTO` | `QUARTO` | `RESTRICT` | Impede eliminar um quarto com histórico de reservas. |
| `ID_Reserva` | `RESERVA_SERVICO` | `RESERVA` | `CASCADE` | Elimina consumos associados caso uma reserva sem pagamentos seja apagada. |
| `ID_Servico` | `RESERVA_SERVICO` | `SERVICO` | `RESTRICT` | Protege o histórico de serviços já faturados em reservas. |
| `ID_Reserva` | `PAGAMENTO` | `RESERVA` | `RESTRICT` | Impede eliminar reservas que tenham pagamentos/prestações registadas. |
| `ID_Hotel` | `HOTEL_SERVICO` | `HOTEL` | `CASCADE` | Remove a oferta local se o hotel for eliminado (desde que sem quartos/funcionários). |
| `ID_Servico` | `HOTEL_SERVICO` | `SERVICO` | `CASCADE` | Remove o serviço do catálogo local dos hotéis (desde que não utilizado em reservas). |

### 5.3. Rastreabilidade das Regras de Negócio e Restrições Semânticas

| Regra | Mecanismo de Implementação | Relação(ões) | Descrição |
|-------|----------------------------|--------------| --------- | 
| **RN01** | `ID_Cliente NOT NULL` + `FOREIGN KEY` | `RESERVA` | Cada reserva tem de estar associada a um único cliente. |
| **RN02** | `CHECK (Data_CheckOut > Data_CheckIn)` | `RESERVA` | Check-out estritamente posterior ao check-in. |
| **RN03** | Não sobreposição de reservas ativas (`pendente`, `confirmada`, `concluida`) no mesmo quarto — regra inter-registos/inter-tabelas a garantir na **Fase 3** (trigger / restrição de exclusão). | `RESERVA`, `RESERVA_QUARTO` | Não pode haver sobreposição de datas de reserva para o mesmo quarto (exceto canceladas).  |
| **RN04** | `Num_Hospedes` ≤ soma de `Capacidade_Maxima` dos quartos da reserva — envolve agregação entre várias tabelas, logo a garantir via **trigger na Fase 3**. | `RESERVA`, `RESERVA_QUARTO`, `QUARTO`, `TIPO_QUARTO` | O número de hóspedes nunca poderá exceder a capacidade máxima. |
| **RN05** | `UNIQUE (NIF)` e `UNIQUE (Doc_Identificacao)` | `CLIENTE` | NIF e documento de identificação únicos por cliente. |
| **RN06** | `CHECK (valor > 0)` em `Preco_Noite`, `Preco_Unitario`, `Preco_Aplicado` e `Valor_Prestacao` | `TIPO_QUARTO`, `SERVICO`, `RESERVA_SERVICO`, `PAGAMENTO` | Todos os valores monetários > 0. | 
| **RN07** | Atributo escalar único `Metodo_Pagamento` por registo de pagamento | `PAGAMENTO` | Registo com método de pagamento único por transação. |
| **RN08** | `CHECK ((Cargo = 'gestor_cadeia' AND ID_Hotel IS NULL) OR (Cargo IN ('rececionista', 'gestor_hotel') AND ID_Hotel IS NOT NULL))` | `FUNCIONARIO` | Cargo gestor_cadeia não afeto a hotel; restantes obrigatórios. |

**Restrições adicionais do modelo:**
* `RESERVA`: `CHECK (Num_Hospedes >= 1)` e domínio de `Estado_Reserva`.
* `TIPO_QUARTO`: `CHECK (Capacidade_Maxima >= 1)`.
* `RESERVA_SERVICO`: `CHECK (Quantidade >= 1)`.
* `PAGAMENTO`: `CHECK (Numero_Prestacao >= 1)`, `UNIQUE (ID_Reserva, Numero_Prestacao)` e `CHECK (Estado_Pagamento = 'pendente' OR (Data_Pagamento IS NOT NULL AND Metodo_Pagamento IS NOT NULL))`.
* **Consistência inter-tabelas (a tratar por trigger na Fase 3):**
  1. Todos os quartos associados à mesma reserva (`RESERVA_QUARTO`) devem pertencer ao **mesmo hotel** (necessário para responder sem ambiguidade a **Q07** — receita por hotel).
  2. Qualquer serviço registado em `RESERVA_SERVICO` deve constar na oferta (`HOTEL_SERVICO`) do hotel onde decorre a reserva.

## 6. Evolução face à Fase 1

1. Introdução de `ID_Quarto` em `QUARTO` e da chave candidata `(ID_Hotel, Num_Quarto)` (**D1**).
2. Substituição de `RESERVA.Num_Quarto` pela tabela associativa `RESERVA_QUARTO` (**D2**).
3. Formalização de `PAGAMENTO.Reserva_ID` como `FK ID_Reserva` numa relação `1:N` com `RESERVA` (**D3**).
4. Alteração de `FUNCIONARIO.ID_Hotel` para opcional (`NULL`), alinhando o modelo com a **RN08** (**D4**).
5. Criação das relações associativas `RESERVA_SERVICO` e `HOTEL_SERVICO` (**D5, D6**).
6. Remoção de `Telemovel` como chave candidata (**D11**) e remoção de `'ocupado'` de `Estado_Manutencao` (**D10**).
7. Ajuste do domínio de `NIF` de `VARCHAR(100)` para `VARCHAR(20)`.