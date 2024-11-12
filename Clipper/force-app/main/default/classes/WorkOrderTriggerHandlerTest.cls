@isTest
public class WorkOrderTriggerHandlerTest {
    
    public static final Id supplierProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Supplier_Product').getRecordTypeId();
    public static final Id standardProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
    
    @testSetup static void setup(){
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Supplier_Pricebook__c = standardPricebookId;
        insert acc;
        
        Product2 supProd = new Product2(Name='Test Supplier Product', ProductCode= 'DEF', RecordTypeId = supplierProductRecordTypeId, IsActive = TRUE);
        insert supProd;
        
        PricebookEntry supPbe = new PricebookEntry();
        supPbe.Product2Id = supProd.Id;
        supPbe.Pricebook2Id = standardPricebookId;
        supPbe.UnitPrice = 100;
        supPbe.IsActive = TRUE;
        insert supPbe;
        
        Product2 prod = new Product2(Name='Test Product', ProductCode= 'ABC', RecordTypeId = standardProductRecordTypeId, Supplier_Product__c = supProd.Id, IsActive = TRUE);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = prod.Id;
        pbe.Pricebook2Id = standardPricebookId;
        pbe.UnitPrice = 100;
        pbe.IsActive = TRUE;
        insert pbe;        
        
        Schema.Location locationRecord = new Schema.Location();
        locationRecord.Name = 'Warehouse';
        locationRecord.LocationType = 'Warehouse';
        insert locationRecord;
        
        Location_Product__c locProd = new Location_Product__c();
        locProd.Product__c = prod.Id;
        locProd.Location__c = locationRecord.Id;
        insert locProd;
        
        WorkOrder ordRecord = new WorkOrder();
        ordRecord.AccountId = acc.Id;
        ordRecord.Picked_bric__c = FALSE;
        ordRecord.Pricebook2Id = standardPricebookId;
        ordRecord.LocationId = locationRecord.Id;
        insert ordRecord;
        
        Inventory_Movement__c invMovement = new Inventory_Movement__c(Product__c = prod.Id, Location__c = locationRecord.Id, Movement__c = 100);
        insert invMovement;
        
    }
    
    static testMethod void updateOrder_Test(){
                
        Id standardPricebookId = Test.getStandardPricebookId();
        Product2 prod = [SELECT Id from Product2 WHERE RecordTypeId =: standardProductRecordTypeId];
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id AND Pricebook2Id =:standardPricebookId AND IsActive = TRUE];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        WorkOrder ordRecord = [SELECT Id,Picked_bric__c,Pricebook2Id,LocationId from WorkOrder LIMIT 1];
                
        Test.startTest();   
        
        WorkOrderLineItem ordItem = new WorkOrderLineItem();
        ordItem.WorkOrderId = ordRecord.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.LocationId = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        ordRecord.Picked_bric__c = TRUE;
        update ordRecord;
        Test.stopTest();
        
    }
    
}