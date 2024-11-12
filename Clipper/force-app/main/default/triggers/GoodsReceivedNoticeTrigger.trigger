trigger GoodsReceivedNoticeTrigger on Goods_Received_Notice_bric__c (before insert, before update, after insert, after update, before delete, after delete)  {

    List<TriggerSetting__mdt> triggerSetting = [SELECT Id, DeveloperName, Active__c FROM TriggerSetting__mdt
                                                WHERE DeveloperName = 'GoodsReceivedNoticeTrigger'];
    if(triggerSetting.isEmpty()) return;
    if(triggerSetting[0].Active__c == TRUE){
        
        if(Trigger.isBefore){
            if(Trigger.isDelete){
                
            }
        }else if(Trigger.isAfter){
            
            if(Trigger.isInsert){
                
                List<Goods_Received_Notice_bric__c> grnToProcess = new List<Goods_Received_Notice_bric__c>();
                for(Goods_Received_Notice_bric__c grn : Trigger.New){
                    if(grn.Status__c == 'Completed'){
                        grnToProcess.add(grn);
                    }
                }
                
                if(grnToProcess.size() > 0){
                   GoodsReceivedNoticeTriggerHandler.onAfterInsert(grnToProcess);
                }
                
            }else if(Trigger.isUpdate){
                List<Goods_Received_Notice_bric__c> grnToProcess = new List<Goods_Received_Notice_bric__c>();
                for(Goods_Received_Notice_bric__c grn : Trigger.New){
                    if(grn.Status__c == 'Completed' && grn.Status__c != Trigger.OldMap.get(grn.Id).Status__c){
                        grnToProcess.add(grn);
                    }
                }
                
                if(grnToProcess.size() > 0){
                    GoodsReceivedNoticeTriggerHandler.onAfterUpdate(grnToProcess);
                }
            }else if(Trigger.isDelete){
                
                
            }
        }
    }
    
}