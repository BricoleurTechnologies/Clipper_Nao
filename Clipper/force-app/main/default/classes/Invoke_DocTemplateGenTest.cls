@IsTest
private class Invoke_DocTemplateGenTest {
    
    @IsTest
    static void testGenerateAndAttachPDF() {
        // Setup test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Document_Template__c docTemplate = new Document_Template__c(
            VisualForce_Template__c = 'TestVFPage',
            sObject__c = 'Account',
            Child_sObject__c = 'Contact',
            Status__c = 'Active',
            Title_Custom_Field__c = 'Name'
        );
        insert docTemplate;

        // Create a request
        Invoke_DocTemplateGen.Request request = new Invoke_DocTemplateGen.Request();
        request.recordId = testAccount.Id;
        request.docTemplates = new List<Document_Template__c>{docTemplate};

        // Add the request to a list
        List<Invoke_DocTemplateGen.Request> requestList = new List<Invoke_DocTemplateGen.Request>{request};

        // Call the method to test
        Test.startTest();
        Invoke_DocTemplateGen.generateAndAttachPDF(requestList);
        Test.stopTest();
    }
}