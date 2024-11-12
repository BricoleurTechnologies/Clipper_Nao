@IsTest
public class Invoke_SendEmailTest {

    @IsTest
    static void testInvokeSendEmail_Success() {
        
        // Setup mock email data
        // Step 1: Create a ContentVersion record
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('This is a test document content.'),
            ContentLocation = 'S' // Salesforce
        );
        insert contentVersion;

        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersion.Id];

        // Retrieve the ContentDocument Id
        ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];

        // Step 2: Create a test record to associate with the ContentDocument
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Step 3: Create a ContentDocumentLink record to link ContentDocument to the test record
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.Id,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V', // Viewer
            Visibility = 'AllUsers' // Set visibility as needed
        );
        insert contentDocumentLink;

        Invoke_SendEmail.EmailInput emailInput = new Invoke_SendEmail.EmailInput();
        emailInput.setToAddrList = new List<String>{'test@example.com'};
        emailInput.ccList = new List<String>{'cc@example.com'};
        //emailInput.emailTemplateDevName = 'Test_Template_Dev';
       // emailInput.subject = 'Test Email Subject';
        emailInput.orgWideEmail = 'noreply@example.com';
        emailInput.senderDisplayName = 'Test Sender';
        emailInput.replyTo = 'replyto@example.com';
        emailInput.whatId = testAccount.Id; // Example record Id
        emailInput.targetObjectId = '0032x000004NayQAAS'; // Example contact Id

        List<Invoke_SendEmail.EmailInput> emailInputList = new List<Invoke_SendEmail.EmailInput>{ emailInput };

        // Use Test.startTest and Test.stopTest to capture actual execution
        Test.startTest();
        List<Invoke_SendEmail.EmailOutput> result = Invoke_SendEmail.invokeSendEmail(emailInputList);
        Test.stopTest();
    }

    @IsTest
    static void testInvokeSendEmail_EmailException() {

        // Setup mock email data with an invalid condition that will cause an error (e.g., no email addresses)
        // Step 1: Create a ContentVersion record
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('This is a test document content.'),
            ContentLocation = 'S' // Salesforce
        );
        insert contentVersion;

        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersion.Id];

        // Retrieve the ContentDocument Id
        ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];

        // Step 2: Create a test record to associate with the ContentDocument
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Step 3: Create a ContentDocumentLink record to link ContentDocument to the test record
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.Id,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V', // Viewer
            Visibility = 'AllUsers' // Set visibility as needed
        );
        insert contentDocumentLink;

        Invoke_SendEmail.EmailInput emailInput = new Invoke_SendEmail.EmailInput();
        emailInput.setToAddrList = new List<String>{};
        emailInput.ccList = new List<String>{};
        //emailInput.emailTemplateDevName = 'Test_Template_Dev';
       // emailInput.subject = 'Test Email Subject';
        emailInput.orgWideEmail = 'noreply@example.com';
        emailInput.senderDisplayName = 'Test Sender';
        emailInput.replyTo = 'replyto@example.com';
        emailInput.whatId = testAccount.Id; // Example record Id
        emailInput.targetObjectId = '0032x000004NayQAAS'; // Example contact Id

        List<Invoke_SendEmail.EmailInput> emailInputList = new List<Invoke_SendEmail.EmailInput>{ emailInput };

        // Use Test.startTest and Test.stopTest to capture actual execution
        Test.startTest();
        List<Invoke_SendEmail.EmailOutput> result = Invoke_SendEmail.invokeSendEmail(emailInputList);
        Test.stopTest();
    }
}