# 🚚 TriggerFreight

Este repositório contém uma implementação de lógica de cálculo de frete automatizado na plataforma Salesforce, utilizando Apex, triggers e arquitetura orientada a handlers. O sistema é capaz de calcular, validar e atribuir automaticamente fretes aos pedidos com base em critérios como localização (CEP, cidade, estado) e características dos itens (peso, volume, quantidade).

---

## 📦 Funcionalidades

- **Validação de dados de frete**: garante que fretes contenham pelo menos um campo de localização (CEP, Cidade ou Estado).
- **Pontuação de fretes**: fretes recebem uma pontuação baseada na granularidade da localização.
- **Cálculo de frete automático**: ao inserir, atualizar ou excluir itens de pedidos (`OrderItem`), o sistema recalcula o frete ideal.
- **Associação de frete ao pedido**: o pedido recebe o frete de melhor custo e melhor pontuação.
- **Validação de status do pedido**: impede alterações em pedidos que não estejam com status `Draft`.
- **Lógica desacoplada e reutilizável** via classes helper e trigger handlers.

---

## 🧠 Lógica de Negócio

### 🔹 Frete (Freight__c)

A classe `FreightHelper` calcula a pontuação do frete:

| Campo preenchido | Pontuação |
|------------------|-----------|
| CEP              | 100       |
| Cidade           | 50        |
| Estado           | 25        |

> ⚠️ Caso nenhum desses campos esteja preenchido, o frete é bloqueado com erro.

---

### 🔹 Pedido (Order) e Itens (OrderItem)

As classes `OrderItemHelper` e `OrderItemTriggerHandler` gerenciam:

1. **Validação de Itens**: impede alteração se o pedido não estiver como `Draft`.

2. **Cálculo de Frete**:
   - Busca os fretes que correspondem ao endereço da conta (por CEP, cidade ou estado).
   - Calcula três tipos de valor:
     - Frete por peso
     - Frete por volume
     - Frete por quantidade
   - Seleciona o **maior** desses valores como o custo final do frete.
   - Escolhe o **frete com maior pontuação e menor custo**.
   - Atualiza os campos no pedido:
     - `Freight__c`
     - `TotalFreight__c`
     - `DistributionCenter__c`

---

## 🧱 Estrutura de Classes

| Classe | Descrição |
|--------|-----------|
| `FreightHelper` | Calcula a pontuação dos fretes. |
| `FreightTriggerHandler` | Lógica de trigger para Freight__c. |
| `OrderItemHelper` | Lógica de cálculo de frete e validação de itens. |
| `OrderItemTriggerHandler` | Controla os eventos de trigger dos itens de pedido. |
| `FreightTrigger` | Trigger para Freight__c (before insert). |
| `OrderItemTrigger` | Trigger para OrderItem (before/after insert/update/delete). |

---

## 📌 Requisitos

- Salesforce DX (SFDX)
- Objeto personalizado `Freight__c` com os seguintes campos:
  - `CEP__c` (Text)
  - `City__c` (Lookup ou Text)
  - `State__c` (Text)
  - `FreightByWeight__c` (Number)
  - `FreightByVolume__c` (Number)
  - `FreightBase__c` (Number)
  - `Score__c` (Number)
  - `DistributionCenter__c` (Lookup ou Id)

- Objeto `OrderItem` com os campos:
  - `Weight__c` (Number)
  - `Volume__c` (Number)

- Objeto `Order` com os campos:
  - `Freight__c` (Lookup para Freight__c)
  - `TotalFreight__c` (Number)
  - `DistributionCenter__c` (Id ou Lookup)

---

## 🧪 Testes

Para garantir a qualidade da lógica, recomenda-se a criação de classes de teste com foco em:

- Validação de fretes inválidos.
- Cálculo de frete com diferentes combinações de localização.
- Comportamento ao inserir/alterar itens de pedido.
- Validação de status do pedido.

---

## ✍️ Autor

Desenvolvido por [Matheus Freitas](https://github.com/mtfreitas-dev)

---

## 📄 Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo [LICENSE](../LICENSE) para mais detalhes.
