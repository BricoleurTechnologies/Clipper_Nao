trigger InventoryMovementTrigger on Inventory_Movement__c (before insert, before update, after insert, after update) {
    
    List<TriggerSetting__mdt> triggerSetting = [SELECT Id, DeveloperName, Active__c FROM TriggerSetting__mdt
                                                WHERE DeveloperName = 'InventoryMovementTrigger'];
    if(triggerSetting.isEmpty()) return;
    if(triggerSetting[0].Active__c == TRUE){
        
        if(Trigger.isBefore){
            if(Trigger.isDelete){
                
            }
        }else if(Trigger.isAfter){
            
            if(Trigger.isInsert){
                
                InventoryMovementTriggerHandler.onAfterInsert(Trigger.Old, Trigger.New, Trigger.NewMap);
                
            }else if(Trigger.isUpdate){
                
                InventoryMovementTriggerHandler.onAfterUpdate(Trigger.Old, Trigger.New);
                
            }else if(Trigger.isDelete){
                
                InventoryMovementTriggerHandler.onAfterDelete(Trigger.Old);
                
            }
        }
    }
}