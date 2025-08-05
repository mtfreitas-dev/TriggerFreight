public with sharing class OrderItemHelper {
    
    /**
     * Inner class that associates a Freight record with its priority score.
     * Used to determine the best freight option for an order.
     * 
     * Classe interna que associa um registro de Frete com seu score de prioridade.
     * Usado para determinar a melhor opção de frete para um pedido.
     */
    public class FreightScore {
        @AuraEnabled public Freight__c freight {get; set;}
        @AuraEnabled public Integer priorityScore {get; set;}

        public FreightScore() {}
        
        public FreightScore(Freight__c freight, Integer priorityScore) {
            this.freight = freight;
            this.priorityScore = priorityScore;
        }
    }

    /**
     * Validates if OrderItems can be modified when their parent Order is not in Draft status.
     * Throws an error if modification is attempted on a non-Draft order.
     * 
     * Valida se OrderItems podem ser modificados quando o Pedido pai não está em status Rascunho.
     * Lança um erro se tentar modificar um pedido que não está em rascunho.
     */
    public static void checkOrderItem(Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap) {
        Set<Id> orderIds = new Set<Id>();
        for (OrderItem newItem : newMap.values()) {
            orderIds.add(newItem.OrderId);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, Status
            FROM Order
            WHERE Id IN: orderIds
        ]);

        for (OrderItem newItem : newMap.values()) {
            if (orderMap.get(newItem.OrderId).Status != 'Draft') {
                newItem.addError('Não é possível modificar itens de pedidos finalizados');
            }
        }
    }

    /**
     * Overloaded version for insert operations - validates new OrderItems
     * Versão sobrecarregada para operações de inserção - valida novos OrderItems
     */
    public static void checkOrderItem(List<OrderItem> orderItemList) {
        Set<Id> orderIds = new Set<Id>();
        for (OrderItem orderItem : orderItemList) {
            orderIds.add(orderItem.OrderId);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, Status
            FROM Order
            WHERE Id IN: orderIds
        ]);

        for (OrderItem orderItem : orderItemList) {
            if (orderMap.get(orderItem.OrderId).Status != 'Draft') {
                orderItem.addError('Não é possível adicionar itens a pedidos finalizados');
            }
        }
    }

    /**
     * Main freight calculation method for updated OrderItems.
     * Triggers recalculation when quantity, volume or weight changes.
     * Returns updated Orders with new freight values.
     * 
     * Método principal de cálculo de frete para OrderItems atualizados.
     * Dispara recálculo quando quantidade, volume ou peso mudam.
     * Retorna Pedidos atualizados com novos valores de frete.
     */
    public static List<Order> calculateFreight(Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap) {
        Set<Id> orderIds = new Set<Id>();

        for (OrderItem newItem : newMap.values()) {
            OrderItem oldItem = oldMap.get(newItem.Id);

            if ((newItem.Quantity != oldItem.Quantity) || 
                (newItem.Volume__c != oldItem.Volume__c) || 
                (newItem.Weight__c != oldItem.Weight__c)) {
                orderIds.add(newItem.OrderId);
            }
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId, Account.City__c, Account.City__r.State__c, Account.CEP__c
            FROM Order
            WHERE Id IN: orderIds
        ]);

        List<Freight__c> freightList = searchFreight(orderMap);
        List<AggregateResult> resultList = aggregateOrderByItems(orderIds);
        List<Order> orderList = aggregateOrderToFreight(resultList, freightList, orderMap);
        return orderList;
    }

    /**
     * Freight calculation method for new OrderItems (insert operation)
     * Método de cálculo de frete para novos OrderItems (operação de inserção)
     */
    public static List<Order> calculateFreight(List<OrderItem> orderItemList) {
        Set<Id> orderIds = new Set<Id>();

        for (OrderItem orderItem : orderItemList) {
            orderIds.add(orderItem.OrderId);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId, Account.City__c, Account.City__r.State__c, Account.CEP__c
            FROM Order
            WHERE Id IN: orderIds
        ]);

        List<Freight__c> freightList = searchFreight(orderMap);
        List<AggregateResult> resultList = aggregateOrderByItems(orderIds);
        List<Order> orderList = aggregateOrderToFreight(resultList, freightList, orderMap);
        
        return orderList;
    }

    /**
     * Searches for applicable freight options based on the order's location.
     * Priority: CEP (zip code) > City > State
     * 
     * Busca opções de frete aplicáveis baseadas na localização do pedido.
     * Prioridade: CEP > Cidade > Estado
     */
    public static List<Freight__c> searchFreight(Map<Id, Order> orderMap) {
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<String> cepIds = new Set<String>();

        for (Order order : orderMap.values()) {
            cepIds.add(order.Account.CEP__c);
            cityIds.add(order.Account.City__c);
            stateIds.add(order.Account.City__r.State__c);
        }

        return [
            SELECT Id, Name, CEP__c, City__c, State__c, DistributionCenter__c, 
                   FreightByWeight__c, FreightByVolume__c, FreightBase__c 
            FROM Freight__c
            WHERE CEP__c IN: cepIds OR
                  City__c IN: cityIds OR
                  State__c IN: stateIds
            ORDER BY DistributionCenter__c
        ];
    }

    /**
     * Aggregates OrderItem values (weight, volume, quantity) by Order
     * Agrega valores de OrderItem (peso, volume, quantidade) por Pedido
     */
    public static List<AggregateResult> aggregateOrderByItems(Set<Id> orderIds) {
        return [
            SELECT OrderId, SUM(Weight__c) TotalWeight, SUM(Volume__c) TotalVolume, SUM(Quantity) TotalQuantity 
            FROM OrderItem 
            WHERE OrderId IN: orderIds 
            GROUP BY OrderId
        ];
    }

    /**
     * Core freight calculation logic that:
     * 1. Matches orders with available freight options
     * 2. Calculates prices based on different freight types
     * 3. Selects the best option for each order
     * 
     * Lógica principal de cálculo de frete que:
     * 1. Associa pedidos com opções de frete disponíveis
     * 2. Calcula preços baseados em diferentes tipos de frete
     * 3. Seleciona a melhor opção para cada pedido
     */
    public static List<Order> aggregateOrderToFreight(List<AggregateResult> resultList, List<Freight__c> freightList, Map<Id, Order> orderMap) {
        Map<Id, Map<Id, FreightScore>> orderToFreightMap = new Map<Id, Map<Id, FreightScore>>();

        // Build priority map of freight options for each order
        for (Order order : orderMap.values()) {
            for (Freight__c freight : freightList) {
                Id distributionId = freight.DistributionCenter__c;
                Integer priorityScore = 0;

                // CEP match - highest priority
                if (order.Account.CEP__c == freight.CEP__c) {
                    priorityScore += 1000;
                }

                // City match - medium priority
                if (order.Account.City__c == freight.City__c) {
                    priorityScore += 100;
                }

                // State match - lowest priority
                if (order.Account.City__r.State__c == freight.State__c) {
                    priorityScore += 10;
                }

                if (priorityScore > 0) {
                    if (!orderToFreightMap.containsKey(order.Id)) {
                        orderToFreightMap.put(order.Id, new Map<Id, FreightScore>());
                    }
                    
                    if(!orderToFreightMap.get(order.Id).containsKey(distributionId) || 
                       orderToFreightMap.get(order.Id).get(distributionId).priorityScore < priorityScore) {
                        orderToFreightMap.get(order.Id).put(distributionId, new FreightScore(freight, priorityScore));
                    }
                }                
            }
        }
        
        // Calculate best freight option for each order
        for (AggregateResult result : resultList) {
            Id orderId = (Id)result.get('OrderId');
            Decimal totalWeight = (Decimal)result.get('TotalWeight');
            Decimal totalVolume = (Decimal)result.get('TotalVolume');
            Decimal totalQuantity = (Decimal)result.get('TotalQuantity');
            
            Decimal bestFreightPrice = 0;
            Id bestFreightId = null;
            Id bestDistributionId = null;
            
            for (Id distributionId : orderToFreightMap.get(orderId).keySet()) {
                Freight__c freight = orderToFreightMap.get(orderId).get(distributionId).freight;
                Decimal freightPrice = getBestFreightPrice(freight, totalWeight, totalVolume, totalQuantity);

                if (bestFreightPrice == 0 || freightPrice < bestFreightPrice) {
                    bestFreightPrice = freightPrice;
                    bestFreightId = freight.Id;
                    bestDistributionId = distributionId;
                }
            }

            // Update order with selected freight
            Order order = orderMap.get(orderId);
            order.Freight__c = bestFreightId;
            order.TotalFreight__c = bestFreightPrice;
            order.DistributionCenter__c = bestDistributionId;
        }

        return new List<Order>(orderMap.values());
    }

    /**
     * Calculates freight price based on three different methods:
     * 1. By weight
     * 2. By volume
     * 3. Base price by quantity
     * Returns the highest of the three values
     * 
     * Calcula preço de frete baseado em três métodos diferentes:
     * 1. Por peso
     * 2. Por volume
     * 3. Preço base por quantidade
     * Retorna o maior dos três valores
     */
    public static Decimal getBestFreightPrice(Freight__c freight, Decimal totalWeight, Decimal totalVolume, Decimal totalQuantity) {
        Decimal weightPrice = totalWeight * freight.FreightByWeight__c;
        Decimal volumePrice = totalVolume * freight.FreightByVolume__c;
        Decimal quantityPrice = totalQuantity * freight.FreightBase__c;

        return Math.max(weightPrice, Math.max(volumePrice, quantityPrice));
    }
}
