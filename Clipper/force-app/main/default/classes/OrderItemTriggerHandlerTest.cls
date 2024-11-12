@isTest
public class OrderItemTriggerHandlerTest {
    
    public static final Id salesOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
    public static final Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
    
    @testSetup static void setup(){
                
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(Name='Test Product', ProductCode= 'ABC');
        insert prod;
        
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
        
        Order salesOrderRecord = new Order();
        salesOrderRecord.AccountId = acc.Id;
        salesOrderRecord.EffectiveDate = Date.today();
        salesOrderRecord.RecordTypeId = salesOrderRecordTypeId;
        salesOrderRecord.Status = 'Draft';
        salesOrderRecord.Pricebook2Id = standardPricebookId;
        salesOrderRecord.Inventory_Location__c = locationRecord.Id;
        insert salesOrderRecord;
        
        Order purchaseOrderRecord = new Order();
        purchaseOrderRecord.AccountId = acc.Id;
        purchaseOrderRecord.EffectiveDate = Date.today();
        purchaseOrderRecord.RecordTypeId = purchaseOrderRecordTypeId;
        purchaseOrderRecord.Status = 'Draft';
        purchaseOrderRecord.Pricebook2Id = standardPricebookId;
        purchaseOrderRecord.Inventory_Location__c = locationRecord.Id;
        insert purchaseOrderRecord;
        
        Inventory_Movement__c invMovement = new Inventory_Movement__c(Product__c = prod.Id, Location__c = locationRecord.Id, Movement__c = 100);
        insert invMovement;
        
    }
    
    static testMethod void insertOrderItem_Test(){
        
        Product2 prod = [SELECT Id from Product2];
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order salesOrder = [SELECT Id,RecordTypeId,Pricebook2Id from Order WHERE RecordTypeId =: salesOrderRecordTypeId LIMIT 1];
        Order purchaseOrder = [SELECT Id,RecordTypeId,Pricebook2Id from Order WHERE RecordTypeId =: purchaseOrderRecordTypeId LIMIT 1];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        salesOrder.Pricebook2Id = standardPricebookId;
        purchaseOrder.Pricebook2Id = standardPricebookId;
        update salesOrder;
        update purchaseOrder;
        
        Test.startTest();
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = salesOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 10;
        insert ordItem;
               
        //PurchaseOrder
        OrderItem purchaseOrdItem = new OrderItem();
        purchaseOrdItem.OrderId = purchaseOrder.Id;
        purchaseOrdItem.PricebookEntryId = pbe.Id;
        purchaseOrdItem.Quantity = 1;
        purchaseOrdItem.UnitPrice = 20;
        insert purchaseOrdItem;
        
        purchaseOrdItem.Quantity = 2;
        update purchaseOrdItem;
        Test.stopTest();
        
    }
    
    static testMethod void updateOrderItem_Test(){
        
        Product2 prod = [SELECT Id from Product2];
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order salesOrder = [SELECT Id,RecordTypeId,Pricebook2Id from Order WHERE RecordTypeId =: salesOrderRecordTypeId];
        Order purchaseOrder = [SELECT Id,RecordTypeId,Pricebook2Id from Order WHERE RecordTypeId =: purchaseOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        salesOrder.Pricebook2Id = standardPricebookId;
        purchaseOrder.Pricebook2Id = standardPricebookId;
        update salesOrder;
        update purchaseOrder;
        
        Test.startTest();
        //SalesOrder
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = salesOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        ordItem.Quantity = 2;
        update ordItem;
        
        //PurchaseOrder
        OrderItem purchaseOrdItem = new OrderItem();
        purchaseOrdItem.OrderId = purchaseOrder.Id;
        purchaseOrdItem.PricebookEntryId = pbe.Id;
        purchaseOrdItem.Location__c = locProd.Location__c;
        purchaseOrdItem.Quantity = 1;
        purchaseOrdItem.UnitPrice = 20;
        insert purchaseOrdItem;
        
        purchaseOrdItem.Quantity = 2;
        update purchaseOrdItem;
        Test.stopTest();
        
    }
    
    static testMethod void deleteOrderItem_Test(){
        
        Product2 prod = [SELECT Id from Product2];
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order salesOrder = [SELECT Id,RecordTypeId from Order WHERE RecordTypeId =: salesOrderRecordTypeId];
        
        Test.startTest();
        //SalesOrder
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = salesOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        delete ordItem;
        Test.stopTest();
        
    }
}