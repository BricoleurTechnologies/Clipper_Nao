trigger WorkOrderTrigger on WorkOrder (before insert, before update, after insert, after update, before delete, after delete) {
    
    List<TriggerSetting__mdt> triggerSetting = [SELECT Id, DeveloperName, Active__c FROM TriggerSetting__mdt
                                                WHERE DeveloperName = 'WorkOrderTrigger'];
    if(triggerSetting.isEmpty()) return;
    if(triggerSetting[0].Active__c == TRUE){
        
        if(Trigger.isUpdate){
            
            List<WorkOrder> ordersToProcess = new List<WorkOrder>();
            Set<Id> locationIds = new Set<Id>();
            Set<Id> prodIds = new Set<Id>();
            Set<Id> woIds = new Set<Id>();
            Set<String> locProdKeys = new Set<String>();
            Set<WorkOrderLineItem> woLIForInventoryMovement = new Set<WorkOrderLineItem>();
            
            for(WorkOrder wo : Trigger.New){
                
                if(wo.Picked_bric__c != Trigger.OldMap.get(wo.Id).Picked_bric__c
                   && wo.Picked_bric__c == TRUE){
                       woIds.add(wo.Id);
                   }
            }
            
            if(woIds.size() > 0){
                for(WorkOrderLineItem wordItem : [SELECT Id,Product2Id,WorkOrderId,WorkOrder.LocationId,LocationId,
                                                  Product2.Inventory_Status__c FROM WorkOrderLineItem
                                                  WHERE WorkOrderId IN: woIds
                                                  AND Product2.Inventory_Status__c != 'Non-Stock Item']){
                                                      /*prodIds.add(wordItem.Product2Id);
                                                      if(wordItem.LocationId != NULL){
                                                          locationIds.add(wordItem.LocationId);
                                                          locProdKeys.add(wordItem.LocationId+ '-' +wordItem.Product2Id);
                                                      }else{
                                                          locationIds.add(wordItem.WorkOrder.LocationId);
                                                          locProdKeys.add(wordItem.WorkOrder.LocationId+ '-' +wordItem.Product2Id);
                                                      }*/
                                                      woLIForInventoryMovement.add(wordItem);                                                  
                                                  }
                //WorkOrderTriggerHandler.processLocProd(locationIds, prodIds, locProdKeys);
            }
            
            if(woLIForInventoryMovement.size() > 0){
                WorkOrderTriggerHandler.upsertInventoryMovemement(woLIForInventoryMovement);
            }
        }
    }
}