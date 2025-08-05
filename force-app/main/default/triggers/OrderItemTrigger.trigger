// Trigger that handles OrderItem object events (insert, update)
// Gatilho que trata eventos do objeto OrderItem (inserção, atualização)
trigger OrderItemTrigger on OrderItem (before insert, after insert, before update, after update, before delete, after delete) {

    // Creates an instance of the trigger handler class, passing the trigger context variables
    // Cria uma instância da classe manipuladora do trigger, passando as variáveis de contexto do trigger
    OrderItemTriggerHandler handler = new OrderItemTriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    // Switch statement to handle different trigger operations
    // Estrutura switch para tratar diferentes operações do trigger
    switch on Trigger.operationType {
        // Before insert context
        // Contexto de antes da inserção
        when BEFORE_INSERT {
            handler.beforeInsert();
        }
        
        // After insert context
        // Contexto de depois da inserção
        when AFTER_INSERT {
            handler.afterInsert();
        }

        // Before update context
        // Contexto de antes da atualização
        when BEFORE_UPDATE {
            handler.beforeUpdate();
        }

        // After update context
        // Contexto de depois da atualização
        when AFTER_UPDATE {
            handler.afterUpdate();
        }

        // Before delete context
        // Contexto de antes da exclusão
        when BEFORE_DELETE {
            handler.beforeDelete();
        }

        // After delete context
        // Contexto de depois da exclusão
        when AFTER_DELETE {
            handler.afterDelete();
        }
    }
}
