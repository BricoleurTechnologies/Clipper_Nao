@isTest
public class OrderPdfControllerTest {
    
    @testSetup
    static void setupData() {
        // Create a test Account record
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a Product2 record
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
    
        // Retrieve the Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId());
        update standardPricebook;
        
        // Create a Standard Price for the product
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true
        );
        insert standardPbe;
    
        // Create a custom Pricebook
        Pricebook2 customPricebook = new Pricebook2(Name = 'Custom Pricebook', IsActive = true);
        insert customPricebook;
        
        // Create a custom Pricebook Entry for the product
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true
        );
        insert customPbe;
        
        // Create an Order record
        Order ord = new Order(AccountId = acc.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = standardPricebook.Id);
        insert ord;
    
        // Create an OrderItem record using the custom Pricebook Entry
        OrderItem ordItem = new OrderItem(
            OrderId = ord.Id, 
            PricebookEntryId = standardPbe.Id, 
            Quantity = 1, 
            UnitPrice = 100
        );
        insert ordItem;
    }
    
    
    @isTest
    static void testOrderPdfController() {
        // Fetch the created Order record
        Order ord = [SELECT Id FROM Order LIMIT 1];
        
        // Set the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/OrderPdfPage'));
        ApexPages.currentPage().getParameters().put('sObjectType', 'Order');
        ApexPages.currentPage().getParameters().put('Id', ord.Id);
        ApexPages.currentPage().getParameters().put('childSObjectType', 'OrderItem'); // Assuming OrderItem as the child object
        
        // Instantiate the controller
        OrderPdfController controller = new OrderPdfController();
        
        // Perform assertions to validate the functionality
        System.assertNotEquals(null, controller.recordList, 'recordList should not be null');
        System.assertEquals(1, controller.recordList.size(), 'recordList should have one order');
        System.assertEquals(ord.Id, controller.recordList[0].Id, 'The ID of the order should match');
    }

}