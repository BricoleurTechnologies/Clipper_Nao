/**
 * @description Utility class for NAO classes
 * @date Aug-25-2024
 * @author [1] JP Sulit (Created)
 *         [2] JP Sulit - Aug-27-2024 - Refactored params in calcOrderProductPicked & createUpdateInventoryMovement
 */

public without sharing class NaoSettingUtil {
    
    public static final Id salesOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
    public static final Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
    public static final Id stockTransferRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(ClipperSettingUtility.getStockTransferRecordTypeDevName()).getRecordTypeId();


    /**
     * [1]
     * @description Updates location product Total_Sales_Orders__c field based on criteria 
     * @author Bricoleur Technologies (jp@bricoleurtech.com)
     * @date Aug-25-2024 
     */    
    public static void calculateTotalSalesOrders(Set<Id> orderIds, Set<Id> locIds, Set<Id> prodIds, Set<String> locProdKeys){
        
        Map<String,Location_Product__c> locationProductMap = new Map<String,Location_Product__c>();
        Map<Id,List<OrderItem>> orderOrderItemMap = new Map<Id,List<OrderItem>>();
        Map<String,Decimal> locationProductInStockMap = new Map<String,Decimal>();        
        Map<String,Decimal> locationProductSalesOrdersMap = new Map<String,Decimal>();
        List<OrderItem> salesOrderItemList = new List<OrderItem>();

        for(Location_Product__c locProd : [SELECT Id, Location__c, Product__c,Warehouse_Location__c FROM Location_Product__c
                                          WHERE Location__c IN: locIds AND Product__c IN: prodIds]){
            String key = locProd.Location__c + '-' + locProd.Product__c;
            locationProductMap.put(key,locProd);
        }
        System.debug('locationProductMap aug 27 bric '+locationProductMap);
        /*Created by: JP Sulit (jp@bricoleurtech.com)
        Created Date: Feb 13, 2024
        Description: Filters Sales Orders conditionally based on naoErpDate value
        */
        //START 
        Date naoErpDate = ClipperSettingUtility.getOrderDateSettings()?.Ignore_SO_before_Activation_Date__c;

        if(naoErpDate != null) {
            salesOrderItemList = [SELECT Id, Order.StatusCode,Order.Inventory_Location__c,Product2Id, OrderId,Location__c ,
                                        Order_Record_Type_bric__c,Order.Picked__c,Quantity_Not_Picked__c,Order.RecordTypeId
                                        FROM OrderItem
                                        WHERE Order.Inventory_Location__c IN: locIDs AND Product2Id IN: prodIDs
                                        AND Order.RecordTypeId =: salesOrderRecordTypeId
                                        AND Order.StatusCode = 'Activated'
                                        AND Order.Picked__c = FALSE
                                        AND Order.ActivatedDate >=: naoErpDate];
        }
        else {
            salesOrderItemList = [SELECT Id, Order.StatusCode,Order.Inventory_Location__c,Product2Id, OrderId,Location__c ,
                                        Order_Record_Type_bric__c,Order.Picked__c,Quantity_Not_Picked__c,Order.RecordTypeId
                                        FROM OrderItem
                                        WHERE Order.Inventory_Location__c IN: locIDs AND Product2Id IN: prodIDs
                                        AND Order.RecordTypeId =: salesOrderRecordTypeId
                                        AND Order.StatusCode = 'Activated'
                                        AND Order.Picked__c = FALSE];            
        }
        //END
        		
        for(OrderItem ordItem : salesOrderItemList){
            String key = ordItem.Order.Inventory_Location__c + '-' + ordItem.Product2Id;
            
            //Add to Sales Orders
            if(locationProductSalesOrdersMap.get(key) != null){
                locationProductSalesOrdersMap.put(key,locationProductSalesOrdersMap.get(key) + ordItem.Quantity_Not_Picked__c);
            }else{ 
                locationProductSalesOrdersMap.put(key,ordItem.Quantity_Not_Picked__c);
            }                
            
        }
        
        system.debug('locationProductSalesOrdersMap :: ' + locationProductSalesOrdersMap);
        List<Location_Product__c> locProdToUpdateList = new  List<Location_Product__c>();
        for(String locProdKey : locProdKeys){
            Location_Product__c locProd = new Location_Product__c();
            System.debug('locProdKey aug 27 bric '+locProdKey);
            locProd.Id = locationProductMap.get(locProdKey)?.Id;
            String[] locProdString = locProdKey.split('-'); 
            locProd.Location__c = locProdString[0];
            locProd.Product__c = locProdString[1];
            locProd.Total_Sales_Orders__c = locationProductSalesOrdersMap.get(locProdKey) != null ?
                locationProductSalesOrdersMap.get(locProdKey) : 0;
            locProdToUpdateList.add(locProd);            
        }
        try {
		    Database.upsert(locProdToUpdateList);   
        }
        catch(Exception e) {
            Utilities.CreateExceptionLog(e, 'OrderTriggerHandler: calculateTotalSalesOrders Location_Product__c update');
        }
        
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        for(OrderItem orderItem : [SELECT OrderId, Id, Product2Id, Order.Inventory_Location__c,Location__c FROM OrderItem WHERE OrderId IN: orderIds]){
            Id locId = orderItem.Location__c;
            if(locId == NULL) locId = orderItem.Order.Inventory_Location__c;
            String key = locId +'-' + orderItem.Product2Id;
            
            orderItem.Warehouse_Location__c = locationProductMap.get(key)?.Warehouse_Location__c;
            orderItem.Location__c = locationProductMap.get(key)?.Location__c;
            orderItemsToUpdate.add(orderItem);
        }
        if(orderItemsToUpdate.size() > 0){
            try {
                Database.update(orderItemsToUpdate);
            }
            catch(Exception e) {
                Utilities.CreateExceptionLog(e, 'OrderTriggerHandler: calculateTotalSalesOrders OrderItem update');
            }
        }
    }

    /**
     * [1]
     * @description Recalculates OrderItem.Picked__c field
     * @date Aug-25-2024 
     * @author [1] JP Sulit (Created) 
     * [2] JP Sulit - Aug-27-2024 - Changed Map<Id, Decimal> orderItemQtyMap param to Map<Id, Order_Pick_Line__c> orderPickLineMap
     */
    public static void calcOrderProductPicked(Map<Id, Order_Pick_Line__c> orderPickLineMap) {
        
        List<OrderItem> oiToUpdate = new List<OrderItem>();

        for(OrderItem ordItem : [SELECT Id, Picked__c FROM OrderItem
                                WHERE Id IN : orderPickLineMap.keySet()]) {
            if(!orderPickLineMap.isEmpty() && orderPickLineMap.containsKey(ordItem.Id)) {
                if(ordItem.Picked__c != null) {
                    ordItem.Picked__c += orderPickLineMap.get(ordItem.Id)?.Picked_Quantity__c;
                }
                else {
                    ordItem.Picked__c = orderPickLineMap.get(ordItem.Id)?.Picked_Quantity__c;
                }
                oiToUpdate.add(ordItem);
            }    
        }

        if(!oiToUpdate.isEmpty()) {
            update oiToUpdate;
        }
    }

    /**
     * [1]
     * @description Upserts Inventory Movement record based on Order Item values
     * @date Aug-25-2024 
     * @author [1] JP Sulit (Created) 
     * [2] JP Sulit - Aug-27-2024 - Changed Map<Id, Decimal> orderItemQtyMap param to Map<Id, Order_Pick_Line__c> orderPickLineMap
     * [2] JP Sulit - Aug-27-2024 - Added logic to populate inv.Order_Pick_Line__c
     */
    //START 
    public static void createUpdateInventoryMovement(Map<Id, Order_Pick_Line__c> orderPickLineMap) {
                
        List<Inventory_Movement__c> invMovementList = [SELECT Id, As_At__c,Order__c,Order_Product__c,Movement__c,
                                                       Product__c,Location__c,Order_Pick_Line__c FROM Inventory_Movement__c
                                                       WHERE Order_Product__c IN: orderPickLineMap.keySet()
                                                       AND Order_Product__c != NULL];
        
        Map<Id,Inventory_Movement__c> invMovementToOrderProductMap = new  Map<Id,Inventory_Movement__c>();
        
        for(Inventory_Movement__c invMov : invMovementList){
            invMovementToOrderProductMap.put(invMov.Order_Product__c,invMov);
        }
        
        List<Inventory_Movement__c> invMovementListToUpsert = new List<Inventory_Movement__c>();

        for(OrderItem ordItem : [SELECT Id, 
                                        Order.Inventory_Location__c,
                                        Product2Id, 
                                        OrderId,Location__c,
                                        Quantity,
                                        Order.RecordTypeId,
                                        Received__c,
                                        Product2.RecordType.DeveloperName
                                        FROM OrderItem
                                        WHERE Id IN : orderPickLineMap.keySet()
                                        AND Product2.Inventory_Status__c != 'Non-Stock Item']) {

            Inventory_Movement__c inv = new Inventory_Movement__c();
            inv.Id = invMovementToOrderProductMap.get(ordItem.Id)?.Id;
            inv.As_At__c = DateTime.now();
            Id locId = NULL;
            if(ordItem.Order.RecordTypeId == salesOrderRecordTypeId && ordItem.Location__c != NULL) locId = ordItem.Location__c;
            else locId = ordItem.Order.Inventory_Location__c;
            inv.Location__c = locId;
            Decimal movementTotal = 0;
            if(ordItem.Order.RecordTypeId == salesOrderRecordTypeId || ordItem.Order.RecordTypeId == stockTransferRecordTypeId){
                Decimal oiQty = !orderPickLineMap.isEmpty() && orderPickLineMap.containsKey(ordItem.Id) ? orderPickLineMap.get(ordItem.Id).Picked_Quantity__c : ordItem.Quantity;
                movementTotal = oiQty * -1;
                inv.Movement__c = movementTotal;
                inv.Order__c = ordItem.OrderId;
                inv.Order_Product__c = ordItem.Id;
                inv.Product__c = ordItem.Product2Id;
                inv.Order_Pick_Line__c = !orderPickLineMap.isEmpty() && orderPickLineMap.containsKey(ordItem.Id) ? orderPickLineMap.get(ordItem.Id).Id : null;
                invMovementListToUpsert.add(inv);
            }            
        }

        if(invMovementListToUpsert.size() > 0) {
            try {
                Database.upsert(invMovementListToUpsert,false);
            }
            catch(Exception e) {
                Utilities.CreateExceptionLog(e, 'OrderTriggerHandler: createUpdateInventoryMovement Inventory_Movement__c upsert');
            }
        }   
    }
}