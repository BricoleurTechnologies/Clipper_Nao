@isTest
public class InventoryMovementTriggerHandlerTest {
    
    @testSetup static void setup(){
        
        Id standardPricebookId = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name='Test Product', ProductCode= 'ABC');
        insert prod;
        
        Schema.Location locationRecord = new Schema.Location();
        locationRecord.Name = 'Warehouse';
        locationRecord.LocationType = 'Warehouse';
        insert locationRecord;
        
        Location_Product__c locProd = new Location_Product__c();
        locProd.Product__c = prod.Id;
        locProd.Location__c = locationRecord.Id;
        insert locProd;        
                    
        Inventory_Movement__c invMovement = new Inventory_Movement__c(Product__c = prod.Id, Movement__c = 100, Location__c = locationRecord.Id);
        insert invMovement;   
        
    }
    
    static testMethod void insertInventoryMovement_Test(){
        
        Product2 prod = [SELECT Id from Product2];
        List<Id> ids = new List<Id>{prod.id};
            
		Inventory_Movement__c invMovement = [SELECT Id,Location__c FROM Inventory_Movement__c LIMIT 1];
        
        Test.startTest();            
        Inventory_Movement__c newInvMovement = new Inventory_Movement__c(Product__c = prod.Id, Movement__c = 100, Location__c = invMovement.Location__c);
        insert newInvMovement;   
        Test.stopTest();
        
    }
    
    static testMethod void updateInventoryMovement_Test(){
        
        Product2 prod = [SELECT Id from Product2];
        List<Id> ids = new List<Id>{prod.id};
            
        Inventory_Movement__c invMovement = [SELECT Id,Location__c FROM Inventory_Movement__c LIMIT 1];
        
        Test.startTest();  
        invMovement.Movement__c = 20;
        update invMovement;
        Test.stopTest();
        
    }
}