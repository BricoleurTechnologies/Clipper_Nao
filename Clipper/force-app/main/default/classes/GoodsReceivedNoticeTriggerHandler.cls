public class GoodsReceivedNoticeTriggerHandler {
    
    public static final Id stockTransferRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(ClipperSettingUtility.getStockTransferRecordTypeDevName()).getRecordTypeId();
        
    public static void onAfterInsert(List<Goods_Received_Notice_bric__c> grnList){
        
        createUpdateInventoryMovement(grnList);
        
    }
    
    public static void onAfterUpdate(List<Goods_Received_Notice_bric__c> grnList){
        
        createUpdateInventoryMovement(grnList);
        /*Created by: JP Sulit (jp@bricoleurtech.com)
        Created Date: Feb 12, 2024
        Description: Gets total purchase order sum from Order Products and GRN Lines
        */
        //START 
        Map<Id, Set<String>> completedGrnProductsMap = ClipperSettingUtility.getCompletedGrnProducts(grnList);
        ClipperSettingUtility.calcTotalPurchaseOrders(completedGrnProductsMap);
        //END
    }
    
    public static void createUpdateInventoryMovement(List<Goods_Received_Notice_bric__c> grnList){
        
        List<Purchase_Order_Products_Received_bric__c> poprList = [SELECT Id, Product_bric__c,Last_Cost__c, Amount_Received__c, Order_Quantity__c,Goods_Received_Notice_bric__c,Order_Product_bric__r.OrderId,
                                                                   Order_Product_bric__c, Order_Product_bric__r.Order.Inventory_Location__c, Product_bric__r.RecordType.DeveloperName,
                                                                   Order_Product_bric__r.Order.Delivery_Location__c,Product_bric__r.Inventory_Status__c,Order_Product_bric__r.Order.RecordTypeId,                                                                  
                                                                   Product_bric__r.Conversion_Factor__c                                                                   
                                                                   FROM Purchase_Order_Products_Received_bric__c
                                                                   WHERE Goods_Received_Notice_bric__c IN :grnList
                                                                   AND Amount_Received__c > 0
                                                                   AND Product_bric__r.Inventory_Status__c != 'Non-Stock Item'];
        
        List<String> orderItemIds = new List<String>();
        List<String> prodIds = new List<String>();
        
        for(Purchase_Order_Products_Received_bric__c popRec : poprList){
            if(popRec.Product_bric__c != null) prodIds.add(popRec.Product_bric__c);
        }
                
        List<Inventory_Movement__c> invMovementList = [SELECT Id, As_At__c,Order__c,Goods_Received_Notice_Line_Item__c,Movement__c,
                                                       Product__c,Location__c FROM Inventory_Movement__c
                                                       WHERE Goods_Received_Notice_Line_Item__c IN: poprList
                                                       AND Goods_Received_Notice_Line_Item__c != NULL];
        
        List<Product2> standardProductList = [SELECT Id, Name, Conversion_Factor__c, Supplier_Product__c
                                              FROM Product2 
                                              WHERE RecordType.DeveloperName = 'Standard'];
        
        
        List<Product_Suppliers_bric__c> productSupplierList = [SELECT Id, Supplier_Product_bric__c,Product_bric__c,Conversion_Factor__c
                                                               FROM Product_Suppliers_bric__c 
                                                               WHERE Supplier_Product_bric__c != NULL
                                                               AND Product_bric__c != NULL
                                                               AND Supplier_Product_bric__c IN: prodIds];
        
        Map<Id,Product2> supplierTostandardProduct = new Map<Id,Product2>();
        Map<Id,Product2> standardProdMap = new Map<Id,Product2>();
        Map<Id,Decimal> supplierConvFactor = new Map<Id,Decimal>();
        
        for(Product2 stdProd : standardProductList){
            standardProdMap.put(stdProd.Id, stdProd);
            if(stdProd.Supplier_Product__c != null){
                supplierTostandardProduct.put(stdProd.Supplier_Product__c,stdProd);
                supplierConvFactor.put(stdProd.Supplier_Product__c, stdProd.Conversion_Factor__c);
            }
        }
        
        if(productSupplierList.size() > 0){
            for(Product_Suppliers_bric__c prodSup : productSupplierList){
                if(supplierTostandardProduct.get(prodSup.Supplier_Product_bric__c) == NULL){
                    supplierTostandardProduct.put(prodSup.Supplier_Product_bric__c,standardProdMap.get(prodSup.Product_bric__c));
                    supplierConvFactor.put(prodSup.Supplier_Product_bric__c, prodSup.Conversion_Factor__c);

                }
            }
        }
        
        Map<Id,Inventory_Movement__c> invMovementToGRNLineMap = new  Map<Id,Inventory_Movement__c>();
        
        for(Inventory_Movement__c invMov : invMovementList){
            invMovementToGRNLineMap.put(invMov.Goods_Received_Notice_Line_Item__c,invMov);
        }
        
        List<Inventory_Movement__c> invMovementListToUpsert = new List<Inventory_Movement__c>();
        for(Purchase_Order_Products_Received_bric__c poprItem : poprList){
            Decimal movementTotal = 0;
            
            if(poprItem.Order_Product_bric__c != null){
                orderItemIds.add(poprItem.Order_Product_bric__c);
            }
            
            Id locationId = null;
            if(poprItem.Order_Product_bric__r.Order.RecordTypeId == stockTransferRecordTypeId){
                locationId = poprItem.Order_Product_bric__r.Order.Delivery_Location__c;
            }else{  
                locationId = poprItem.Order_Product_bric__r.Order.Inventory_Location__c;
            }
            
            if(poprItem.Product_bric__r.RecordType.DeveloperName == 'Supplier_Product'){
                if(supplierTostandardProduct.get(poprItem.Product_bric__c) != NULL){
                    Inventory_Movement__c supInv = new Inventory_Movement__c();
                    supInv.Id = invMovementToGRNLineMap.get(poprItem.Id)?.Id;
                    supInv.As_At__c = DateTime.now();
                    supInv.Location__c =  locationId;
                    Decimal supMovementTotal = 0;
                    Decimal convFactor = 1;
                    if(supplierConvFactor.get(poprItem.Product_bric__c) != null) convFactor = supplierConvFactor.get(poprItem.Product_bric__c);
                    supMovementTotal = poprItem.Amount_Received__c * convFactor;
                    supInv.Movement__c = supMovementTotal;
                    supInv.Order__c = poprItem.Order_Product_bric__r.OrderId;
                    supInv.Order_Product__c = poprItem.Order_Product_bric__c;
                    supInv.Product__c =  supplierTostandardProduct.get(poprItem.Product_bric__c)?.Id;
                    supInv.Goods_Received_Notice_Line_Item__c = poprItem.Id;
                    invMovementListToUpsert.add(supInv);
                    System.debug('invMovementListToUpsert supplier product '+invMovementListToUpsert);
                }else{
                    
                    system.debug('not found in supplierTostandardProduct::: '+poprItem.Product_bric__c);
                }
            }else{
                Inventory_Movement__c supInv = new Inventory_Movement__c();
                supInv.Id = invMovementToGRNLineMap.get(poprItem.Id)?.Id;
                supInv.As_At__c = DateTime.now();
                supInv.Location__c =  locationId;
                Decimal supMovementTotal = 0;
                Decimal convFactor = 1;
                /**
                 * @description Added checking if Order is not Stock Transfer
                 * @date Apr-22-2024
                 * @author Bricoleur Technologies
                 */
                //START
                if(poprItem.Order_Product_bric__r.Order.RecordTypeId != stockTransferRecordTypeId) {
                    if(poprItem.Product_bric__r?.Conversion_Factor__c != null) convFactor = poprItem.Product_bric__r?.Conversion_Factor__c;
                }
                else {
                    convFactor = 1;
                }
                //END
                System.debug('invMovementListToUpsert convFactor '+convFactor);
                supMovementTotal = poprItem.Amount_Received__c * convFactor;
                supInv.Movement__c = supMovementTotal;
                supInv.Order__c = poprItem.Order_Product_bric__r.OrderId;
                supInv.Order_Product__c = poprItem.Order_Product_bric__c;
                supInv.Product__c =  poprItem.Product_bric__c;
                supInv.Goods_Received_Notice_Line_Item__c = poprItem.Id;
                invMovementListToUpsert.add(supInv);
                System.debug('invMovementListToUpsert standard product '+invMovementListToUpsert);
            }
            /**
             * @description Added checking if Order is Stock Transfer and do logic for source warehouse
             * @date Apr-22-2024
             * @author Bricoleur Technologies
             */
            //START
            if(poprItem.Order_Product_bric__r.Order.RecordTypeId == stockTransferRecordTypeId) {
                Inventory_Movement__c supInvSource = new Inventory_Movement__c();
                //supInvSource.Id = invMovementToGRNLineMap.get(poprItem.Id)?.Id;
                supInvSource.As_At__c = DateTime.now();
                supInvSource.Location__c = poprItem.Order_Product_bric__r.Order.Inventory_Location__c;
                supInvSource.Movement__c = poprItem.Amount_Received__c * -1;
                supInvSource.Order__c = poprItem.Order_Product_bric__r.OrderId;
                supInvSource.Order_Product__c = poprItem.Order_Product_bric__c;
                supInvSource.Product__c =  poprItem.Product_bric__c;
                supInvSource.Goods_Received_Notice_Line_Item__c = poprItem.Id;
                invMovementListToUpsert.add(supInvSource);
            }
            //END
        }        
        system.debug('invMovementListToUpsert::: '+invMovementListToUpsert);
        try{
            if(invMovementListToUpsert.size() > 0) Database.upsert(invMovementListToUpsert);
            if(orderItemIds.size() > 0) calculateAmountReceived(orderItemIds);
        }catch(Exception e){
            Utilities.CreateExceptionLog(e,'GoodsReceivedNoticeTriggerHandler');
        }
        //calculateProductTotals(poprList, prodIds);
    }
    
    //UPDATE Amount Received value on Order Product Record
    public static void calculateAmountReceived( List<String> orderItemIds ){
        
        List<OrderItem> ordItemList = new List<OrderItem>();
        
        List<Purchase_Order_Products_Received_bric__c> poprList = [SELECT Id, Product_bric__c,Last_Cost__c, Amount_Received__c, Order_Quantity__c,Goods_Received_Notice_bric__c,Order_Product_bric__r.OrderId,
                                                                   Order_Product_bric__c, Order_Product_bric__r.Order.Inventory_Location__c, Product_bric__r.RecordType.DeveloperName,
                                                                   Product_bric__r.Conversion_Factor__c
                                                                   FROM Purchase_Order_Products_Received_bric__c
                                                                   WHERE Order_Product_bric__c IN :orderItemIds
                                                                   AND Amount_Received__c > 0];
        
        Map<String,Decimal> ordProdReceived = new Map<String,Decimal>();
        
        for(Purchase_Order_Products_Received_bric__c popRec : poprList){
            if(popRec.Order_Product_bric__c != null){
                if(ordProdReceived.get(popRec.Order_Product_bric__c) == NULL){
                    ordProdReceived.put(popRec.Order_Product_bric__c,popRec.Amount_Received__c);                    
                }else{
                    Decimal amtRcvd = ordProdReceived.get(popRec.Order_Product_bric__c);
                    amtRcvd += popRec.Amount_Received__c;
                    ordProdReceived.put(popRec.Order_Product_bric__c,amtRcvd);
                }
            }
            
        }
        
        for(String ordItemID : ordProdReceived.keySet()){
            OrderItem ordItem = new OrderItem();
            ordItem.Id = ordItemID;
            ordItem.Amount_Received__c = ordProdReceived.get(ordItemID);
            ordItemList.add(ordItem);
        }
        
        try{
            if(ordItemList.size() > 0) Database.upsert(ordItemList);
        }catch(Exception e){
            Utilities.CreateExceptionLog(e,'GoodsReceivedNoticeTriggerHandler: calculateAmountReceived');
        }
        
    }
}