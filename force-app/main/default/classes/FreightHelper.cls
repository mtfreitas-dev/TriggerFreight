public with sharing class FreightHelper {
    
    // Empty constructor
    // Construtor vazio
    public FreightHelper() {}

    // Method to calculate a freight score based on delivery information
    // Método para calcular um score de frete baseado nas informações de entrega
    public static void calculateScore(List<Freight__c> freightList) {
        
        // Loop through each freight record in the list
        // Loop através de cada registro de frete na lista
        for (Freight__c freight : freightList) {
            
            // Initialize score and delivery info check flag
            // Inicializa o score e o flag de verificação de informações de entrega
            Integer score = 0;
            Boolean checkDeliveryInfo = false;

            // Check if CEP (ZIP code) is filled and add to score
            // Verifica se CEP está preenchido e adiciona ao score
            if (!String.isEmpty(freight.CEP__C)) {
                score += 100;
                checkDeliveryInfo = true;
            }

            // Check if City is filled and add to score
            // Verifica se Cidade está preenchida e adiciona ao score
            if (!String.isEmpty(freight.City__c)) {
                score += 50;
                checkDeliveryInfo = true;
            }

            // Check if State is filled and add to score
            // Verifica se Estado está preenchido e adiciona ao score
            if (!String.isEmpty(freight.State__c)) {
                score += 25;
                checkDeliveryInfo = true;
            }

            // If no delivery information is provided, add error
            // Se nenhuma informação de entrega for fornecida, adiciona erro
            if (!checkDeliveryInfo) {
                freight.addError('Frete necessita de um campo de entrega preenchido');
            }
            else {
                // Otherwise, update the freight score
                // Caso contrário, atualiza o score do frete
                freight.Score__c = score;
            }         
        }
    }
}
