public with sharing class FreightTriggerHandler {
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

    public void beforeInsert() {
        FreightHelper.calculateScore(this.newRecords);
    }
}