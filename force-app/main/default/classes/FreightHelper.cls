public with sharing class FreightHelper {
    public FreightHelper() {}

    public static void calculateScore(List<Freight__c> freightList) {
        for (Freight__c freight : freightList) {
            Integer score = 0;
            Boolean checkDeliveryInfo = false;

            if (!String.isEmpty(freight.CEP__C)) {
                score += 100;
                checkDeliveryInfo = true;
            }

            if (!String.isEmpty(freight.City__c)) {
                score += 50;
                checkDeliveryInfo = true;
            }

            if (!String.isEmpty(freight.State__c)) {
                score += 25;
                checkDeliveryInfo = true;
            }

            if (!checkDeliveryInfo) {
                freight.addError('Frete necessita de um campo de entrega preenchido');
            }
            else {
                freight.Score__c = score;
            }         
        }
    }
}