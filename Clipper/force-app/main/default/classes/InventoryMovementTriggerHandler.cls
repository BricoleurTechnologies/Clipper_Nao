public without sharing class InventoryMovementTriggerHandler {
    
    public static final Id stockTransferRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(ClipperSettingUtility.getStockTransferRecordTypeDevName()).getRecordTypeId();

    public static void onAfterInsert(List<Inventory_Movement__c> priorInvMovements, List<Inventory_Movement__c> newInvMovements, Map<Id,Inventory_Movement__c> newMapInvMovements){
        
        Set<Id> productIds = new Set<Id>();
        Set<Id> locIds = new Set<Id>();
        Set<Id> grnIds = new Set<Id>();
        Set<String> locProdKeys = new Set<String>();
        
        for(Inventory_Movement__c inv : newInvMovements){
            if(inv.Product__c != NULL) productIds.add(inv.Product__c);
            if(inv.Location__c != NULL) locIds.add(inv.Location__c);
            if(inv.Product__c != NULL && inv.Location__c != NULL) locProdKeys.add(inv.Location__c+'-'+inv.Product__c);
            if(inv.Goods_Received_Notice_Line_Item__c != NULL) grnIds.add(inv.Goods_Received_Notice_Line_Item__c);
        }
        
        if(grnIds.size() > 0){
            System.debug('inventory bric calculateProductWeightedAverageCost');
            calculateProductWeightedAverageCost(grnIds, productIds,newInvMovements, locIds);
        }else {
            System.debug('inventory bric calculateInStockLocationProduct');
            calculateInStockLocationProduct(locIds, productIds,locProdKeys);
            //calculateProductTotals(productIds,locIds);
        }
    }
    
    public static void onAfterUpdate(List<Inventory_Movement__c> priorInvMovements, List<Inventory_Movement__c> newInvMovements){
        
        Set<Id> productIds = new Set<Id>();
        Set<Id> locIds = new Set<Id>();
        Set<Id> grnIds = new Set<Id>();
        Set<String> locProdKeys = new Set<String>();
        
        for(Inventory_Movement__c inv : newInvMovements){
            if(inv.Product__c != NULL) productIds.add(inv.Product__c);
            if(inv.Location__c != NULL) locIds.add(inv.Location__c);
            if(inv.Product__c != NULL && inv.Location__c != NULL) locProdKeys.add(inv.Location__c+'-'+inv.Product__c);
            if(inv.Goods_Received_Notice_Line_Item__c != NULL) grnIds.add(inv.Goods_Received_Notice_Line_Item__c);
        }
        
        if(grnIds.size() > 0){
            calculateProductWeightedAverageCost(grnIds, productIds,newInvMovements, locIds);
        }else {
            calculateInStockLocationProduct(locIds, productIds,locProdKeys);
            //calculateProductTotals(productIds,locIds);
        }
    }
    
    public static void onAfterDelete(List<Inventory_Movement__c> priorInvMovements){
        
    }
    /*
    public static void calculateProductInventory(Set<ID> ids) {
        
        List<Product2> productList = [SELECT Id,Total_Available__c FROM Product2 WHERE Id IN :ids];
        List<AggregateResult> invMovementTotalByProduct = [select Product__c, sum(Movement__c)movementTotal
                                                           from Inventory_Movement__c
                                                           group by Product__c];
        Map<String,Decimal> sumByProductMap = new Map<String,Decimal>();
        
        for(AggregateResult inv : invMovementTotalByProduct){
            
            String prodId = '';
            if(inv.get('Product__c') != null) prodId = (String)inv.get('Product__c');
            
            Decimal invTotal = 0;
            if(inv.get('movementTotal') != null && inv.get('movementTotal') != '') invTotal = (Decimal)inv.get('movementTotal');
            
            sumByProductMap.put(prodId, invTotal);
        }
        
        for(Product2 prod : productList){
            Decimal totalAvailable = 0;
            if(sumByProductMap.get(prod.Id) != null) totalAvailable = sumByProductMap.get(prod.Id);
            prod.Total_Available__c = totalAvailable;
        }
        
        update productList;
    }
	*/
    
    public static void calculateInStockLocationProduct(Set<Id> locIds, Set<Id> prodIds,Set<String> locProdKeys) {
        
        Map<String,Location_Product__c> locationProductMap = new Map<String,Location_Product__c>();
        Map<String,Decimal> locationProductInStockMap = new Map<String,Decimal>();     
        Set<String> locProdKeysWithStocktake = new Set<String>();
        
        List<Location_Product__c> locProductList = [SELECT Id, Location__c, Product__c FROM 
                                                    Location_Product__c
                                                    WHERE Location__c IN: locIds
                                                    AND Product__c IN: prodIds];
        System.debug('calculateInStockLocationProduct locProductList '+locProductList);

        for(Location_Product__c locProd : locProductList){
            String key = locProd.Location__c + '-' + locProd.Product__c;
            System.debug('calculateInStockLocationProduct key '+key);
            locationProductMap.put(key,locProd);
        }
        
        //Calculate In Stock field 
        //(total number (amount) in stock from inventory movements)
        
        List<Inventory_Movement__c> inventoryMovementList =[SELECT Movement__c,Product__c,Location__c, 
                                                            As_At__c,Record_Type_Name_bric__c
                                                            FROM Inventory_Movement__c 
                                                            WHERE Product__c != null AND Location__c != null
                                                            AND Product__c IN: prodIds AND Location__c IN: locIds
                                                            ORDER BY As_At__c DESC];

        System.debug('calculateInStockLocationProduct inventoryMovementList '+inventoryMovementList);
        
        for(Inventory_Movement__c invMovement : inventoryMovementList){
            String key = invMovement.Location__c + '-' + invMovement.Product__c;
            Decimal movementValue = invMovement.Movement__c == null ? 0: invMovement.Movement__c;
            if(!locProdKeysWithStocktake.contains(key)){
                if(invMovement.Record_Type_Name_bric__c == 'Stocktake') locProdKeysWithStocktake.add(key);
                
                if(locationProductInStockMap.get(key) != null){
                    locationProductInStockMap.put(key,locationProductInStockMap.get(key) + movementValue);
                }else{   
                    locationProductInStockMap.put(key,movementValue);
                }                
            }
        }

        System.debug('calculateInStockLocationProduct locationProductInStockMap '+locationProductInStockMap);
                
        List<Location_Product__c> locProdToUpdateList = new  List<Location_Product__c>();
        for(String locProdKey : locProdKeys){
            Location_Product__c locProd = new Location_Product__c();
            locProd.Id = locationProductMap.get(locProdKey)?.Id;
            String[] locProdString = locProdKey.split('-'); 
            locProd.Location__c = locProdString[0];
            locProd.Product__c = locProdString[1];
            locProd.In_Stock__c = locationProductInStockMap.get(locProdKey);
            locProdToUpdateList.add(locProd);
        }
        
        System.debug('calculateInStockLocationProduct locProdToUpdateList '+locProdToUpdateList);

        List<Database.UpsertResult> dmlResults = Database.upsert(locProdToUpdateList);  
        for(Database.UpsertResult ur : dmlResults)
        {
            if(ur.isSuccess())
            {
                if(ur.isCreated()) system.debug('Created locProd ID: ' + ur.getId());
                else system.debug('Updated locProd ID: ' + ur.getId());
            }
            else
            {
                for(Database.Error err : ur.getErrors())
                {
                    Utilities.CreateExceptionLog(null,err.getMessage() +':::'+ err.getFields());
                    System.debug('Error locProd: ' + err);
                }
            }
        }
        
        calculateProductTotals(prodIds,locIds);
    }
    
    public static void calculateProductTotals(Set<ID> productIds, Set<Id> locIds) {
        
        List<Product2> productList = [SELECT Id,Weighted_Average_Cost__c,Total_Stock__c FROM Product2 WHERE Id IN :productIds];
        List<AggregateResult> totalInStockByProduct = [SELECT Product__c, sum(In_Stock__c)totalInStock
                                                       FROM Location_Product__c
                                                       WHERE Product__c IN :productIds
                                                       GROUP BY Product__c];        
        
        List<AggregateResult> totalAvailableByProduct = [SELECT Product__c, sum(Available_To_Promise__c)totalAvailable
                                                         FROM Location_Product__c
                                                         WHERE Product__c IN :productIds
                                                         GROUP BY Product__c];
        
        
        Map<String,Decimal> sumByProductMap = new Map<String,Decimal>();
        Map<String,Decimal> sumAvailableByProductMap = new Map<String,Decimal>();
        
        for(AggregateResult stock : totalInStockByProduct){
            
            String prodId = '';
            if(stock.get('Product__c') != null) prodId = (String)stock.get('Product__c');
            
            Decimal inStockTotal = 0;
            if(stock.get('totalInStock') != null && stock.get('totalInStock') != '') inStockTotal = (Decimal)stock.get('totalInStock');                        
            sumByProductMap.put(prodId, inStockTotal);
        }
        
        for(AggregateResult avail : totalAvailableByProduct){
            
            String prodId = '';
            if(avail.get('Product__c') != null) prodId = (String)avail.get('Product__c');
            
            Decimal availableTotal = 0;
            if(avail.get('totalAvailable') != null && avail.get('totalAvailable') != '') availableTotal = (Decimal)avail.get('totalAvailable');                        
            sumAvailableByProductMap.put(prodId, availableTotal);
        }
        
        for(Product2 prod : productList){
            Decimal totalStock = 0;
            if(sumByProductMap.get(prod.Id) != null) totalStock = sumByProductMap.get(prod.Id);
            prod.Total_Stock__c = totalStock;            
            
            Decimal totalAvailable = 0;
            if(sumAvailableByProductMap.get(prod.Id) != null) totalAvailable = sumAvailableByProductMap.get(prod.Id);
            prod.Total_Available__c = totalAvailable;
        }
        
        Database.update(productList);  

     
    }
    
    //Update Weighted Average Cost
    public static void calculateProductWeightedAverageCost(Set<Id> grnList, Set<Id> prodIds, List<Inventory_Movement__c> newInvMovements, Set<Id> locIds){
        
         List<Product2> standardProductList = [SELECT Id, Name, Conversion_Factor__c, Supplier_Product__c
                                              FROM Product2 
                                              WHERE RecordType.DeveloperName = 'Standard'];
        
        
        List<Product_Suppliers_bric__c> productSupplierList = [SELECT Id, Supplier_Product_bric__c,Product_bric__c,Conversion_Factor__c
                                                               FROM Product_Suppliers_bric__c 
                                                               WHERE Supplier_Product_bric__c != NULL
                                                               AND Product_bric__c != NULL
                                                               AND Product_bric__c IN: prodIds];
                
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
        
        List<Purchase_Order_Products_Received_bric__c> poprList = [SELECT Id, Product_bric__c,Last_Cost__c, Amount_Received__c, Order_Quantity__c,Goods_Received_Notice_bric__c,Order_Product_bric__r.OrderId,
                                                                   Order_Product_bric__c, Order_Product_bric__r.Order.Inventory_Location__c, Product_bric__r.RecordType.DeveloperName,Order_Product_bric__r.Order.RecordType.DeveloperName,
                                                                   Product_bric__r.Conversion_Factor__c, Order_Product_bric__r.Order.Delivery_Location__c
                                                                   FROM Purchase_Order_Products_Received_bric__c
                                                                   WHERE Id IN :grnList];
        List<Product2> productList = new List<Product2> ();
        Map<Id,Product2> prodMap = new Map<Id,Product2>([SELECT Id, Weighted_Average_Cost__c, Total_Stock__c FROM Product2 WHERE Id IN : prodIds]);
        Set<String> locProdKeys = new Set<String>();
        
        Map<Id, Id> grnLineItemToProduct = new Map<Id, Id>();
        for(Inventory_Movement__c invMovement : newInvMovements){
            if(invMovement.Goods_Received_Notice_Line_Item__c != null){
                grnLineItemToProduct.put(invMovement.Goods_Received_Notice_Line_Item__c, invMovement.Product__c);
            }            
            if(invMovement.Product__c != NULL && invMovement.Location__c != NULL) locProdKeys.add(invMovement.Location__c+'-'+invMovement.Product__c);
        }
        
        //MAP checkCalculateWAC
        Map<String,Boolean> rtToCalcWAC = new Map<String,Boolean>();
        List<Clipper_Inventory_Setting__mdt> clipperSettingList = [SELECT Id,Calculate_Weighted_AverageCost__c, Record_Type_Developer_Name__c 
                                                                   FROM Clipper_Inventory_Setting__mdt];
        for(Clipper_Inventory_Setting__mdt clipperSetting : clipperSettingList){
            rtToCalcWAC.put(clipperSetting.Record_Type_Developer_Name__c,clipperSetting.Calculate_Weighted_AverageCost__c);
        }
        
        
        for(Purchase_Order_Products_Received_bric__c poprItem : poprList){
            /**
             * @description Added Stock Transfer RT check for Orders
             * @date Apr-12-2024
             * @author JP Sulit jp@bricoleurtech.com
             */
            if(poprItem.Order_Product_bric__r?.Order?.RecordTypeId != stockTransferRecordTypeId) {//START
                Product2 prodItem = new Product2();
                prodItem.Id = grnLineItemToProduct.get(poprItem.Id);
                if(prodItem.Id != null){
                    Decimal weightedAvgCost = prodMap.get(prodItem.Id)?.Weighted_Average_Cost__c == null ? 0 : prodMap.get(prodItem.Id)?.Weighted_Average_Cost__c;
                    Decimal totalStock = prodMap.get(prodItem.Id)?.Total_Stock__c == null ? 0 : prodMap.get(prodItem.Id)?.Total_Stock__c;
                    Decimal convFactor = 1;
                    
                    if(supplierConvFactor.get(poprItem.Product_bric__c) != null) convFactor = supplierConvFactor.get(poprItem.Product_bric__c);
                    if( totalStock < 0){
                        prodItem.Weighted_Average_Cost__c = poprItem.Last_Cost__c/convFactor;
                    }else{              
                        System.debug('weightedAvgCost bric '+weightedAvgCost);
                        System.debug('totalStock bric '+totalStock);
                        System.debug('poprItem.Last_Cost__c bric '+poprItem.Last_Cost__c);
                        System.debug('poprItem.Amount_Received__c bric '+poprItem.Amount_Received__c);
                        System.debug('convFactor bric '+convFactor);
                        prodItem.Weighted_Average_Cost__c = ((weightedAvgCost * totalStock) + (poprItem.Last_Cost__c * poprItem.Amount_Received__c)) / (totalStock + (poprItem.Amount_Received__c * convFactor));
                    }
                    
                    if(rtToCalcWAC.get(poprItem.Order_Product_bric__r?.Order?.RecordType.DeveloperName)){
                        productList.add(prodItem);
                    }
                }
            }//END
        }
        map<id,product2> prodMapForUpdate = new map<id,product2>();
        
        //put all the values from the list to map. 
        prodMapForUpdate.putall(productList);
        if(prodMapForUpdate.size()>0){
            update prodMapForUpdate.values();
        }
            //update productList;    
        
        calculateInStockLocationProduct(locIds,prodIds,locProdKeys);
    }       
    
}