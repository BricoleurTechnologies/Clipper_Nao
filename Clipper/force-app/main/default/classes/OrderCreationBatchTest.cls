@isTest(seeAllData=true)
private class OrderCreationBatchTest {
    
    @isTest
    static void testOrderCreationBatch() {
        // Set up necessary data and record types for the test
        Id salesOrderTemplateRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order_Template' AND SObjectType = 'Order' LIMIT 1].Id;
        system.debug('salesOrderTemplateRTId--->'+salesOrderTemplateRTId);
        // Create an Account and Contacts
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact billToContact = new Contact(LastName = 'Bill To Contact', AccountId = acc.Id);
        insert billToContact;
        
        Contact shipToContact = new Contact(LastName = 'Ship To Contact', AccountId = acc.Id);
        insert shipToContact;
        
        // Create an Order Template that meets the batch criteria
        Order orderTemplate = new Order(
            AccountId = acc.Id,
            BillToContactId = billToContact.Id,
            ShipToContactId = shipToContact.Id,
            Next_Recurring_Order_Date__c = Date.today(),
            Generate_Draft_Order_Days_Prior__c = 2,
            Description = 'Template Order Description',
            Type = 'Recurring',
            Pricebook2Id = Test.getStandardPricebookId(),
            Recurring__c = true,
            Snooze_Order__c = false,
            Recurrence_Frequency__c= 'Daily',
            EffectiveDate= Date.today() - 5,
            Status = 'Draft',
            RecordTypeId = salesOrderTemplateRTId
        );
        insert orderTemplate;
        
        // Create a Product for Order Items
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;
        
        // Create an Order Line Item for the template
        OrderItem orderItem = new OrderItem(
            OrderId = orderTemplate.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            Quantity = 1,
            PricebookEntryId = pricebookEntry.Id
        );
        insert orderItem;
        // Define the batch class instance
        OrderCreationBatch batch = new OrderCreationBatch();

        // Test the batch execution
        Test.startTest();
        // Run the batch 
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
    }
    
}