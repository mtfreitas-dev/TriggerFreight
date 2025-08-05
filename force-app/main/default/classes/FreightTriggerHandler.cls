public with sharing class FreightTriggerHandler {

    //Armazena os valores que serão manipulados
    //Stores the values ​​that will be manipulated

    List<Freight__c> oldRecords {get; set;}
    List<Freight__c> newRecords {get; set;}
    Map<Id, Freight__c> oldMap {get; set;}
    Map<Id, Freight__c> newMap {get; set;}

    public FreightTriggerHandler(List<Freight__c> oldRecords, List<Freight__c> newRecords, Map<Id, Freight__c> oldMap, Map<Id, Freight__c> newMap) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;   
    }

    //Este método aciona outras funções quando a trigger na condição é acionada
    //This method triggers other functions when the trigger in the condition is triggered

    public void beforeInsert() {
        FreightHelper.calculateScore(this.newRecords);
    }
}
