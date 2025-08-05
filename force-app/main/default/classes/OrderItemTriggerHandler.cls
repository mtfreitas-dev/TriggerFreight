public with sharing class OrderItemTriggerHandler {

    //Armazena os valores que serão manipulados
    //Stores the values ​​that will be manipulated

    List<OrderItem> oldRecords {get; set;} // Trigger.old
    List<OrderItem> newRecords {get; set;} //Trigger.new
    Map<Id, OrderItem> oldMap {get; set;} //Trigger.oldMap
    Map<Id, OrderItem> newMap {get; set;} //Trigger.newMap

    public OrderItemTriggerHandler(List<OrderItem> oldRecords, List<OrderItem> newRecords, Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    //Este método aciona outras funções quando a trigger na condição é acionada
    //This method triggers other functions when the trigger in the condition is triggered

    public void beforeInsert() {
        OrderItemHelper.checkOrderItem(this.newRecords);
    }

    public void afterInsert() {
        List<Order> orderList = OrderItemHelper.calculateFreight(this.newRecords);
        if(!orderList.isEmpty()) {
            update orderList;
        }
    }

    public void beforeUpdate() {
        OrderItemHelper.checkOrderItem(this.oldMap, this.newMap);
    }

    public void afterUpdate() {
        List<Order> orderList = OrderItemHelper.calculateFreight(this.oldMap, this.newMap);
        if(orderList != null && !orderList.isEmpty()) {
            update orderList;
        }
    }

    public void beforeDelete() {
        OrderItemHelper.checkOrderItem(this.oldRecords);
    }

    public void afterDelete() {
        List<Order> orderList = OrderItemHelper.calculateFreight(this.oldRecords);
        if(!orderList.isEmpty()) {
            update orderList;
        }
    }
}
