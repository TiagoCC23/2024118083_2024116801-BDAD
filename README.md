# 2024118083_2024116801-BDAD

![Language](https://img.shields.io/badge/Language-SQL-2677C7.svg)
![Course](https://img.shields.io/badge/Course-BDAD-DB7533.svg)
![University](https://img.shields.io/badge/University-UFP-00764B.svg)

> **Projeto Prático de Desenvolvimento de Software em SQL**
> 
> *Bases de Dados I*
> 
> ***FEITO POR: Rayssa Santos e Tiago Chousal***

---

# Tema: 
Base de dados de um Alojamento Local/ Hotel

---
## Estrutura
```
sql/
  01_schema.sql          # Criação previsível do esquema (6.3)
  02_seed_data.sql       # Povoamento de dados (6.4)
  03_queries.sql         # Início das consultas Q01-Q07 (6.5)
fase2/
  6.1/Modelo_Relacional.md
  6.2/Normalizacao.md
  6.3/Implementacao_PostgreSQL.md
```

---

## Análise e âmbito
O domínio consiste no desenvolvimento de uma base de dados relacional para gerir o funcionamento de uma unidade de Alojamento Local/Hotel. O sistema abrange a gestão de quartos e respetivas tipologias, registro e acompanhamento de clientes, gestão das reservas, faturação/pagamentos e disponibilização de serviços adicionais (transportes, spa, café da manhã…). 
Considera-se que cada reserva diz respeito a um único quarto e a um único cliente. 

O objetivo é garantir o controle rigoroso da disponibilidade de quartos, evitar sobreposições de reservas (overbooking), assegurar o cumprimento da capacidade máxima por quarto e manter o histórico completo de estadias e pagamentos.


## Glossário:
* **Cliente**: Pessoa individual que efetua a reserva e/ou desfruta da estadia na unidade de alojamento.
* **Quarto**: Unidade física de alojamento disponível para ocupação.
* **Tipo de Quarto**: Categoria do quarto que define a capacidade máxima de hóspedes e o preço base por noite.
* **Reserva**: Registo formal de uma intenção de ocupação de um quarto por um cliente num determinado intervalo de datas (check-in e check-out).
* **Pagamento**: Registo da transação financeira referente ao valor total de uma reserva ou serviço.
* **Serviço**: Prestação adicional disponibilizada pelo hotel para o cliente durante a sua estadia.
* **Funcionário**: Colaborador do hotel responsável por processar reservas, check-in/check-out e registar serviços. 
* **Hotel**: Unidade física da cadeia hoteleira, com os seus próprios quartos e funcionários. 


---

## Requisitos de dados
* **RD01** – O sistema deve registar os dados dos funcionários (nome, NIF, e-mail, telefone, cargo e data de contratação).
* **RD02** – O sistema deve registar os quartos (número/identificador, piso, estado de limpeza/manutenção) e associá-los ao respetivo tipo de quarto.
* **RD03** – O sistema deve manter o registo das categorias de quarto, indicando a descrição, a capacidade máxima de pessoas e a tarifa base por noite.
* **RD04** – O sistema deve armazenar os dados identificativos dos clientes (nome, NIF, e-mail, telefone, documento de identificação e país).
* **RD05** – O sistema deve guardar o histórico e o estado atual das reservas (data de criação, data de check-in, data de check-out, estado da reserva — pendente, confirmada, cancelada, concluída — e cliente associado).
* **RD06** – O sistema deve guardar a informação financeira de cada reserva (montante total, data do pagamento, método de pagamento utilizado e estado do pagamento).
* **RD07** – O sistema deve registar o nome do serviço adicional.

---

## Regras de negócio
* **RN01** – Cada reserva tem de estar compulsoriamente associada a um único cliente registrado.
* **RN02** – A data de check-out deve ser estritamente posterior à data de check-in.
* **RN03** – Um mesmo quarto não pode ter mais do que uma reserva pendente, confirmada ou concluída para o mesmo intervalo de datas (as reservas canceladas não ocupam o quarto). 
* **RN04** – O número de hóspedes associado a uma reserva não pode exceder a capacidade máxima definida para a tipologia do quarto selecionado.
* **RN05** – O NIF e o documento de identificação do cliente devem ser únicos no sistema, impedindo registos duplicados.
* **RN06** – Todos os valores monetários devem ser estritamente superiores a zero.
* **RN07** – Cada transação/registo de pagamento utiliza um único método de pagamento.
* **RN08** – O campo ID_Hotel em Funcionario é obrigatório para os cargos 'rececionista' e 'gestor_hotel', e deve ser nulo para 'gestor_cadeia'.

---

## Atores e necessidades de acesso
Cliente: Consultar a disponibilidade de quartos, criar reservas próprias, consultar o histórico do seu perfil/reservas e efetuar pagamentos.
Recepcionista/Funcionário: Consultar e gerir a disponibilidade dos quartos, efetuar check-in/check-out, registar/alterar reservas, registar serviços adicionais e emitir/consultar pagamentos.
Gestor do hotel: Acesso completo para consultar, alterar e analisar todos os dados do sistema (quartos, clientes, reservas, faturação e relatórios de ocupação/serviços).

---

## Necessidades de Informação
* **Q01**: Quais são os quartos disponíveis (não reservados) para um determinado intervalo de datas?
* **Q02**: Qual é o histórico de reservas efetuadas por um determinado cliente?
* **Q03**: Qual é o valor total de faturação acumulado por método de pagamento num determinado mês?
* **Q04**: Em quantas reservas foi incluído cada serviço adicional? 
* **Q05**: Qual é a taxa de ocupação dos quartos agrupada por tipo de quarto num determinado período?
* **Q06**: Quais são as reservas pendentes de pagamento cuja data de check-in é no próprio dia?
