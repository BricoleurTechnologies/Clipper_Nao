/**
* @description Trigger for Order object
* @author Bricoleur Technologies
* [1] JP Sulit - Aug-27-2024 - Commented out exec logic of createUpdateInventoryMovement2 & reverted back logic to exec createUpdateInventoryMovement
*/
trigger OrderTrigger on Order (before insert, before update, after insert, after update, before delete, after delete) {
    
    public static final Id salesOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order')?.getRecordTypeId();
    public static final Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order')?.getRecordTypeId();
    public static final Id stockTransferRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(ClipperSettingUtility.getStockTransferRecordTypeDevName()).getRecordTypeId();
    
    
    List<TriggerSetting__mdt> triggerSetting = [SELECT Id, DeveloperName, Active__c FROM TriggerSetting__mdt
                                                WHERE DeveloperName = 'OrderTrigger'];
    if(triggerSetting.isEmpty()) return;
    if(triggerSetting[0].Active__c == TRUE){
        
        if(Trigger.isBefore){
            if(Trigger.isDelete){
                
            }
            //Nagendra - CT-14 STARTS
            if(Trigger.isInsert || Trigger.isUpdate){
                // Map to store Orders that require `Next_Recurring_Order_Date__c` calculation
                Map<Id, Order> ordersToProcess = new Map<Id, Order>();
                Id salesOrderTemplateRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order_Template')?.getRecordTypeId();
                Boolean isSalesOrderTemplate = false;
                // Gather orders that meet the criteria for calculating Next Recurring Order Date
                for (Order ord : Trigger.new) {
                   if(ord.RecordTypeId == salesOrderTemplateRecordTypeId) isSalesOrderTemplate = true;
                    Boolean isRecurringOrder = ord.Recurring__c == true;
                    Boolean isNewRecord = Trigger.isInsert;
                    
                    // Check if order meets insert criteria
                    Boolean meetsInsertCriteria = isNewRecord && isSalesOrderTemplate && isRecurringOrder;
                    
                    // Check if any relevant fields have changed for update criteria
                    Boolean isUpdatedRecurringFields = isSalesOrderTemplate && Trigger.isUpdate && (
                        ord.Recurring__c != Trigger.oldMap.get(ord.Id).Recurring__c ||
                        ord.Snooze_Order__c != Trigger.oldMap.get(ord.Id).Snooze_Order__c ||
                        ord.Snooze_Start_Date__c != Trigger.oldMap.get(ord.Id).Snooze_Start_Date__c ||
                        ord.Snooze_End_Date__c != Trigger.oldMap.get(ord.Id).Snooze_End_Date__c
                    );
                    
                    // Add order to processing map if it meets criteria
                    if (meetsInsertCriteria || isUpdatedRecurringFields) {
                        ordersToProcess.put(ord.Id, ord);
                    }
                }
                
                // Process orders in bulk using the helper method
                if (!ordersToProcess.isEmpty()) {
                    Map<Id, Date> nextOccurrenceDates = OrderTriggerHandler.getNextOrderDates(new List<Order>(ordersToProcess.values()));
                    
                    // Update the Next_Recurring_Order_Date__c field based on calculated values
                    for (Order ord : Trigger.new) {
                        if (nextOccurrenceDates.containsKey(ord.Id)) {
                            ord.Next_Recurring_Order_Date__c = nextOccurrenceDates.get(ord.Id);
                        }
                    }
                }
            }
            //CT-14 ENDS
        }else if(Trigger.isAfter){
            
            if(Trigger.isInsert){
                
                //When an order with record type = Purchase Order is created, copy the Account Supplier Pricebook to the Order.
                List<Order> ordersToProcess = new List<Order>();
                for(Order ord : Trigger.New){
                    if(ord.RecordTypeId == purchaseOrderRecordTypeId){
                        ordersToProcess.add(ord);
                    }
                }
                if(ordersToProcess.size() > 0){
                    OrderTriggerHandler.setOrderAccountSupplierPricebook(ordersToProcess);
                }
                
            }else if(Trigger.isUpdate){
                
                List<Order> ordersToProcess = new List<Order>();
                Set<Id> locationIds = new Set<Id>();
                Set<Id> prodIds = new Set<Id>();
                Set<Id> salesOrderIds = new Set<Id>();
                Set<Id> purchaseOrderIds = new Set<Id>();
                Set<String> locProdKeys = new Set<String>();
                Set<Order> ordersForInventoryMovement = new Set<Order>();
                
                Map<Id, Order> purchaseOrderNewMap = new Map<Id, Order>();
                /**
* @description Used to update non stock item sales orders 
* @author Bricoleur Technologies (jp@bricoleurtech.com)
* @date July-02-2024
*/
                //START
                Set<Id> orderItemIdSet = new Set<Id>();
                //END
                
                for(Order ord : Trigger.New){
                    system.debug(ord.StatusCode);
                    system.debug(ord.RecordTypeId);
                    
                    if(ord.RecordTypeId == salesOrderRecordTypeId){
                        
                        if(ord.StatusCode != Trigger.OldMap.get(ord.Id).StatusCode
                           && ord.StatusCode == 'Activated'){
                               //locationIds.add(ord.Inventory_Location__c);
                               salesOrderIds.add(ord.Id);
                           }
                        if(ord.Picked__c != Trigger.OldMap.get(ord.Id).Picked__c
                           && ord.Picked__c == TRUE){
                               //locationIds.add(ord.Inventory_Location__c);
                               salesOrderIds.add(ord.Id);
                               ordersForInventoryMovement.add(ord);
                           }
                        
                    }else if(ord.RecordTypeId == purchaseOrderRecordTypeId){
                        
                        if((ord.StatusCode != Trigger.OldMap.get(ord.Id).StatusCode && ord.StatusCode == 'Activated') 
                           || (ord.Completed__c != Trigger.OldMap.get(ord.Id).Completed__c && ord.Completed__c == true)){                            
                               locationIds.add(ord.Inventory_Location__c);
                               purchaseOrderIds.add(ord.Id);
                           }
                        
                    }else if(ord.RecordTypeId == stockTransferRecordTypeId){
                        
                        if(ord.Picked__c != Trigger.OldMap.get(ord.Id).Picked__c
                           && ord.Picked__c == TRUE){
                               locationIds.add(ord.Inventory_Location__c);
                               ordersForInventoryMovement.add(ord);                                  
                           }
                    }
                }
                
                if(salesOrderIds.size() > 0){
                    for(OrderItem ordItem : [SELECT Id,
                                             Product2Id,
                                             OrderId,
                                             Order.Inventory_Location__c,
                                             Product2.Inventory_Status__c, 
                                             Location__c FROM OrderItem
                                             WHERE OrderId IN: salesOrderIds
                                             AND Product2.Inventory_Status__c != 'Non-Stock Item']) {
                                                 
                                                 prodIds.add(ordItem.Product2Id);     
                                                 if(ordItem.Location__c != NULL){
                                                     locationIds.add(ordItem.Location__c);
                                                     locProdKeys.add(ordItem.Location__c+ '-' +ordItem.Product2Id);
                                                 }else{
                                                     locationIds.add(ordItem.Order.Inventory_Location__c);
                                                     locProdKeys.add(ordItem.Order.Inventory_Location__c+ '-' +ordItem.Product2Id);
                                                 }
                                                 /**
* @description Used to update non stock item sales orders 
* @author Bricoleur Technologies (jp@bricoleurtech.com)
* @date July-02-2024
*/
                                                 //START
                                                 orderItemIdSet.add(ordItem.Id);
                                                 //END
                                             }
                    OrderTriggerHandler.calculateTotalSalesOrders(salesOrderIds,locationIds, prodIds, locProdKeys);
                }
                
                if(purchaseOrderIds.size() > 0){
                    /*for(OrderItem ordItem : [SELECT Id,
Product2Id,
OrderId,
Order.Inventory_Location__c,
Product2.Inventory_Status__c 
FROM OrderItem
WHERE OrderId IN: purchaseOrderIds
AND Product2.Inventory_Status__c != 'Non-Stock Item']){
prodIds.add(ordItem.Product2Id);
locProdKeys.add(ordItem.Order.Inventory_Location__c+ '-' +ordItem.Product2Id);
}
system.debug('locProdKeys bric  '+locProdKeys);
OrderTriggerHandler.calculateTotalPurchaseOrders(purchaseOrderIds,locationIds, prodIds, locProdKeys);*/
                    
                    /*Created by: JP Sulit (jp@bricoleurtech.com)
Created Date: Feb 9, 2024
Description: Gets total purchase order sum from Order Products and GRN Lines
*/
                    //START 
                    Map<Id, Set<String>> completedOrderProductsMap = ClipperSettingUtility.getCompletedOrderProducts(purchaseOrderIds);
                    ClipperSettingUtility.calcTotalPurchaseOrders(completedOrderProductsMap);
                    //END
                }
                
                System.debug('ordersForInventoryMovement '+ordersForInventoryMovement.size());
                System.debug('ordersForInventoryMovement '+ordersForInventoryMovement);
                
                if(ordersForInventoryMovement.size() > 0){
                    OrderTriggerHandler.createUpdateInventoryMovement(ordersForInventoryMovement);
                }
                
                /*if(ordersForInventoryMovement.size() > 0 && orderItemIdSet.isEmpty()){
OrderTriggerHandler.createUpdateInventoryMovement(ordersForInventoryMovement);
}
else {
OrderTriggerHandler.createUpdateInventoryMovement2(orderItemIdSet);
}*/
            }else if(Trigger.isDelete){
                
                
            }
        }
    }
}