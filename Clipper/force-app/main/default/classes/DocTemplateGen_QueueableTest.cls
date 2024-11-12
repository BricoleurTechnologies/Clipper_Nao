@IsTest
private class DocTemplateGen_QueueableTest {
    
    @IsTest
    static void testDocTemplateGenQueueable() {
        // Step 1: Create test data
        
        // Create a test record to use with the document template generation
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create a Document_Template__c record
        Document_Template__c docTemplate = new Document_Template__c(
            VisualForce_Template__c = 'TestVisualforcePage',
            sObject__c = 'Account',
            Child_sObject__c = 'Contact',
            Template_Name__c = 'Test_Template',
            Title_Custom_Field__c = 'Name'

        );
        insert docTemplate;
        
        // Create a Request object for the Invoke_DocTemplateGen.Request
        Invoke_DocTemplateGen.Request request = new Invoke_DocTemplateGen.Request();
        request.recordId = testAccount.Id;
        request.docTemplates = new List<Document_Template__c>{docTemplate};
        
        // Step 2: Instantiate the Queueable class and pass the request list
        List<Invoke_DocTemplateGen.Request> requestList = new List<Invoke_DocTemplateGen.Request>{request};
        DocTemplateGen_Queueable queueableJob = new DocTemplateGen_Queueable(requestList);
        
        // Step 3: Enqueue the Queueable job
        Test.startTest();
        System.enqueueJob(queueableJob);
        Test.stopTest();
    }
    
    @IsTest
    static void testDocTemplateGenQueueable_EmptyDocTemplates() {
        // Test when docTemplates is empty
        
        // Create a test record to use with the document template generation
        Account testAccount = new Account(Name = 'Test Account 2');
        insert testAccount;
        
        // Create a Request object for the Invoke_DocTemplateGen.Request with an empty docTemplates list
        Invoke_DocTemplateGen.Request request = new Invoke_DocTemplateGen.Request();
        request.recordId = testAccount.Id;
        request.docTemplates = new List<Document_Template__c>();
        
        // Step 2: Instantiate the Queueable class and pass the request list
        List<Invoke_DocTemplateGen.Request> requestList = new List<Invoke_DocTemplateGen.Request>{request};
        DocTemplateGen_Queueable queueableJob = new DocTemplateGen_Queueable(requestList);
        
        // Step 3: Enqueue the Queueable job
        Test.startTest();
        System.enqueueJob(queueableJob);
        Test.stopTest();
    }
}