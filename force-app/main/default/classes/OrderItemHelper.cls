public with sharing class OrderItemHelper {

    public class FreightScore {
        Freight__c freight {get; set;}
        Integer priorityScore {get; set;}

        public FreightScore() {}
        
        public FreightScore(Freight__c freight, Integer priorityScore) {
            this.freight = freight;
            this.priorityScore = priorityScore;
        }
    }   

        //Check se orderItem está ok quando der update
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
                    newItem.addError('Error');
    
                }
            }
        }

         //check orderItem 
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
                orderItem.addError('Error');

            }
        }
    }

    //Metodo responsavel pela atualização do valor do frete (Calcula a partir de uma atualização no pedido)
    public static List<Order> calculateFreight(Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap) {
        Set<Id> orderIds = new Set<Id>();

        //Realiza a interação dos itens do pedido e verifica se ocorreram alteração nos registros, caso sim atualiza o Set de OrderIds
        for (OrderItem newItem : newMap.values()) {
            OrderItem oldItem = oldMap.get(newItem.Id);

            if ((newItem.Quantity != oldItem.Quantity) || 
                (newItem.Volume__c != oldItem.Volume__c) || 
                (newItem.Weight__c != oldItem.Weight__c)) {
                orderIds.add(newItem.OrderId);
            }
        }

        //Faz uma busca no banco de dados e retorna dos dados de localização do pedido (Referente a conta vinculada)
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

         //Metodo responsavel pelo calculo do frete (Calcula a partir de uma inserção no pedido)
    public static List<Order> calculateFreight(List<OrderItem> orderItemList) {
        Set<Id> orderIds = new Set<Id>();

        //Realiza a interação dos intens do pedido e adiciona ao Set de OrderIds
        for (OrderItem orderItem : orderItemList) {
            orderIds.add(orderItem.OrderId);
        }

          //Faz uma busca no banco de dados e retorna dos dados de localização do pedido (Referente a conta vinculada) 
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

     //Metodo responsavel por realizar a buscas dos fretes em relação a localização do pedido   
     public static List<Freight__c> searchFreight(Map<Id, Order> orderMap) {
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<String> cepIds = new Set<String>();

        //Realiza a interação dos valores do pedido e armazena as informações de localização (En relação aos dados da conta)
        for (Order order : orderMap.values()) {
            cepIds.add(order.Account.CEP__c);
            cityIds.add(order.Account.City__c);
            stateIds.add(order.Account.City__r.State__c);
        }

        //Realiza a busca no banco de dados das informações de localização e ordena com base no valor do score de cada frete
        List<Freight__c> freightList = [
            SELECT Id, Name, CEP__c, City__c, State__c, DistributionCenter__c, FreightByWeight__c, FreightByVolume__c, FreightBase__c 
            FROM Freight__c
            WHERE CEP__c IN: cepIds OR
            City__c IN: cityIds OR
            State__c IN: stateIds
            ORDER BY DistributionCenter__c
        ];

        return freightList;
    }

    //Metodo responsavel por agregar os valores referentes aos pedidos realizando a soma de todos os itens contidos nele
    public static List<AggregateResult> aggregateOrderByItems(Set<Id> orderIds) {
        List<AggregateResult> resultList = [
            SELECT OrderId, SUM(Weight__c) TotalWeight, SUM(Volume__c) TotalVolume, SUM(Quantity) TotalQuantity 
            FROM OrderItem 
            WHERE OrderId IN: orderIds 
            GROUP BY OrderId
        ];
        return resultList;
    }

    //Realiza a interação entre os pedidos e os fretes para definição da prioridade (Score mais elevado)
    public static List<Order> aggregateOrderToFreight(List<AggregateResult> resultList, List<Freight__c> freightList, Map<Id, Order> orderMap) {
        Map<Id, Map<Id, FreightScore>> orderToFreightMap = new Map<Id, Map<Id, FreightScore>>();

        for (Order order : orderMap.values()) {
            for (Freight__c freight : freightList) {
                Id distributionId = freight.DistributionCenter__c;
                Integer priorityScore = 0;

                //CEP - Prioridade 1
                if (order.Account.CEP__c == freight.CEP__c) {
                    priorityScore += 1000;
                }

                //Cidade - Prioridade 2                
                if (order.Account.City__c == freight.City__c) {
                    priorityScore += 100;
                }

                //Estado - Prioridade 3
                if (order.Account.City__r.State__c == freight.State__c) {
                    priorityScore += 10;
                }

                if (priorityScore > 0) {
                    if (orderToFreightMap.containsKey(order.Id)) {
                        if(!orderToFreightMap.get(order.Id).containsKey(distributionId)) {
                            orderToFreightMap.get(order.Id).put(distributionId, new FreightScore(freight, priorityScore));
                        } 
                        else if (orderToFreightMap.get(order.Id).get(distributionId).priorityScore < priorityScore) {
                            orderToFreightMap.get(order.Id).put(distributionId, new FreightScore(freight, priorityScore));
                        }
                    }
                    else {
                        orderToFreightMap.put(
                            order.Id,
                            new Map<Id, FreightScore>{
                                distributionId => new FreightScore(freight, priorityScore)
                            } 
                        );
                    }
                }                
            }
        }
        
        //Realiza a interação dos valores resultates da lista de agregação com base nos pedidos
        for (AggregateResult result : resultList) {
            Id orderId = (Id)result.get('OrderId');
            Decimal totalWeight = (Decimal)result.get('TotalWeight');
            Decimal totalVolume = (Decimal)result.get('TotalVolume');
            Decimal totalQuantity = (Decimal)result.get('TotalQuantity');
            Id bestFreightId = null;
            Id bestDistributionId = null;
            Decimal bestFreightPrice = 0;
            
            for (Id distributionId : orderToFreightMap.get(orderId).keySet()) {
                Freight__c freight = orderToFreightMap.get(orderId).get(distributionId).freight;
                Decimal freightPrice = getBestFreightPrice(freight, totalWeight, totalVolume, totalQuantity);

                if (freightPrice < bestFreightPrice || bestFreightPrice == 0) {
                    bestFreightPrice = freightPrice;
                    bestFreightId = freight.Id;
                    bestDistributionId = distributionId;
                }
            }

            Order order = orderMap.get(orderId);
            order.Freight__c = bestFreightId;
            order.TotalFreight__c = bestFreightPrice;
            order.DistributionCenter__c = bestDistributionId;
        }

          //Realiza uma interação dos pedidos e adiciona os pedidos atualizados a lista
          List<Order> orderList = new List<Order>();

          for (Order order : orderMap.values()) {
              orderList.add(order);
          }
          return orderList;
      }

      public static Decimal getBestFreightPrice(Freight__c freight, Decimal totalWeight, Decimal totalVolume, Decimal totalQuantity) {
        
        //Realiza o calculo de cada um dos tipos de frete seguindo a premissa: Soma(Valores dos itens do pedido) * valor definido para o tipo de frete
        Decimal WeightPrice = totalWeight * freight.FreightByWeight__c;
        Decimal VolumePrice = totalVolume * freight.FreightByVolume__c;
        Decimal QuantityPrice = totalQuantity * freight.FreightBase__c;
        Decimal freightPrice = 0;

        //Verifica qual o maior frete dentre as três opções calculadas
        if((VolumePrice > WeightPrice) && (VolumePrice > QuantityPrice)){
            freightPrice = VolumePrice;
        }else if((WeightPrice > VolumePrice) && (WeightPrice > QuantityPrice)){
            freightPrice = WeightPrice;
        }else{
            freightPrice = QuantityPrice;
        }

        return freightPrice;

    }
}