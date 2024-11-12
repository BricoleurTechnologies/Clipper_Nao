trigger LocationProductTrigger on Location_Product__c (after insert, after update) {
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {

        }
        else if(Trigger.isUpdate) {

            Set<Id> productIdSet = new Set<Id>();
            Set<Id> locationIdSet =  new Set<Id>();

            for(Location_Product__c locProd : Trigger.new) {
                if(locProd.Total_Sales_Orders__c != Trigger.oldMap.get(locProd.Id).Total_Sales_Orders__c) {
                    productIdSet.add(locProd.Product__c);
                    locationIdSet.add(locProd.Location__c);
                }
            }

            if(!productIdSet.isEmpty() && !locationIdSet.isEmpty()) {
                InventoryMovementTriggerHandler.calculateProductTotals(productIdSet, locationIdSet);
            }
        }
    }
}