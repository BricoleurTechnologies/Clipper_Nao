@isTest
public class ScheduleOrderCreationTest {
    
    @testSetup
    static void setupData() {
        // Set up test data 
        Id salesOrderTemplateRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order_Template' AND SObjectType = 'Order' LIMIT 1].Id;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact billToContact = new Contact(LastName = 'Bill To Contact', AccountId = acc.Id);
        insert billToContact;
        
        Contact shipToContact = new Contact(LastName = 'Ship To Contact', AccountId = acc.Id);
        insert shipToContact;
        
        Pricebook2 pricebook = new Pricebook2(Name = 'Standard Pricebook', IsActive = true);
        insert pricebook;
        
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
        
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;
        
        OrderItem orderItem = new OrderItem(
            OrderId = orderTemplate.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            Quantity = 1,
            PricebookEntryId = pricebookEntry.Id
        );
        insert orderItem;
    }
    
    @isTest
    static void testScheduleOrderCreation() {
        // Schedule the job
        String cronExpression = '0 0 4 * * ?'; // Schedule to run daily at 4 AM
        ScheduleOrderCreation schedulableClass = new ScheduleOrderCreation();
        
        Test.startTest();
        String jobId = System.schedule('Test Order Creation Schedule Job', cronExpression, schedulableClass);
        
        // Check that the job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpression, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        
        Test.stopTest();
    }
}