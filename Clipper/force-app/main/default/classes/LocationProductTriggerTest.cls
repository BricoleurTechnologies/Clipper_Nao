@isTest
public class LocationProductTriggerTest {
    
    public static final Id salesOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
    public static final Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
    public static final Id supplierProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Supplier_Product').getRecordTypeId();
    public static final Id standardProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();

    @TestSetup
    static void testData() {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Supplier_Pricebook__c = standardPricebookId;
        insert acc;
        
        Product2 supProd = new Product2(Name='Test Supplier Product', ProductCode= 'DEF', RecordTypeId = supplierProductRecordTypeId);
        insert supProd;
        
        PricebookEntry supPbe = new PricebookEntry();
        supPbe.Product2Id = supProd.Id;
        supPbe.Pricebook2Id = standardPricebookId;
        supPbe.UnitPrice = 100;
        insert supPbe;
        
        Product2 prod = new Product2(Name='Test Product', ProductCode= 'ABC', RecordTypeId = standardProductRecordTypeId, Supplier_Product__c = supProd.Id, Conversion_Factor__c = 150);
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
        locProd.In_Stock__c = 1000;
        insert locProd;
        
        Inventory_Movement__c invMovement = new Inventory_Movement__c(Product__c = prod.Id, Location__c = locationRecord.Id, Movement__c = 100);
        insert invMovement;
    }
    private static testMethod void onAfterUpdateTest() {
        Location_Product__c locProd = [SELECT Id, Total_Sales_Orders__c FROM Location_Product__c LIMIT 1];
        locProd.Total_Sales_Orders__c = 100;

        Test.startTest();
            update locProd;
        Test.stopTest();
        
        Location_Product__c updatedLocProd = [SELECT Id, Total_Sales_Orders__c, Product__c FROM Location_Product__c WHERE Id =: locProd.Id];
        Product2 prod = [SELECT Id, Total_Available__c FROM Product2 WHERE Id =: updatedLocProd.Product__c];

        // Assert.isNull(prod.Total_Available__c);
    }
}