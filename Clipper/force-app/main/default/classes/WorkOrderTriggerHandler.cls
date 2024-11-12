public class WorkOrderTriggerHandler {
    
    public static void upsertInventoryMovemement(Set<WorkOrderLineItem> woLIList){
        
        List<WorkOrderLineItem> orderItemsToProcess = [SELECT Id, WorkOrder.LocationId,Product2Id, WorkOrderId,LocationId, 
                                                       Quantity,Product2.RecordType.DeveloperName
                                                       FROM WorkOrderLineItem
                                                       WHERE Id IN: woLIList
                                                       AND Quantity != NULL
                                                       AND Product2Id != NULL]; 
        
        List<Inventory_Movement__c> invMovementList = [SELECT Id, As_At__c,Work_Order__c,Work_Order_Line_Item__c,Movement__c,
                                                       Product__c,Location__c FROM Inventory_Movement__c
                                                       WHERE Work_Order_Line_Item__c IN: orderItemsToProcess
                                                       AND Work_Order__c != NULL];
        
        Map<Id,Inventory_Movement__c> invMovementToOrderProductMap = new  Map<Id,Inventory_Movement__c>();
        
        for(Inventory_Movement__c invMov : invMovementList){
            invMovementToOrderProductMap.put(invMov.Work_Order_Line_Item__c,invMov);
        }
        
        List<Inventory_Movement__c> invMovementListToUpsert = new List<Inventory_Movement__c>();
        for(WorkOrderLineItem ordItem : orderItemsToProcess){
            Inventory_Movement__c inv = new Inventory_Movement__c();
            inv.Id = invMovementToOrderProductMap.get(ordItem.Id)?.Id;
            inv.As_At__c = DateTime.now();
            Id locId = ordItem.LocationId;
            if(locId == NULL) locId = ordItem.WorkOrder.LocationId;
            inv.Location__c = locId;
            Decimal movementTotal = 0;
            movementTotal = ordItem.Quantity * -1;
            inv.Movement__c = movementTotal;
            inv.Work_Order__c = ordItem.WorkOrderId;
            inv.Work_Order_Line_Item__c = ordItem.Id;
            inv.Product__c = ordItem.Product2Id;
            invMovementListToUpsert.add(inv);
        }
        
        if(invMovementListToUpsert.size() > 0) Database.upsert(invMovementListToUpsert,false);
        
    }
    
    /*
    public static void processLocProd(Set<Id> locIds, Set<Id> prodIds, Set<String> locProdKeys){
        
        Map<String,Location_Product__c> locationProductMap = new Map<String,Location_Product__c>();
        Map<Id,List<WorkOrderLineItem>> orderOrderItemMap = new Map<Id,List<WorkOrderLineItem>>();
        Map<String,Decimal> locationProductOrdersMap = new Map<String,Decimal>();
        
        for(Location_Product__c locProd : [SELECT Id, Location__c, Product__c,Warehouse_Location__c FROM Location_Product__c
                                           WHERE Location__c IN: locIds AND Product__c IN: prodIds]){
                                               String key = locProd.Location__c + '-' + locProd.Product__c;
                                               locationProductMap.put(key,locProd);
                                           }
        
        
        
        //Calculate Total Sales Order field
        //(total number (amount) in orders linked to that Location (order line) where the order is a sales order
        List<WorkOrderLineItem> orderItemList = [SELECT Id, WorkOrder.LocationId,Product2Id, OrderId, LocationId,
                                                 WorkOrder.Picked_bric__c,Quantity
                                                 FROM WorkOrderLineItem
                                                 WHERE WorkOrder.LocationId IN: locIDs AND Product2Id IN: prodIDs
                                                 AND WorkOrder.Picked_bric__c = FALSE];
        
        for(WorkOrderLineItem ordItem : orderItemList){
            Id locId = ordItem.LocationId;
            if(locId == NULL) locId = ordItem.WorkOrder.LocationId;
            String key = locId + '-' + ordItem.Product2Id;
            
            //Add to Sales Orders
            if(locationProductOrdersMap.get(key) != null){
                locationProductOrdersMap.put(key,locationProductOrdersMap.get(key) + ordItem.Quantity);
            }else{ 
                locationProductOrdersMap.put(key,ordItem.Quantity);
            }                
            
        }
        
        system.debug('locationProductSalesOrdersMap :: ' + locationProductOrdersMap);
        List<Location_Product__c> locProdToUpdateList = new  List<Location_Product__c>();
        for(String locProdKey : locProdKeys){
            Location_Product__c locProd = new Location_Product__c();
            locProd.Id = locationProductMap.get(locProdKey)?.Id;
            String[] locProdString = locProdKey.split('-'); 
            locProd.Location__c = locProdString[0];
            locProd.Product__c = locProdString[1];
            locProd.Total_Sales_Orders__c = locationProductOrdersMap.get(locProdKey) != null ?
                locationProductOrdersMap.get(locProdKey) : 0;
            locProdToUpdateList.add(locProd);            
        }
        Database.upsert(locProdToUpdateList);   
    }
    */
    
}