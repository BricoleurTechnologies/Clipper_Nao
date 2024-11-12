public without sharing class ClipperSettingUtility {
    
    public static String getStockTransferRecordTypeDevName(){
        
        Clipper_Inventory_Setting__mdt clipperSetting = [SELECT Id,Stock_Transfer_Record_Type__c, Record_Type_Developer_Name__c 
                                                         FROM Clipper_Inventory_Setting__mdt
                                                        WHERE Stock_Transfer_Record_Type__c = TRUE LIMIT 1];
        
        return clipperSetting?.Record_Type_Developer_Name__c;
    }

    /*Created by: JP Sulit (jp@bricoleurtech.com)
        Created Date: Feb 12, 2024
        Description: Returns date value from Ignore_Orders_before_Activation_Date__c field in NAO ERP Custom Setting
    */  
    public static NAO_ERP_Custom_Settings__c getOrderDateSettings() {
        NAO_ERP_Custom_Settings__c naoErpDate = NAO_ERP_Custom_Settings__c.getValues('Order Date Settings');
        return naoErpDate;
    }

    /*Created by: JP Sulit (jp@bricoleurtech.com)
    Created Date: Feb 7, 2024
    Description: Returns a unique list of Product Ids from GRN 
    */    
    public static Map<Id, Set<String>> getCompletedGrnProducts(List<Goods_Received_Notice_bric__c> grnList) { 
        
        // Set<String> grnIdSet = new Set<String>();
        Map<Id, Set<String>> completedProductsMap = new Map<Id, Set<String>>();
        List<Purchase_Order_Products_Received_bric__c> listGrnLine = new List<Purchase_Order_Products_Received_bric__c>();

        /*for(Goods_Received_Notice_bric__c grn : grnNewMap.values()) {
            if(grn.Status__c != grnOldMap.get(grn.Id).Status__c && grn.Status__c == 'Completed' && grn.Order_Record_Type_Name_Bric__c == 'Purchase_Order') {
                grnIdSet.add(grn.Id);
            }
        }*/

        Date naoErpDate = getOrderDateSettings()?.Ignore_Purchase_Orders_Before_Activation__c;

        if(naoErpDate != null) {
            listGrnLine = [SELECT Id, 
                                    Goods_Received_Notice_bric__c,
                                    Product_Bric__c,
                                    Goods_Received_Notice_bric__r.Order_Warehouse_Location__c 
                                    FROM Purchase_Order_Products_Received_bric__c
                                    WHERE Goods_Received_Notice_bric__c IN : grnList
                                    AND Amount_Received__c > 0
                                    AND Goods_Received_Notice_bric__r.Order_Bric__r.ActivatedDate >=: naoErpDate
                                    AND Product_bric__r.Inventory_Status__c != 'Non-Stock Item'];
        }
        else {
            listGrnLine = [SELECT Id, 
                                    Goods_Received_Notice_bric__c,
                                    Product_Bric__c,
                                    Goods_Received_Notice_bric__r.Order_Warehouse_Location__c 
                                    FROM Purchase_Order_Products_Received_bric__c
                                    WHERE Goods_Received_Notice_bric__c IN : grnList
                                    AND Amount_Received__c > 0
                                    AND Product_bric__r.Inventory_Status__c != 'Non-Stock Item'];
        }

        for(Purchase_Order_Products_Received_bric__c grnLine : listGrnLine) {
            
            if(!completedProductsMap.containsKey(grnLine.Goods_Received_Notice_bric__c)) {
                completedProductsMap.put(grnLine.Goods_Received_Notice_bric__c, new Set<String> {grnLine.Product_Bric__c});
            }
            else {
                completedProductsMap.get(grnLine.Goods_Received_Notice_bric__c).add(grnLine.Product_Bric__c);
            }
        }
        return completedProductsMap;
    }
    

    public static Map<Id, Set<String>> getCompletedOrderProducts(Set<Id> orderIdSet) {

        Map<Id, Set<String>> completedProductsMap = new Map<Id, Set<String>>();
        List<OrderItem> listOi = new List<OrderItem>();

        /*for(Order o : orderNewMap.values()) {
            if(o.Completed__c != orderOldMap.get(o.Id).Completed__c && o.Completed__c == true && o.Record_Type_Name_Bric__c == 'Purchase_Order') {
                orderIdSet.add(o.Id);
            }
        }*/

        Date naoErpDate = getOrderDateSettings()?.Ignore_Purchase_Orders_Before_Activation__c;

        listOi = [SELECT Id, Quantity, OrderId, Product2Id, Order.Inventory_Location__c FROM OrderItem
                    WHERE OrderId IN : orderIdSet];

        for(OrderItem oi : listOi) {

            if(!completedProductsMap.containsKey(oi.OrderId)) {
                completedProductsMap.put(oi.OrderId, new Set<String> {oi.Product2Id});
            }
            else {
                completedProductsMap.get(oi.OrderId).add(oi.Product2Id);
            }
        }

        return completedProductsMap;
    }

    public static Map<Id, Decimal> getStdProdIdMap(Map<Id, Set<String>> completedProductsMap) {
        
        Set<String> productIdSet = new Set<String>();
        Map<Id, Decimal> stdProductMap = new Map<Id, Decimal>();
        System.debug('getStdProdIdMap completedProductsMap bric '+completedProductsMap.keySet());
        for(String key : completedProductsMap.keySet()) {
            productIdSet.addAll(completedProductsMap.get(key));
        }
        System.debug('getStdProdIdMap productIdSet bric '+productIdSet);
        for(Product2 prod : [SELECT Id, Conversion_Factor__c FROM Product2 
                            WHERE RecordType.DeveloperName = 'Standard'
                            AND Supplier_Product__c IN : productIdSet]) {

            stdProductMap.put(prod.Id, prod.Conversion_Factor__c);
        }

        System.debug('getStdProdIdMap stdProductMap 1 bric '+stdProductMap);
        for(Product_Suppliers_bric__c ps : [SELECT Product_bric__c, Conversion_Factor__c FROM Product_Suppliers_bric__c            
        WHERE Supplier_Product_bric__c IN : productIdSet]) {
            
            if(!stdProductMap.containsKey(ps.Product_bric__c)) {
                stdProductMap.put(ps.Product_bric__c, ps.Conversion_Factor__c);
            }
        }
        
        System.debug('getStdProdIdMap stdProductMap 2 bric '+stdProductMap);
        for(Product2 prod : [SELECT Id, Conversion_Factor__c FROM Product2 
                            WHERE RecordType.DeveloperName = 'Standard'
                            AND Id IN : productIdSet
                            AND Use_This_Product_for_Re_order__c = true]) {

            if(!stdProductMap.containsKey(prod.Id)) {
                stdProductMap.put(prod.Id, 1);
            }
        }

        System.debug('getStdProdIdMap stdProductMap 3 bric '+stdProductMap);

        return stdProductMap;
    }

    public static Map<Id, Product2> getSupplierProductsMap(Map<Id, Decimal> stdProductMap) {

        Set<String> productIdSet = new Set<String>();
        Map<Id, Product2> supplierProdMap = new Map<Id, Product2>();
        Map<Id, Product2> standardProdMap = new Map<Id, Product2>();

        for(Product2 prod : [SELECT Supplier_Product__c, Id, Conversion_Factor__c FROM Product2 
                            WHERE RecordType.DeveloperName = 'Standard'
                            AND Id IN : stdProductMap.keySet()]) {

            // supplierProdMap.put(prod.Supplier_Product__c, prod.Conversion_Factor__c);
            supplierProdMap.put(prod.Supplier_Product__c, prod);
            standardProdMap.put(prod.Id, prod);
        }

        for(Product_Suppliers_bric__c ps : [SELECT Supplier_Product_bric__c, Product_bric__c, Conversion_Factor__c FROM Product_Suppliers_bric__c            
        WHERE Product_bric__c IN : stdProductMap.keySet()]) {
            
            if(!supplierProdMap.containsKey(ps.Supplier_Product_bric__c)) {
                // supplierProdMap.put(ps.Supplier_Product_bric__c, ps.Conversion_Factor__c);
                supplierProdMap.put(ps.Supplier_Product_bric__c, standardProdMap.get(ps.Product_bric__c));
            }
        }

        for(Product2 prod : [SELECT Id, Conversion_Factor__c FROM Product2 
                            WHERE RecordType.DeveloperName = 'Standard'
                            AND Id IN : stdProductMap.keySet()
                            AND Use_This_Product_for_Re_order__c = true]) {

            if(!supplierProdMap.containsKey(prod.Id)) {
                // supplierProdMap.put(prod.Id, 1);
                supplierProdMap.put(prod.Supplier_Product__c, prod);
            }
        }

        System.debug('getSupplierProductsMap supplierProdMap 3 bric '+supplierProdMap);
        return supplierProdMap;
    }

    /*Created by: JP Sulit (jp@bricoleurtech.com)   
    Created Date: Feb 22, 2024
    Description: Gets conversion factor from Product and Product Supplier
    */
    public static Map<Id, Decimal> getSupProdConversionFactorMap(Map<Id, Decimal> stdProductMap) {

        Set<String> productIdSet = new Set<String>();
        Map<Id, Decimal> supplierProdMap = new Map<Id, Decimal>();
        Map<Id, Product2> standardProdMap = new Map<Id, Product2>();

        for(Product2 prod : [SELECT Supplier_Product__c, Id, Conversion_Factor__c FROM Product2 
                            WHERE RecordType.DeveloperName = 'Standard'
                            AND Id IN : stdProductMap.keySet()]) {

            supplierProdMap.put(prod.Supplier_Product__c, prod.Conversion_Factor__c);
            standardProdMap.put(prod.Id, prod);
        }

        System.debug('getSupProdConversionFactorMap supplierProdMap 1 '+supplierProdMap);

        for(Product_Suppliers_bric__c ps : [SELECT Supplier_Product_bric__c, Product_bric__c, Conversion_Factor__c FROM Product_Suppliers_bric__c            
        WHERE Product_bric__c IN : stdProductMap.keySet()]) {
            
            if(!supplierProdMap.containsKey(ps.Supplier_Product_bric__c)) {
                System.debug('getSupProdConversionFactorMap has product supplier bric ');
                supplierProdMap.put(ps.Supplier_Product_bric__c, ps.Conversion_Factor__c);
            }
        }

        System.debug('getSupProdConversionFactorMap supplierProdMap 2 '+supplierProdMap);

        for(Product2 prod : [SELECT Id, Conversion_Factor__c FROM Product2 
                            WHERE RecordType.DeveloperName = 'Standard'
                            AND Id IN : stdProductMap.keySet()
                            AND Use_This_Product_for_Re_order__c = true]) {

            if(!supplierProdMap.containsKey(prod.Id)) {
                supplierProdMap.put(prod.Id, 1);
            }
        }

        System.debug('getSupProdConversionFactorMap supplierProdMap bric 3 '+supplierProdMap);
        return supplierProdMap;
    }

    public static Map<Id, List<OrderItem>> getPurchaseOrderLineMap(Map<Id, Product2> supplierProdMap) {

        Map<Id, List<OrderItem>> purchaseOrderLineMap = new Map<Id, List<OrderItem>>();    
        List<OrderItem> listOi = new List<OrderItem>();        

        Date naoErpDate = getOrderDateSettings()?.Ignore_Purchase_Orders_Before_Activation__c;

        if(naoErpDate != null) {
            listOi = [SELECT Product2Id, OrderId, Id, Quantity FROM OrderItem 
                        WHERE Order.StatusCode = 'Activated'
                        AND Order.Completed__c = FALSE
                        AND Product2Id IN : supplierProdMap.keySet()
                        AND Order.RecordType.DeveloperName  = 'Purchase_Order'
                        AND Order.ActivatedDate >=: naoErpDate];
        }
        else {
            listOi = [SELECT Product2Id, OrderId, Id, Quantity FROM OrderItem 
                        WHERE Order.StatusCode = 'Activated'
                        AND Order.Completed__c = FALSE
                        AND Product2Id IN : supplierProdMap.keySet()
                        AND Order.RecordType.DeveloperName  = 'Purchase_Order'];
        }

        for(OrderItem oi : listOi) {
            
            if(!purchaseOrderLineMap.containsKey(oi.OrderId)) {
                purchaseOrderLineMap.put(oi.OrderId, new List<OrderItem>{oi});
            }
            else {
                purchaseOrderLineMap.get(oi.OrderId).add(oi);
            }
        }
        return purchaseOrderLineMap;
    }

    public static Map<Id, Purchase_Order_Products_Received_bric__c> getGrnLineRcvdMap(Map<Id, List<OrderItem>> purchaseOrderLineMap) {
        
        Set<String> orderProductIdSet = new Set<String>();
    
        for(String key : purchaseOrderLineMap.keySet()) {
            for(OrderItem oi : purchaseOrderLineMap.get(key)) {
                orderProductIdSet.add(oi.Id);
            }
        }

        Date naoErpDate = getOrderDateSettings()?.Ignore_Purchase_Orders_Before_Activation__c;
        Map<Id, Purchase_Order_Products_Received_bric__c> grnLineMap;

        if(naoErpDate != null) {
            grnLineMap = new Map<Id, Purchase_Order_Products_Received_bric__c>([SELECT Order_Product_bric__c, 
                                                                                        Product_bric__c, 
                                                                                        Amount_Received__c 
                                                                                        FROM Purchase_Order_Products_Received_bric__c
                                                                                        WHERE Order_Product_bric__c IN : orderProductIdSet
                                                                                        AND Order_Product_bric__r.Order.ActivatedDate >=: naoErpDate]);
        }
        else {
            grnLineMap = new Map<Id, Purchase_Order_Products_Received_bric__c>([SELECT Order_Product_bric__c, 
                                                                                        Product_bric__c, 
                                                                                        Amount_Received__c 
                                                                                        FROM Purchase_Order_Products_Received_bric__c
                                                                                        WHERE Order_Product_bric__c IN : orderProductIdSet]);
        }

        return grnLineMap;
    }

    public static Map<String, Decimal> getPurchaseOrderProductTotals(Map<Id, Product2> supplierProdMap) {
        
        Map<String, Decimal> purchaseOrderProductTotalsMap = new Map<String, Decimal>();
        List<AggregateResult> arList = new List<AggregateResult>();

        Date naoErpDate = getOrderDateSettings()?.Ignore_Purchase_Orders_Before_Activation__c;

        if(naoErpDate != null) {
            arList = [SELECT Product2Id, Order.Inventory_Location__c locId, SUM(Quantity) totalQty FROM OrderItem 
                            WHERE Order.StatusCode = 'Activated'
                            AND Order.Completed__c = FALSE
                            AND Product2Id IN : supplierProdMap.keySet()
                            AND Order.RecordType.DeveloperName  = 'Purchase_Order'
                            AND Order.ActivatedDate >=: naoErpDate
                            GROUP BY Product2Id, Order.Inventory_Location__c];
        }
        else {
            arList = [SELECT Product2Id, Order.Inventory_Location__c locId, SUM(Quantity) totalQty FROM OrderItem 
                            WHERE Order.StatusCode = 'Activated'
                            AND Order.Completed__c = FALSE
                            AND Product2Id IN : supplierProdMap.keySet()
                            AND Order.RecordType.DeveloperName  = 'Purchase_Order'
                            GROUP BY Product2Id, Order.Inventory_Location__c];
        }
        
        for(AggregateResult ar : arList) {
            
            String prodId = (String) ar.get('Product2Id');
            String warehouseId = (String) ar.get('locId');
            purchaseOrderProductTotalsMap.put(warehouseId+';'+prodId, (Decimal) ar.get('totalQty'));
        }
        return purchaseOrderProductTotalsMap;
    }

    public static Map<String, Decimal> getGrnLineProductTotals(Map<Id, List<OrderItem>> purchaseOrderLineMap) {

        Map<String, Decimal> grnLineProductTotalsMap = new Map<String, Decimal>();
        Set<String> orderProductIdSet = new Set<String>();
        List<AggregateResult> arList = new List<AggregateResult>();

        for(String key : purchaseOrderLineMap.keySet()) {
            for(OrderItem oi : purchaseOrderLineMap.get(key)) {
                orderProductIdSet.add(oi.Id);
            }
        }
        System.debug('grnLine bric getGrnLineProductTotals orderProductIdSet bric '+orderProductIdSet);
        Date naoErpDate = getOrderDateSettings()?.Ignore_Purchase_Orders_Before_Activation__c;

        if(naoErpDate != null) {
            arList = [SELECT Product_bric__c, Goods_Received_Notice_bric__r.Order_bric__r.Inventory_Location__c locId,
                            SUM (Amount_Received__c) totalAmtRcvd 
                            FROM Purchase_Order_Products_Received_bric__c
                            WHERE Order_Product_bric__c IN : orderProductIdSet
                            AND Goods_Received_Notice_bric__r.Status__c = 'Completed'
                            AND Order_Product_bric__r.Order.ActivatedDate >=: naoErpDate
                            GROUP BY Product_bric__c, Goods_Received_Notice_bric__r.Order_bric__r.Inventory_Location__c];
        }
        else {
            arList = [SELECT Product_bric__c prod, Goods_Received_Notice_bric__r.Order_bric__r.Inventory_Location__c locId,
                            SUM (Amount_Received__c) totalAmtRcvd 
                            FROM Purchase_Order_Products_Received_bric__c
                            WHERE Order_Product_bric__c IN : orderProductIdSet
                            AND Goods_Received_Notice_bric__r.Status__c = 'Completed'
                            GROUP BY Product_bric__c, Goods_Received_Notice_bric__r.Order_bric__r.Inventory_Location__c];
        }
        System.debug('getGrnLineProductTotals arList bric '+arList);
        for(AggregateResult ar : arList) {
            
            String prodId = (String) ar.get('prod');
            String warehouseId = (String) ar.get('locId');
            grnLineProductTotalsMap.put(warehouseId+';'+prodId, (Decimal) ar.get('totalAmtRcvd'));
        }

        return grnLineProductTotalsMap;
    }

    /*Created by: JP Sulit (jp@bricoleurtech.com)   
    Created Date: Feb 20, 2024
    */
    public static Set<String> getLocStdProd(Map<Id, Set<String>> completedOrderProductsMap, Map<Id, Product2> supplierProductsMap) {
        Set<String> locStdProdSet = new Set<String>();
        for(Order o : [SELECT Inventory_Location__c, (SELECT Product2Id FROM OrderItems) FROM Order WHERE Id IN : completedOrderProductsMap.keySet()]) {
            if(!o.OrderItems.isEmpty()) {
                System.debug('has order');
                for(OrderItem oi : o.OrderItems) {
                    System.debug('getLocStdProd supplier product id bric '+oi.Product2Id);
                    if(supplierProductsMap.containsKey(oi.Product2Id) && supplierProductsMap.get(oi.Product2Id) != null) {
                        String key = o.Inventory_Location__c+';'+supplierProductsMap.get(oi.Product2Id).Id;
                        System.debug('getLocStdProd key bric '+key);
                        locStdProdSet.add(key);
                    } 
                }
            }
        }
        return locStdProdSet;
    }

    /*Created by: JP Sulit (jp@bricoleurtech.com)   
    Created Date: Feb 12, 2024
    */
    public static void calcTotalPurchaseOrders(Map<Id, Set<String>> completedOrderProductsMap) {
        
        Map<Id, Decimal> standardProductsMap = getStdProdIdMap(completedOrderProductsMap);
        /*Created by: JP Sulit (jp@bricoleurtech.com)   
        Created Date: Feb 20, 2024
        */
        //START
        Map<Id, Decimal> supProdConvFactorMap = getSupProdConversionFactorMap(standardProductsMap);
        //END
        Map<Id, Product2> supplierProductsMap = getSupplierProductsMap(standardProductsMap);
        Map<Id, List<OrderItem>> purchaseOrderLineMap = getPurchaseOrderLineMap(supplierProductsMap);
        Map<Id, Purchase_Order_Products_Received_bric__c> grnLineRcvdMap = getGrnLineRcvdMap(purchaseOrderLineMap);
        Map<String, Decimal> purchaseOrderProductTotalsMap = getPurchaseOrderProductTotals(supplierProductsMap);
        Map<String, Decimal> grnLineProductTotalsMap = getGrnLineProductTotals(purchaseOrderLineMap);

        Map<String, Decimal> openPurchaseOrderTotalMap = new Map<String, Decimal>();
        Map<String, Decimal> openPurchaseOrderTotalStdMap = new Map<String, Decimal>();
        List<Location_Product__c> locProductToUpdate = new List<Location_Product__c>();

        System.debug('calcTotalPurchaseOrders supplierProductsMap bric '+supplierProductsMap);
        System.debug('calcTotalPurchaseOrders purchaseOrderProductTotalsMap bric '+purchaseOrderProductTotalsMap);
        System.debug('calcTotalPurchaseOrders grnLineProductTotalsMap bric '+grnLineProductTotalsMap);

        /*Created by: JP Sulit (jp@bricoleurtech.com)   
        * Created Date: Feb 20, 2024
        */
        //START
        Map<String, Product2> standardProductMapToUpdate = new Map<String, Product2>([SELECT Id, Total_Purchase_Orders__c FROM Product2 WHERE Id IN : standardProductsMap.keySet()]);
        //END

        for(String key : purchaseOrderProductTotalsMap.keySet()) {
            Decimal purchaseOrderTotal = 0;
            if(grnLineProductTotalsMap.containsKey(key)) {
                purchaseOrderTotal = purchaseOrderProductTotalsMap.get(key) - grnLineProductTotalsMap.get(key);
                openPurchaseOrderTotalMap.put(key, purchaseOrderTotal);
            }
            else {
                purchaseOrderTotal = purchaseOrderProductTotalsMap.get(key);
                openPurchaseOrderTotalMap.put(key, purchaseOrderTotal);
            }
        }

        System.debug('calcTotalPurchaseOrders openPurchaseOrderTotalMap bric 1 '+openPurchaseOrderTotalMap);

        for(String key : openPurchaseOrderTotalMap.keySet()) {
            String warehouseId = key.split(';')[0];
            String prodId = key.split(';')[1];

            if(supplierProductsMap.containsKey(prodId) && supProdConvFactorMap.containsKey(prodId)) {
                Decimal conversionFactor = supProdConvFactorMap.get(prodId);
                /*Updated by: JP Sulit (jp@bricoleurtech.com)   
                * Updated Date: Feb 26, 2024
                * Description: Added null checking on supplierProductsMap to get the standard product id
                */
                //START
                Id standardProductId = supplierProductsMap.containsKey(prodId) && supplierProductsMap.get(prodId) != null?supplierProductsMap.get(prodId).Id:null;
                //END
                System.debug('supplier product id bric '+prodId);
                System.debug('conversionFactor bric '+conversionFactor);
                System.debug('standardProductId bric '+standardProductId);
                System.debug('warehouseId bric '+warehouseId);
                /*Updated by: JP Sulit (jp@bricoleurtech.com)   
                * Updated Date: Feb 26, 2024
                * Description: Performed conversion factor null checking
                */
                //START
                if(conversionFactor != null && standardProductId != null) {
                    openPurchaseOrderTotalStdMap.put(warehouseId+';'+standardProductId, openPurchaseOrderTotalMap.get(key) * conversionFactor);
                }
                //END
                    // standardProductMapToUpdate.put(standardProductId, supplierProductsMap.get(prodId));
            }
        }

        System.debug('calcTotalPurchaseOrders openPurchaseOrderTotalStdMap bric '+openPurchaseOrderTotalStdMap);
        System.debug('calcTotalPurchaseOrders standardProductMapToUpdate bric '+standardProductMapToUpdate);


        /*Created by: JP Sulit (jp@bricoleurtech.com)   
        * Created Date: Feb 20, 2024
        */
        //START
        Set<String> locStdProdSet = getLocStdProd(completedOrderProductsMap, supplierProductsMap);
        System.debug('locStdProdSet bric '+locStdProdSet);

        for(String key : locStdProdSet) {
            if(!openPurchaseOrderTotalStdMap.containsKey(key)) {
                openPurchaseOrderTotalStdMap.put(key, 0);
            }
        }
        //END
        System.debug('openPurchaseOrderTotalStdMap checked bric '+openPurchaseOrderTotalStdMap);
        /*Created by: JP Sulit (jp@bricoleurtech.com)   
        * Created Date: Feb 20, 2024
        */
        //START
        Set<String> locProdKeySet = new Set<String>();

        if(!openPurchaseOrderTotalStdMap.keySet().isEmpty()) {
            locProdKeySet.addAll(openPurchaseOrderTotalStdMap.keySet());
        }
        else {
            locProdKeySet.addAll(openPurchaseOrderTotalMap.keySet());
        }
        //END

        System.debug('locProdKeySet bric '+locProdKeySet);

        for(Location_Product__c locProd : [SELECT Id, Product__c, Total_Purchase_Orders__c,Location_Product_Key_Bric__c
                                            FROM Location_Product__c WHERE
                                            Location_Product_Key_Bric__c IN : locProdKeySet]) {
            /*Created by: JP Sulit (jp@bricoleurtech.com)   
            * Created Date: Feb 20, 2024
            */
            //START
            Decimal totalPO = !openPurchaseOrderTotalStdMap.isEmpty()?openPurchaseOrderTotalStdMap.get(locProd.Location_Product_Key_Bric__c):openPurchaseOrderTotalMap.get(locProd.Location_Product_Key_Bric__c);
            System.debug('calcTotalPurchaseOrders totalPO bric '+totalPO);
            locProd.Total_Purchase_Orders__c = totalPO;
            //END
            System.debug('calcTotalPurchaseOrders Total_Purchase_Orders__c bric '+locProd.Total_Purchase_Orders__c);
            locProductToUpdate.add(locProd);
            System.debug('openPurchaseOrderTotalStdMap.get(locProd.Location_Product_Key_Bric__c) bric '+openPurchaseOrderTotalStdMap.get(locProd.Location_Product_Key_Bric__c));
            System.debug('locProd.Product__c bric '+locProd.Product__c);
            standardProductMapToUpdate.get(locProd.Product__c).Total_Purchase_Orders__c = openPurchaseOrderTotalStdMap.get(locProd.Location_Product_Key_Bric__c);
        }

        System.debug('calcTotalPurchaseOrders locProductToUpdate bric '+locProductToUpdate);

        try {
            Database.update(locProductToUpdate);
            Database.update(standardProductMapToUpdate.values());
        }
        catch(Exception e){
            Utilities.CreateExceptionLog(e, 'ClipperSettingUtility: calcTotalPurchaseOrders');
        }
    }
}