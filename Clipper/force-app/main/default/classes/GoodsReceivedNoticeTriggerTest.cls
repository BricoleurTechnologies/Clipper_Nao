@isTest
public class GoodsReceivedNoticeTriggerTest {
    
    public static final Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
    public static final Id supplierProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Supplier_Product').getRecordTypeId();
    public static final Id standardProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();

    public static final Id stockTransferRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(ClipperSettingUtility.getStockTransferRecordTypeDevName()).getRecordTypeId();
  
    
    @testSetup static void setup(){
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Supplier_Pricebook__c = standardPricebookId;
        acc.Type = 'Supplier';
        insert acc;
        
        Product2 supProd = new Product2(Name='Test Supplier Product', ProductCode= 'DEF', RecordTypeId = supplierProductRecordTypeId);
        insert supProd;
        
        PricebookEntry supPbe = new PricebookEntry();
        supPbe.Product2Id = supProd.Id;
        supPbe.Pricebook2Id = standardPricebookId;
        supPbe.UnitPrice = 100;
        insert supPbe;
        
        Product2 prod = new Product2(Name='Test Product', ProductCode= 'ABC', RecordTypeId = standardProductRecordTypeId, Supplier_Product__c = supProd.Id);
        insert prod;
        
        Product2 supProd2 = new Product2(Name='Test Supplier Product2', ProductCode= 'GHIS', RecordTypeId = supplierProductRecordTypeId);
        insert supProd2;
        
        PricebookEntry supPbe2 = new PricebookEntry();
        supPbe2.Product2Id = supProd2.Id;
        supPbe2.Pricebook2Id = standardPricebookId;
        supPbe2.UnitPrice = 100;
        insert supPbe2;
        
        Product_Suppliers_bric__c prodSup = new Product_Suppliers_bric__c();
        prodSup.Product_bric__c = prod.Id;
        prodSup.Conversion_Factor__c = 20;
        prodSup.Supplier_bric__c = acc.Id;
        prodSup.Supplier_Product_bric__c = supProd2.Id;
        insert prodSup;
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = prod.Id;
        pbe.Pricebook2Id = standardPricebookId;
        pbe.UnitPrice = 100;
        insert pbe;
        
        
        Schema.Location locationRecord = new Schema.Location();
        locationRecord.Name = 'Warehouse';
        locationRecord.LocationType = 'Warehouse';
        insert locationRecord;
        
        Location_Product__c locProd = new Location_Product__c();
        locProd.Product__c = prod.Id;
        locProd.Location__c = locationRecord.Id;
        insert locProd;
        
        Order purchaseOrderRecord = new Order();
        purchaseOrderRecord.AccountId = acc.Id;
        purchaseOrderRecord.EffectiveDate = Date.today();
        purchaseOrderRecord.RecordTypeId = purchaseOrderRecordTypeId;
        purchaseOrderRecord.Status = 'Draft';
        purchaseOrderRecord.Pricebook2Id = standardPricebookId;
        purchaseOrderRecord.Inventory_Location__c = locationRecord.Id;
        insert purchaseOrderRecord;
        
        OrderItem purchaseOrderItemRecord = new OrderItem();
        purchaseOrderItemRecord.OrderId = purchaseOrderRecord.Id;
        purchaseOrderItemRecord.PricebookEntryId = supPbe.Id;
        purchaseOrderItemRecord.Location__c = locProd.Location__c;
        purchaseOrderItemRecord.Quantity = 1;
        purchaseOrderItemRecord.UnitPrice = 20;
        insert purchaseOrderItemRecord;
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = purchaseOrderRecord.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        OrderItem purchaseOrderItemRecord2 = new OrderItem();
        purchaseOrderItemRecord2.OrderId = purchaseOrderRecord.Id;
        purchaseOrderItemRecord2.PricebookEntryId = supPbe2.Id;
        purchaseOrderItemRecord2.Location__c = locProd.Location__c;
        purchaseOrderItemRecord2.Quantity = 1;
        purchaseOrderItemRecord2.UnitPrice = 20;
        insert purchaseOrderItemRecord2;
        
        Order stockTransferOrderRecord = new Order();
        stockTransferOrderRecord.AccountId = acc.Id;
        stockTransferOrderRecord.EffectiveDate = Date.today();
        stockTransferOrderRecord.RecordTypeId = stockTransferRecordTypeId;
        stockTransferOrderRecord.Status = 'Draft';
        stockTransferOrderRecord.Pricebook2Id = standardPricebookId;
        stockTransferOrderRecord.Inventory_Location__c = locationRecord.Id;
        insert stockTransferOrderRecord;

        OrderItem stOrderItemRecord = new OrderItem();
        stOrderItemRecord.OrderId = stockTransferOrderRecord.Id;
        stOrderItemRecord.PricebookEntryId = supPbe.Id;
        stOrderItemRecord.Location__c = locProd.Location__c;
        stOrderItemRecord.Quantity = 1;
        stOrderItemRecord.UnitPrice = 20;
        insert stOrderItemRecord;
        
        OrderItem stOrdItem = new OrderItem();
        stOrdItem.OrderId = stockTransferOrderRecord.Id;
        stOrdItem.PricebookEntryId = pbe.Id;
        stOrdItem.Location__c = locProd.Location__c;
        stOrdItem.Quantity = 1;
        stOrdItem.UnitPrice = 20;
        insert stOrdItem;
        
        OrderItem stOrderItemRecord2 = new OrderItem();
        stOrderItemRecord2.OrderId = stockTransferOrderRecord.Id;
        stOrderItemRecord2.PricebookEntryId = supPbe2.Id;
        stOrderItemRecord2.Location__c = locProd.Location__c;
        stOrderItemRecord2.Quantity = 1;
        stOrderItemRecord2.UnitPrice = 20;
        insert stOrderItemRecord2;

        Inventory_Movement__c invMovement = new Inventory_Movement__c(Product__c = prod.Id, Location__c = locationRecord.Id, Movement__c = 100);
        insert invMovement;

        NAO_ERP_Custom_Settings__c naoErp =  new NAO_ERP_Custom_Settings__c(Ignore_Purchase_Orders_Before_Activation__c = null,
        Ignore_SO_before_Activation_Date__c = null,
        Name = 'Order Date Settings');
        insert naoErp;

        Goods_Received_Notice_bric__c grn = new Goods_Received_Notice_bric__c(GRN_Reference_Number__c = '123',
        Order_bric__c = purchaseOrderRecord.Id,
        Status__c = 'Open');
        insert grn;

        Purchase_Order_Products_Received_bric__c grnLine =  new Purchase_Order_Products_Received_bric__c(Goods_Received_Notice_bric__c = grn.Id,
        Order_bric__c = purchaseOrderRecord.Id,
        Order_Product_bric__c = purchaseOrderItemRecord.Id,
        Product_bric__c = purchaseOrderItemRecord.Product2Id,
        Order_Quantity__c = purchaseOrderItemRecord.Quantity,
        Amount_Received__c = 0);
        insert grnLine;

        Goods_Received_Notice_bric__c grnStock = new Goods_Received_Notice_bric__c(GRN_Reference_Number__c = '123',
        Order_bric__c = stockTransferOrderRecord.Id,
        Status__c = 'Open');
        insert grnStock;

        Purchase_Order_Products_Received_bric__c grnLineStock =  new Purchase_Order_Products_Received_bric__c(Goods_Received_Notice_bric__c = grn.Id,
        Order_bric__c = stockTransferOrderRecord.Id,
        Order_Product_bric__c = stOrderItemRecord.Id,
        Product_bric__c = stOrderItemRecord.Product2Id,
        Order_Quantity__c = stOrderItemRecord.Quantity,
        Amount_Received__c = 0);
        insert grnLineStock;                                
    }
    
    static testMethod void insertGRN_Test(){
        
        Order ord = [SELECT Id FROM Order WHERE RecordTypeId =: purchaseOrderRecordTypeId LIMIT 1];
        
        Test.startTest();
        Goods_Received_Notice_bric__c grn = new Goods_Received_Notice_bric__c();
        grn.GRN_Reference_Number__c = '1234';
        grn.Order_bric__c = ord.Id;
        grn.Status__c = 'Completed';
        insert grn;        
        
        Purchase_Order_Products_Received_bric__c popr = [SELECT Id FROM Purchase_Order_Products_Received_bric__c WHERE Order_bric__c =: ord.Id LIMIT 1];
        popr.Amount_Received__c = 10;
        update popr;
        
        Test.stopTest();
        
    }
    
    static testMethod void insertGRNStockOrder_Test(){
        
        Order ord = [SELECT Id FROM Order WHERE RecordTypeId =: stockTransferRecordTypeId LIMIT 1];
        
        Test.startTest();
        Goods_Received_Notice_bric__c grn = new Goods_Received_Notice_bric__c();
        grn.GRN_Reference_Number__c = '1234';
        grn.Order_bric__c = ord.Id;
        grn.Status__c = 'Completed';
        insert grn;        
        
        Purchase_Order_Products_Received_bric__c popr = [SELECT Id FROM Purchase_Order_Products_Received_bric__c WHERE Order_bric__c =: ord.Id LIMIT 1];
        popr.Amount_Received__c = 10;
        update popr;
        
        Test.stopTest();
        
    }

    static testMethod void updateGRN_Test(){
        
        Order ord = [SELECT Id FROM Order WHERE RecordTypeId =: purchaseOrderRecordTypeId LIMIT 1];
                
        Goods_Received_Notice_bric__c grn = new Goods_Received_Notice_bric__c();
        grn.GRN_Reference_Number__c = '1234';
        grn.Order_bric__c = ord.Id;
        grn.Status__c = 'Open';
        insert grn;
        
        Goods_Received_Notice_bric__c grn2 = new Goods_Received_Notice_bric__c();
        grn2.GRN_Reference_Number__c = '5678';
        grn2.Order_bric__c = ord.Id;
        grn2.Status__c = 'Completed';
        insert grn2; 
        
        List<Purchase_Order_Products_Received_bric__c> poprList = [SELECT Id FROM Purchase_Order_Products_Received_bric__c WHERE Order_bric__c =: ord.Id];
        for(Purchase_Order_Products_Received_bric__c popr : poprList){
            popr.Amount_Received__c = 10;
        }
        
        Inventory_Movement__c invMovement= new Inventory_Movement__c();
        invMovement.Goods_Received_Notice_Line_Item__c = poprList[0].Id;
        invMovement.Order__c = ord.Id;
        insert invMovement;
        
        update poprList;
        
        Test.startTest();
        grn.Status__c = 'Completed';
        update grn;
        Test.stopTest();
        
    }

    static testMethod void updateGRNStock_Test(){
        
        Order ord = [SELECT Id FROM Order WHERE RecordTypeId =: stockTransferRecordTypeId LIMIT 1];
                
        Goods_Received_Notice_bric__c grn = new Goods_Received_Notice_bric__c();
        grn.GRN_Reference_Number__c = '1234';
        grn.Order_bric__c = ord.Id;
        grn.Status__c = 'Open';
        insert grn;
        
        Goods_Received_Notice_bric__c grn2 = new Goods_Received_Notice_bric__c();
        grn2.GRN_Reference_Number__c = '5678';
        grn2.Order_bric__c = ord.Id;
        grn2.Status__c = 'Completed';
        insert grn2; 
        
        List<Purchase_Order_Products_Received_bric__c> poprList = [SELECT Id FROM Purchase_Order_Products_Received_bric__c WHERE Order_bric__c =: ord.Id];
        for(Purchase_Order_Products_Received_bric__c popr : poprList){
            popr.Amount_Received__c = 10;
        }
        
        Inventory_Movement__c invMovement= new Inventory_Movement__c();
        invMovement.Goods_Received_Notice_Line_Item__c = poprList[0].Id;
        invMovement.Order__c = ord.Id;
        insert invMovement;
        
        update poprList;
        
        Test.startTest();
        grn.Status__c = 'Completed';
        update grn;
        Test.stopTest();
        
    }
}