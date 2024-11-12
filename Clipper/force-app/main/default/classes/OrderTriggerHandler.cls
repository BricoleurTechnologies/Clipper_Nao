public without sharing class OrderTriggerHandler {
    
    public static final Id salesOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
    public static final Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
    public static final Id stockTransferRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(ClipperSettingUtility.getStockTransferRecordTypeDevName()).getRecordTypeId();
    
    /*public static void onAfterInsert(List<Order> priorOrders, List<Order> newOrders, Map<Id,Order> newMapOrders){     

//createUpdateInventoryMovement(newOrders);
//calculateAmounts(newOrders);
}

public static void onAfterUpdate(List<Order> newOrders){          

//createUpdateInventoryMovement(newOrders);
//calculateAmounts(newOrders);
}

public static void onAfterDelete(List<Order> priorOrders){

//calculateAmounts(priorOrders);
}*/
    
    public static void setOrderAccountSupplierPricebook(List<Order> orderList){
        List<Order> orderListToProcess = [SELECT Id, AccountId, Account.Supplier_Pricebook__c FROM Order
                                          WHERE Id IN: orderList];
        for(Order ord : orderListToProcess){
            ord.Pricebook2Id = ord.Account.Supplier_Pricebook__c;
        }
        try {
            Database.update(orderListToProcess);
        }
        catch(Exception e) {
            Utilities.CreateExceptionLog(e, 'OrderTriggerHandler: setOrderAccountSupplierPricebook');
        }
    }
    
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
        
        //Calculate Total Sales Order field
        //(total number (amount) in orders linked to that Location (order line) where the order is a sales order
        /*List<OrderItem> salesOrderItemList = [SELECT Id, Order.StatusCode,Order.Inventory_Location__c,Product2Id, OrderId,Location__c ,
Order_Record_Type_bric__c,Order.Picked__c,Quantity,Order.RecordTypeId
FROM OrderItem
WHERE Order.Inventory_Location__c IN: locIDs AND Product2Id IN: prodIDs
AND Order.RecordTypeId =: salesOrderRecordTypeId
AND Order.StatusCode = 'Activated'
AND Order.Picked__c = FALSE];*/
        
        /*Created by: JP Sulit (jp@bricoleurtech.com)
Created Date: Feb 13, 2024
Description: Filters Sales Orders conditionally based on naoErpDate value
*/
        //START 
        Date naoErpDate = ClipperSettingUtility.getOrderDateSettings()?.Ignore_SO_before_Activation_Date__c;
        
        if(naoErpDate != null) {
            salesOrderItemList = [SELECT Id, Order.StatusCode,Order.Inventory_Location__c,Product2Id, OrderId,Location__c ,
                                  Order_Record_Type_bric__c,Order.Picked__c,Quantity,Order.RecordTypeId
                                  FROM OrderItem
                                  WHERE Order.Inventory_Location__c IN: locIDs AND Product2Id IN: prodIDs
                                  AND Order.RecordTypeId =: salesOrderRecordTypeId
                                  AND Order.StatusCode = 'Activated'
                                  AND Order.Picked__c = FALSE
                                  AND Order.ActivatedDate >=: naoErpDate];
        }
        else {
            salesOrderItemList = [SELECT Id, Order.StatusCode,Order.Inventory_Location__c,Product2Id, OrderId,Location__c ,
                                  Order_Record_Type_bric__c,Order.Picked__c,Quantity,Order.RecordTypeId
                                  FROM OrderItem
                                  WHERE Order.Inventory_Location__c IN: locIDs AND Product2Id IN: prodIDs
                                  AND Order.RecordTypeId =: salesOrderRecordTypeId
                                  AND Order.StatusCode = 'Activated'
                                  AND Order.Picked__c = FALSE];            
        }
        //END
        
        System.debug('salesOrderItemList aug 30 '+salesOrderItemList);
        
        for(OrderItem ordItem : salesOrderItemList){
            String key = ordItem.Order.Inventory_Location__c + '-' + ordItem.Product2Id;
            System.debug('key aug 30 '+key);
            System.debug(' ordItem.Quantity aug 30 '+ ordItem.Quantity);
            //Add to Sales Orders
            if(locationProductSalesOrdersMap.containsKey(key) && locationProductSalesOrdersMap.get(key) != null){
                System.debug('locationProductSalesOrdersMap.get(key) aug 30 '+locationProductSalesOrdersMap.get(key));
                Decimal test = locationProductSalesOrdersMap.get(key) + ordItem.Quantity;
                System.debug('add aug 30 '+test);
                locationProductSalesOrdersMap.put(key,locationProductSalesOrdersMap.get(key) + ordItem.Quantity);
            }else{ 
                System.debug('key1 aug 30 '+key);
                locationProductSalesOrdersMap.put(key,ordItem.Quantity);
                System.debug('locationProductSalesOrdersMap.get(key)1 aug 30 '+locationProductSalesOrdersMap.get(key));
            }                
            
        }
        
        system.debug('locationProductSalesOrdersMap :: ' + locationProductSalesOrdersMap);
        List<Location_Product__c> locProdToUpdateList = new  List<Location_Product__c>();
        for(String locProdKey : locProdKeys){
            Location_Product__c locProd = new Location_Product__c();
            locProd.Id = locationProductMap.get(locProdKey)?.Id;
            String[] locProdString = locProdKey.split('-'); 
            locProd.Location__c = locProdString[0];
            locProd.Product__c = locProdString[1];
            System.debug('locProdKey aug 30 '+locProdKey);
            System.debug('locationProductSalesOrdersMap.get(locProdKey) aug 30 '+locationProductSalesOrdersMap.get(locProdKey));
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
    
    /*public static void calculateTotalPurchaseOrders(Set<Id> orderIds, Set<Id> locIds, Set<Id> prodIds, Set<String> locProdKeys){

Map<String,Location_Product__c> locationProductMap = new Map<String,Location_Product__c>();
Map<Id,List<OrderItem>> orderOrderItemMap = new Map<Id,List<OrderItem>>();        
Map<String,Decimal> locationProductPurchaseOrdersMap = new Map<String,Decimal>(); 
Map<String,Set<Id>> locationProductPurchaseOrderIDsMap = new Map<String,Set<Id>>();        
Set<Id> standardProdSet = new Set<Id>();  

//Calculate Total Purchase Order field
//(total number (amount) in orders linked to that Location (order line) where the order is a purchase order
List<OrderItem> purchaseOrderItemList = [SELECT Id, Order.StatusCode,Order.Inventory_Location__c,Product2Id, OrderId, 
Order_Record_Type_bric__c,Order.Received_in_Full__c,Quantity,Order.RecordTypeId,
Order.Referred_to_Purchasing__c
FROM OrderItem
WHERE Order.Inventory_Location__c IN: locIDs AND Product2Id IN: prodIDs
AND Order.RecordTypeId =: purchaseOrderRecordTypeId
AND Order.StatusCode = 'Activated'
AND Order.Referred_to_Purchasing__c = FALSE
AND Order.Received_in_Full__c = FALSE
];

List<Product2> standardProductList = [SELECT Id, Name, Conversion_Factor__c, Supplier_Product__c
FROM Product2 
WHERE RecordType.DeveloperName = 'Standard' 
AND Supplier_Product__c != NULL];


List<Product_Suppliers_bric__c> productSupplierList = [SELECT Id, Supplier_Product_bric__c,Product_bric__c
FROM Product_Suppliers_bric__c 
WHERE Supplier_Product_bric__c != NULL
AND Product_bric__c != NULL];

Map<Id,Product2> supplierTostandardProduct = new Map<Id,Product2>();
Map<Id,Product2> standardProdMap = new Map<Id,Product2>();

for(Product2 stdProd : standardProductList){
standardProdMap.put(stdProd.Id, stdProd);
supplierTostandardProduct.put(stdProd.Supplier_Product__c,stdProd);
}

if(productSupplierList.size() > 0){
for(Product_Suppliers_bric__c prodSup : productSupplierList){
if(supplierTostandardProduct.get(prodSup.Supplier_Product_bric__c) == NULL) supplierTostandardProduct.put(prodSup.Supplier_Product_bric__c,standardProdMap.get(prodSup.Product_bric__c));
}
}

List<String> standardProdsToProcess = new List<String>();
for(OrderItem ordItem : purchaseOrderItemList){
String key = ordItem.Order.Inventory_Location__c + '-' ;
if(standardProdMap.get(ordItem.Product2Id) != null) key += ordItem.Product2Id;
else key += supplierTostandardProduct.get(ordItem.Product2Id)?.Id;            

standardProdsToProcess.add(supplierTostandardProduct.get(ordItem.Product2Id)?.Id);

//Add to Purchase Orders
if(locationProductPurchaseOrdersMap.get(key) != null){
locationProductPurchaseOrdersMap.put(key,locationProductPurchaseOrdersMap.get(key) + ordItem.Quantity);
}else{ 
locationProductPurchaseOrdersMap.put(key,ordItem.Quantity);
}   
}
for(Location_Product__c locProd : [SELECT Id, Location__c, Product__c,Warehouse_Location__c FROM Location_Product__c
WHERE Location__c IN: locIds AND Product__c IN: standardProdsToProcess]){

String key = locProd.Location__c + '-' + locProd.Product__c;
locationProductMap.put(key,locProd);
}

List<Location_Product__c> locProdToUpdateList = new  List<Location_Product__c>();
List<String> locProdStringStandardProduct = new List<String>();        
for(String locProdKey : locProdKeys){
String[] locProdKeyStandard = locProdKey.split('-'); 
String locProdKeySupplier = locProdKeyStandard[0]+'-';
if(standardProdMap.get(locProdKeyStandard[1]) != null) locProdKeySupplier += locProdKeyStandard[1];
else locProdKeySupplier += supplierTostandardProduct.get(locProdKeyStandard[1])?.Id; 

if(locProdKeyStandard[1] != null && supplierTostandardProduct.get(locProdKeyStandard[1]) != null) locProdStringStandardProduct.add(locProdKeySupplier);
}

for(String locProdKey : locProdStringStandardProduct){
Location_Product__c locProd = new Location_Product__c();
locProd.Id = locationProductMap.get(locProdKey)?.Id;
String[] locProdString = locProdKey.split('-'); 
locProd.Location__c = locProdString[0];
locProd.Product__c = locProdString[1];
locProd.Total_Purchase_Orders__c = locationProductPurchaseOrdersMap.get(locProdKey) != null ?
locationProductPurchaseOrdersMap.get(locProdKey) : 0;
locProdToUpdateList.add(locProd);   
standardProdSet.add(locProdString[1]);			
}
map<id,Location_Product__c> locProdMapForUpdate = new map<id,Location_Product__c>();        
//put all the values from the list to map. 
locProdMapForUpdate.putall(locProdToUpdateList);
if(locProdMapForUpdate.size()>0){       
try {     
Database.upsert(locProdMapForUpdate.values());   
}
catch(Exception e) {
Utilities.CreateExceptionLog(e, 'OrderTriggerHandler: calculateTotalPurchaseOrders Location_Product__c update');
}
}

calculateProductTotalPO(standardProdSet);
}*/
    
    /*Created by: JP Sulit (jp@bricoleurtech.com)
Created Date: Feb 15, 2024
*/
    public static void upsertInvMovementRetrospective(List<Order> orderList) {
        
        List<OrderItem> orderItemsToProcess = [SELECT Id, Order.Inventory_Location__c,Product2Id, OrderId,Location__c,
                                               Quantity,Order.RecordTypeId,Received__c,Product2.RecordType.DeveloperName,
                                               Order.ActivatedDate
                                               FROM OrderItem
                                               WHERE OrderId IN: orderList]; 
        
        System.debug('upsertInvMovementRetrospective orderItemsToProcess '+orderItemsToProcess);
        
        List<Inventory_Movement__c> invMovementList = [SELECT Id, As_At__c,Order__c,Order_Product__c,Movement__c,
                                                       Product__c,Location__c,Notes__c FROM Inventory_Movement__c
                                                       WHERE Order_Product__c IN: orderItemsToProcess
                                                       AND Order_Product__c != NULL];
        
        System.debug('upsertInvMovementRetrospective invMovementList '+invMovementList);
        
        Map<Id,Inventory_Movement__c> invMovementToOrderProductMap = new  Map<Id,Inventory_Movement__c>();
        
        for(Inventory_Movement__c invMov : invMovementList){
            invMovementToOrderProductMap.put(invMov.Order_Product__c,invMov);
        }
        
        System.debug('upsertInvMovementRetrospective invMovementToOrderProductMap '+invMovementToOrderProductMap);
        
        List<Inventory_Movement__c> invMovementListToUpsert = new List<Inventory_Movement__c>();
        for(OrderItem ordItem : orderItemsToProcess){
            Inventory_Movement__c inv = new Inventory_Movement__c();
            inv.Id = invMovementToOrderProductMap.get(ordItem.Id)?.Id;
            //inv.As_At__c = DateTime.now();
            inv.As_At__c = ordItem.Order.ActivatedDate;
            inv.Notes__c = 'Manually inserted '+Date.today();
            Id locId = NULL;
            if(ordItem.Order.RecordTypeId == salesOrderRecordTypeId && ordItem.Location__c != NULL) locId = ordItem.Location__c;
            else locId = ordItem.Order.Inventory_Location__c;
            System.debug('upsertInvMovementRetrospective locId '+locId);
            inv.Location__c = locId;
            Decimal movementTotal = 0;
            if(ordItem.Order.RecordTypeId == salesOrderRecordTypeId || ordItem.Order.RecordTypeId == stockTransferRecordTypeId){
                movementTotal = ordItem.Quantity * -1;
                inv.Movement__c = movementTotal;
                inv.Order__c = ordItem.OrderId;
                inv.Order_Product__c = ordItem.Id;
                inv.Product__c = ordItem.Product2Id;
                System.debug('upsertInvMovementRetrospective inv '+inv);
                invMovementListToUpsert.add(inv);
            }            
        }
        
        System.debug('upsertInvMovementRetrospective invMovementListToUpsert '+invMovementListToUpsert);
        
        if(invMovementListToUpsert.size() > 0) {
            try {
                Database.upsert(invMovementListToUpsert,false);
            }
            catch(Exception e) {
                Utilities.CreateExceptionLog(e, 'OrderTriggerHandler: createUpdateInventoryMovement Inventory_Movement__c upsert');
            }
        }
    }
    
    public static void createUpdateInventoryMovement(Set<Order> orderList){
        
        List<OrderItem> orderItemsToProcess = [SELECT Id, Order.Inventory_Location__c,Product2Id, OrderId,Location__c,
                                               Quantity,Order.RecordTypeId,Received__c,Product2.RecordType.DeveloperName
                                               FROM OrderItem
                                               WHERE OrderId IN: orderList]; 
        
        List<Inventory_Movement__c> invMovementList = [SELECT Id, As_At__c,Order__c,Order_Product__c,Movement__c,
                                                       Product__c,Location__c FROM Inventory_Movement__c
                                                       WHERE Order_Product__c IN: orderItemsToProcess
                                                       AND Order_Product__c != NULL];
        
        Map<Id,Inventory_Movement__c> invMovementToOrderProductMap = new  Map<Id,Inventory_Movement__c>();
        
        for(Inventory_Movement__c invMov : invMovementList){
            invMovementToOrderProductMap.put(invMov.Order_Product__c,invMov);
        }
        
        List<Inventory_Movement__c> invMovementListToUpsert = new List<Inventory_Movement__c>();
        for(OrderItem ordItem : orderItemsToProcess){
            Inventory_Movement__c inv = new Inventory_Movement__c();
            inv.Id = invMovementToOrderProductMap.get(ordItem.Id)?.Id;
            inv.As_At__c = DateTime.now();
            Id locId = NULL;
            if(ordItem.Order.RecordTypeId == salesOrderRecordTypeId && ordItem.Location__c != NULL) locId = ordItem.Location__c;
            else locId = ordItem.Order.Inventory_Location__c;
            inv.Location__c = locId;
            Decimal movementTotal = 0;
            if(ordItem.Order.RecordTypeId == salesOrderRecordTypeId || ordItem.Order.RecordTypeId == stockTransferRecordTypeId){
                movementTotal = ordItem.Quantity * -1;
                inv.Movement__c = movementTotal;
                inv.Order__c = ordItem.OrderId;
                inv.Order_Product__c = ordItem.Id;
                inv.Product__c = ordItem.Product2Id;
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
    
    
    public static void calculateProductTotalPO(Set<ID> productIds) {
        
        List<Product2> productList = [SELECT Id,Weighted_Average_Cost__c,Total_Stock__c FROM Product2 WHERE Id IN :productIds];
        List<AggregateResult> totalPOByProduct = [SELECT Product__c prod, sum(Total_Purchase_Orders__c)totalPO
                                                  FROM Location_Product__c
                                                  WHERE Product__c IN :productIds
                                                  GROUP BY Product__c];        
        
        Map<String,Decimal> sumByProductMap = new Map<String,Decimal>();
        
        for(AggregateResult stock : totalPOByProduct){
            
            String prodId = '';
            if(stock.get('prod') != null) prodId = (String)stock.get('prod');
            
            Decimal poTotal = 0;
            if(stock.get('totalPO') != null && stock.get('totalPO') != '') poTotal = (Decimal)stock.get('totalPO');                        
            sumByProductMap.put(prodId, poTotal);
        }
        
        for(Product2 prod : productList){
            Decimal totalPO = 0;
            if(sumByProductMap.get(prod.Id) != null) totalPO = sumByProductMap.get(prod.Id);
            prod.Total_Purchase_Orders__c = totalPO;
        }
        try {
            Database.update(productList);
        }  
        catch(Exception e) {
            Utilities.CreateExceptionLog(e, 'OrderTriggerHandler: calculateProductTotalPO Product update');
        }
        
    }
    
    /*Created by: JP Sulit (jp@bricoleurtech.com)
Created Date: Feb 8, 2024
*/
    public static void calcTotalPurchaseOrders(Map<Id, Set<String>> completedOrderProductsMap) {
        
        Map<Id, Decimal> standardProductsMap = ClipperSettingUtility.getStdProdIdMap(completedOrderProductsMap);
        Map<Id, Product2> supplierProductsMap = ClipperSettingUtility.getSupplierProductsMap(standardProductsMap);
        Map<Id, List<OrderItem>> purchaseOrderLineMap = ClipperSettingUtility.getPurchaseOrderLineMap(supplierProductsMap);
        Map<Id, Purchase_Order_Products_Received_bric__c> grnLineRcvdMap = ClipperSettingUtility.getGrnLineRcvdMap(purchaseOrderLineMap);
        Map<String, Decimal> purchaseOrderProductTotalsMap = ClipperSettingUtility.getPurchaseOrderProductTotals(supplierProductsMap);
        Map<String, Decimal> grnLineProductTotalsMap = ClipperSettingUtility.getGrnLineProductTotals(purchaseOrderLineMap);
        
        Map<String, Decimal> openPurchaseOrderTotalMap = new Map<String, Decimal>();
        Map<String, Decimal> openPurchaseOrderTotalStdMap = new Map<String, Decimal>();
        Map<String, Product2> standardProductMapToUpdate = new Map<String, Product2>();
        Set<String> warehouseIdSet =  new Set<String>();
        List<Location_Product__c> locProductToUpdate = new List<Location_Product__c>();
        
        System.debug('calcTotalPurchaseOrders purchaseOrderProductTotalsMap bric '+purchaseOrderProductTotalsMap);
        System.debug('calcTotalPurchaseOrders grnLineProductTotalsMap bric '+grnLineProductTotalsMap);
        
        for(String key : purchaseOrderProductTotalsMap.keySet()) {
            if(grnLineProductTotalsMap.containsKey(key)) {
                Decimal purchaseOrderTotal = purchaseOrderProductTotalsMap.get(key) - grnLineProductTotalsMap.get(key);
                openPurchaseOrderTotalMap.put(key, purchaseOrderTotal);
            }
        }
        
        System.debug('calcTotalPurchaseOrders openPurchaseOrderTotalMap bric 1 '+openPurchaseOrderTotalMap);
        
        for(String key : openPurchaseOrderTotalMap.keySet()) {
            String warehouseId = key.split(';')[0];
            String prodId = key.split(';')[1];
            
            if(supplierProductsMap.containsKey(prodId)) {
                Decimal conversionFactor = supplierProductsMap.get(prodId).Conversion_Factor__c;
                Id standardProductId = supplierProductsMap.get(prodId).Id;
                openPurchaseOrderTotalStdMap.put(warehouseId+';'+standardProductId, openPurchaseOrderTotalMap.get(key) * conversionFactor);
                standardProductMapToUpdate.put(standardProductId, supplierProductsMap.get(prodId));
            }
        }
        
        System.debug('calcTotalPurchaseOrders openPurchaseOrderTotalStdMap bric '+openPurchaseOrderTotalStdMap);
        
        for(Location_Product__c locProd : [SELECT Id, Product__c, Total_Purchase_Orders__c,Location_Product_Key_Bric__c
                                           FROM Location_Product__c WHERE
                                           Location_Product_Key_Bric__c IN : openPurchaseOrderTotalStdMap.keySet()]) {
                                               
                                               System.debug('calcTotalPurchaseOrders openPurchaseOrderTotalStdMap bric '+openPurchaseOrderTotalStdMap.get(locProd.Location_Product_Key_Bric__c));
                                               locProd.Total_Purchase_Orders__c = openPurchaseOrderTotalStdMap.get(locProd.Location_Product_Key_Bric__c);
                                               System.debug('calcTotalPurchaseOrders Total_Purchase_Orders__c bric '+locProd.Total_Purchase_Orders__c);
                                               locProductToUpdate.add(locProd);
                                               standardProductMapToUpdate.get(locProd.Product__c).Total_Purchase_Orders__c = openPurchaseOrderTotalStdMap.get(locProd.Location_Product_Key_Bric__c);
                                           }
        
        System.debug('calcTotalPurchaseOrders locProductToUpdate bric '+locProductToUpdate);
        
        try {
            Database.update(locProductToUpdate);
            Database.update(standardProductMapToUpdate.values());
        }
        catch(Exception e){
            Utilities.CreateExceptionLog(e, 'OrderTriggerHandler: calcTotalPurchaseOrders');
        }
    }
    
    /**
* @description Optimized createUpdateInventoryMovement method
* @author Bricoleur Technologies (jp@bricoleurtech.com)
* @date July-02-2024
*/
    //START
    public static void createUpdateInventoryMovement2(Set<Id> orderItemIdSet) {
        
        List<Inventory_Movement__c> invMovementList = [SELECT Id, As_At__c,Order__c,Order_Product__c,Movement__c,
                                                       Product__c,Location__c FROM Inventory_Movement__c
                                                       WHERE Order_Product__c IN: orderItemIdSet
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
                                 WHERE Id IN : orderItemIdSet]) {
                                     
                                     Inventory_Movement__c inv = new Inventory_Movement__c();
                                     inv.Id = invMovementToOrderProductMap.get(ordItem.Id)?.Id;
                                     inv.As_At__c = DateTime.now();
                                     Id locId = NULL;
                                     if(ordItem.Order.RecordTypeId == salesOrderRecordTypeId && ordItem.Location__c != NULL) locId = ordItem.Location__c;
                                     else locId = ordItem.Order.Inventory_Location__c;
                                     inv.Location__c = locId;
                                     Decimal movementTotal = 0;
                                     if(ordItem.Order.RecordTypeId == salesOrderRecordTypeId || ordItem.Order.RecordTypeId == stockTransferRecordTypeId){
                                         movementTotal = ordItem.Quantity * -1;
                                         inv.Movement__c = movementTotal;
                                         inv.Order__c = ordItem.OrderId;
                                         inv.Order_Product__c = ordItem.Id;
                                         inv.Product__c = ordItem.Product2Id;
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
    //END
    
    /*
* Method created by : Nagendra Yanadigalla
* Created Date : November 4, 2024
*/
    //CT-14 STARTS
    public static Map<Id, Date> getNextOrderDates(List<Order> orders) {
        Map<Id, Date> nextOccurrenceDates = new Map<Id, Date>();
        
        for (Order order : orders) {
            // Default nextOrderDate to null
            Date nextOrderDate = null;
            
            // Check snooze condition
            if (order.Snooze_Order__c == true && order.Snooze_Start_Date__c >= Date.today() && order.Snooze_End_Date__c == null) {
                nextOccurrenceDates.put(order.Id, null);
                continue;
            }
            
            // Calculate next occurrence date based on frequency
            if (order.Recurrence_Frequency__c == 'Daily') {
                // Daily logic
                nextOrderDate = (order.Snooze_Order__c == true && order.Snooze_End_Date__c != null) ? 
                    order.Snooze_End_Date__c.addDays(1) : Date.today().addDays(1);
                
            } else if (order.Recurrence_Frequency__c == 'Weekly') {
                //Weekly logic
                List<Integer> recurrenceWeekdays = getRecurrenceWeekdays(order.Recurrence_Weekdays__c);
                nextOrderDate = getNextWeeklyOccurrence(Date.today(), recurrenceWeekdays, order.Snooze_Order__c, order.Snooze_End_Date__c);                
            } else if (order.Recurrence_Frequency__c == 'Monthly') {
                // Monthly logic
                if (order.Recurrence_When__c == 'Specific Days') {
                    Integer specificDay = Integer.valueOf(order.Specific_Day__c);
                    nextOrderDate = getNextSpecificDayOccurrence(specificDay, order.Snooze_Order__c, order.Snooze_End_Date__c);
                } else if (order.Recurrence_When__c == 'Relative Days') {
                    // Implement relative days logic
                    nextOrderDate = getNextRelativeDayOccurrence(order);
                }
            }
            
            // Check if nextOrderDate exceeds recurrence end date
            if (order.Recurrence_End_Date__c != null && nextOrderDate != null && nextOrderDate > order.Recurrence_End_Date__c) {
                nextOrderDate = null;
            }
            
            // Store the result
            nextOccurrenceDates.put(order.Id, nextOrderDate);
        }
        
        return nextOccurrenceDates;
    }
    private static List<Integer> getRecurrenceWeekdays(String recurrenceWeekdaysStr) {
        // Helper to parse Recurrence_Weekdays__c into a list of integers representing weekdays
        Map<String, Integer> dayOfWeekMap = new Map<String, Integer>{
            'Sunday' => 1, 'Monday' => 2, 'Tuesday' => 3, 'Wednesday' => 4, 
                'Thursday' => 5, 'Friday' => 6, 'Saturday' => 7
                };
                    
                    List<Integer> weekdays = new List<Integer>();
        if (recurrenceWeekdaysStr != null) {
            for (String day : recurrenceWeekdaysStr.split(';')) {
                day = day.trim();
                if (dayOfWeekMap.containsKey(day)) {
                    weekdays.add(dayOfWeekMap.get(day));
                }
            }
        }
        
        return weekdays;
    }    
    private static Date getNextWeeklyOccurrence(Date today, List<Integer> weekdays, Boolean snoozeOrder, Date snoozeEndDate) {
        // Base date is either snoozeEndDate or today
        Date baseDate = snoozeOrder && snoozeEndDate != null ? snoozeEndDate : today;
        
        // Get the start of the week for baseDate
        Date startOfWeek = baseDate.toStartOfWeek();
        
        // Initialize nextDate to a very high value
        Date nextDate = Date.newInstance(9999, 12, 31); 
        
        // Iterate through each weekday to find the next occurrence
        for (Integer weekday : weekdays) {
            // Calculate the potential next occurrence date
            Date potentialDate = startOfWeek.addDays(weekday - 1);
            
            // If the potential date is greater than or equal to the base date
            if (potentialDate > baseDate) {
                if (potentialDate < nextDate) {
                    nextDate = potentialDate; // Update nextDate to the found potentialDate
                }
            } else {
                // If the potential date is before the base date, calculate for the next week
                Date nextWeekPotentialDate = startOfWeek.addDays(7).addDays(weekday - 1);
                if (nextWeekPotentialDate < nextDate) {
                    nextDate = nextWeekPotentialDate; // Update nextDate to the found nextWeekPotentialDate
                }
            }
        }
        
        return nextDate;
    }
    // Helper method to calculate next monthly occurrence on a specific day of the month
    private static Date getNextSpecificDayOccurrence(Integer day, Boolean snoozeOrder, Date snoozeEndDate) {
        Date baseDate = snoozeOrder && snoozeEndDate != null ? snoozeEndDate : Date.today();
        Date nextDate = Date.newInstance(baseDate.year(), baseDate.month(), day);
        system.debug('baseDate--->'+baseDate);
        system.debug('nextDate--->'+nextDate);
        if (nextDate <= baseDate) {
            system.debug('IF Loop');
            nextDate = nextDate.addMonths(1);
        }
        return nextDate;
    }
    
    // Helper method to calculate the next monthly occurrence on a relative day of the month
    private static Date getNextRelativeDayOccurrence(Order order) {
        // Check if Snooze Order is true
        if (order.Snooze_Order__c) {
            // If Snooze Order is true, return the next occurrence after the Snooze End Date
        if (order.Snooze_End_Date__c != null) {
            Date snoozeEndDate = order.Snooze_End_Date__c;

            Integer dayOfWeek = getDayOfWeekFromRelativeDay(order.Relative_Day_Repeat_On__c);
            Integer weekOfMonth = getWeekOfMonthFromRelativeRepeatOn(order.Relative_Day__c);

            // Calculate the first occurrence in the current month (month of snooze end date)
            Date firstOccurrenceThisMonth = getDateForRelativeDay(Date.newInstance(snoozeEndDate.year(), snoozeEndDate.month(), 1), dayOfWeek, weekOfMonth);

            // If the first occurrence in the current month is on or before the snooze end date, skip to the next month
            if (firstOccurrenceThisMonth <= snoozeEndDate) {
                Date nextMonthStart = snoozeEndDate.addMonths(1);
                return getDateForRelativeDay(Date.newInstance(nextMonthStart.year(), nextMonthStart.month(), 1), dayOfWeek, weekOfMonth);
            } else {
                return firstOccurrenceThisMonth;
            }
        }
        } else {
            // If Snooze Order is false, generate date based on current month
            Date today = Date.today();
            Integer dayOfWeek = getDayOfWeekFromRelativeDay(order.Relative_Day_Repeat_On__c);
            Integer weekOfMonth = getWeekOfMonthFromRelativeRepeatOn(order.Relative_Day__c);
            
            // Generate initial target date for the current month
            Date targetDate = getDateForRelativeDay(Date.newInstance(today.year(), today.month(), 1), dayOfWeek, weekOfMonth);
            
            // If the generated date is in the past, move to the next month
            if (targetDate <= today) {
                Integer nextMonth = today.month() == 12 ? 1 : today.month() + 1;
                Integer nextYear = today.month() == 12 ? today.year() + 1 : today.year();
                targetDate = getDateForRelativeDay(Date.newInstance(nextYear, nextMonth, 1), dayOfWeek, weekOfMonth);
            }
            
            return targetDate; // Return the next occurrence date
        }
        
        return null; // Return null if no valid date found
    }
    
    // Helper to get the date for a specific relative day in a month
    private static Date getDateForRelativeDay(Date firstOfMonth, Integer dayOfWeek, Integer weekOfMonth) {
        Date initialDay = firstOfMonth;
        Integer currentWeek = 1;
        Integer dayOfWeekCounter = 0;
        
        while (currentWeek <= 4) {
            if (initialDay.toStartOfWeek().daysBetween(initialDay) + 1 == dayOfWeek) {
                dayOfWeekCounter++;
                if (dayOfWeekCounter == weekOfMonth) {
                    return initialDay; // Return the date for the specific relative day and week
                }
            }
            initialDay = initialDay.addDays(1);
            if (initialDay.month() != firstOfMonth.month()) break; 
        }
        
        // Handle "Last" for the last occurrence of the specified day in the month
        if (weekOfMonth == -1) {
            Date lastDayOfMonth = firstOfMonth.addMonths(1).addDays(-1);
            while ((lastDayOfMonth.toStartOfWeek().daysBetween(lastDayOfMonth) + 1) != dayOfWeek) {
                lastDayOfMonth = lastDayOfMonth.addDays(-1);
            }
            return lastDayOfMonth;
        }
        
        return null; // Return null if no valid date found
    }
    
    // Utility to get the weekday integer from relative day repeat on field
    private static Integer getDayOfWeekFromRelativeDay(String relativeDay) {
        Map<String, Integer> dayOfWeekMap = new Map<String, Integer>{
            'Sunday' => 1,
                'Monday' => 2,
                'Tuesday' => 3,
                'Wednesday' => 4,
                'Thursday' => 5,
                'Friday' => 6,
                'Saturday' => 7
                };
                    return dayOfWeekMap.get(relativeDay);
    }
    
    // Utility to get week of month from relative day
    private static Integer getWeekOfMonthFromRelativeRepeatOn(String repeatOn) {
        Map<String, Integer> weekOfMonthMap = new Map<String, Integer>{
            'First' => 1,
                'Second' => 2,
                'Third' => 3,
                'Fourth' => 4,
                'Last' => -1
                };
                    return weekOfMonthMap.get(repeatOn);
    }
    //CT-14 ENDS
}