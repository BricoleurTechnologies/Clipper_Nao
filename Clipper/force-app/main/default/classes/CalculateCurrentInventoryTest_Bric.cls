@isTest
public class CalculateCurrentInventoryTest_Bric {
    
    @testSetup static void setup(){
        
        Id standardPricebookId = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name='Test Product', ProductCode= 'ABC');
        insert prod;

        Inventory_Movement__c invMovement = new Inventory_Movement__c(Product__c = prod.Id, Movement__c = 100);
        insert invMovement;
        
    }
    
    static testMethod void getProductInventory_Test(){
        
        Product2 prod = [SELECT Id from Product2];
        List<Id> ids = new List<Id>{prod.id};
            
        Test.startTest();
        CalculateCurrentInventory_Bric.getProductInventory(ids);
        Test.stopTest();
        
    }
}