@isTest
public class PicklistPDFController_Test {

    public static final Id salesOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
    public static final Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
    public static final Id supplierProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Supplier_Product').getRecordTypeId();
    public static final Id standardProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
    
    @testSetup static void setup(){
        
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
        
        Product2 prod = new Product2(Name='Test Product', ProductCode= 'ABC', RecordTypeId = standardProductRecordTypeId, Supplier_Product__c = supProd.Id);
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
    
    static testMethod void generatePicklist_Test(){
        
        PicklistPDFController ext;
        List<Order> salesOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: salesOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();  
        PageReference vfPage = Page.PicklistVFPage;
        Test.setCurrentPage(vfPage);
        vfPage.getParameters().put('Id', salesOrder[0].Id);
        ApexPages.StandardSetController sc = new  ApexPages.StandardSetController(salesOrder);
        ext = new PicklistPDFController(sc);
        Test.stopTest();
        
    }
    
    static testMethod void generatePicklistBulk_Test(){
        
        PicklistPDFController ext;
        List<Order> salesOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: salesOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();  
        PageReference vfPage = Page.PicklistVFPage;
        Test.setCurrentPage(vfPage);
        vfPage.getParameters().put('recordids', salesOrder[0].Id);
        ApexPages.StandardSetController sc = new  ApexPages.StandardSetController(salesOrder);
        ext = new PicklistPDFController(sc);
        Test.stopTest();
        
    }
    
    static testMethod void savePdfAsAttachment_Test(){
        
        PicklistPDFController ext;
        List<Order> salesOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: salesOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        List<String> idList = new List<String>{salesOrder[0].Id};
            List<List<String>> params = new List<List<String>>{idList};
        
        Test.startTest();  
        PicklistPDFController.savePdfAsAttachment(params);
        Test.stopTest();
        
    }
    
    
}