trigger OrderItemTrigger on OrderItem (before insert, before update, after insert, after update, before delete, after delete) {
    
    
    List<TriggerSetting__mdt> triggerSetting = [SELECT Id, DeveloperName, Active__c FROM TriggerSetting__mdt
                                                WHERE DeveloperName = 'OrderItemTrigger'];
    if(triggerSetting.isEmpty()) return;
    if(triggerSetting[0].Active__c == TRUE){
        
        if(Trigger.isBefore){
            if(Trigger.isDelete){
                
            }
        }else if(Trigger.isAfter){
            
            if(Trigger.isInsert){
                
                OrderItemTriggerHandler.onAfterInsert(Trigger.Old, Trigger.New, Trigger.NewMap);
                
            }else if(Trigger.isUpdate){
                
                OrderItemTriggerHandler.onAfterUpdate(Trigger.Old, Trigger.New);
                
            }else if(Trigger.isDelete){
                
                OrderItemTriggerHandler.onAfterDelete(Trigger.Old);
                
            }
        }
    }
}