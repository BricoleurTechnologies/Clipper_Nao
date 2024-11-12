/**
 * @description Test class for Invoke_SendBulkEmail
 * @date Nov-7-2024
 * @author Bricoleur Technologies
*/
@isTest
public class Invoke_SendBulkEmailTest {
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

        ContentVersion cv = [SELECT Id, ContentDocumentId, Record_ID__c FROM ContentVersion WHERE Id =: contentVersion.Id];

        // Retrieve the ContentDocument Id
        ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];

        // Step 2: Create a test record to associate with the ContentDocument
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact con = new Contact(LastName = 'Lname', Firstname = 'Fname', AccountId = testAccount.Id, Email = 'test@email.com');
        insert con;

        // Step 3: Create a ContentDocumentLink record to link ContentDocument to the test record
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.Id,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V', // Viewer
            Visibility = 'AllUsers' // Set visibility as needed
        );
        insert contentDocumentLink;

        Invoke_SendBulkEmail.EmailInput emailInput = new Invoke_SendBulkEmail.EmailInput();
        emailInput.setToAddrList = new List<String>{'test@example.com'};
        emailInput.ccList = new List<String>{'cc@example.com'};
        //emailInput.emailTemplateDevName = 'Test_Template_Dev';
       // emailInput.subject = 'Test Email Subject';
        //emailInput.orgWideEmail = 'noreply@example.com';
        emailInput.senderDisplayName = 'Test Sender';
        emailInput.replyTo = 'replyto@example.com';
        emailInput.whatId = testAccount.Id; // Example record Id
        emailInput.targetObjectId = con.Id; // Example contact Id

        //[1] JP Sulit - Nov-7-2024 - Pass values to list parameters added in EmailInput inner class
        //START
        emailInput.attachmentList = new List<ContentVersion> {cv};
        emailInput.whatIdList = new List<String> {emailInput.whatId}; 
        emailInput.targetObjectIdList = new List<String> {emailInput.targetObjectId};
        emailInput.targetObjectFieldName = 'Id';
        emailInput.whatFieldName = 'AccountId';
        emailInput.saveAsActivity = true;
        //END

        List<Invoke_SendBulkEmail.EmailInput> emailInputList = new List<Invoke_SendBulkEmail.EmailInput>{ emailInput };

        // Use Test.startTest and Test.stopTest to capture actual execution
        Test.startTest();
        List<Invoke_SendBulkEmail.EmailOutput> result = Invoke_SendBulkEmail.invokeSendEmail(emailInputList);
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

        ContentVersion cv = [SELECT Id, ContentDocumentId, Record_ID__c FROM ContentVersion WHERE Id =: contentVersion.Id];

        // Retrieve the ContentDocument Id
        ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];

        // Step 2: Create a test record to associate with the ContentDocument
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact con = new Contact(LastName = 'Lname', Firstname = 'Fname', AccountId = testAccount.Id, Email = 'test@email.com');
        insert con;

        // Step 3: Create a ContentDocumentLink record to link ContentDocument to the test record
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.Id,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V', // Viewer
            Visibility = 'AllUsers' // Set visibility as needed
        );
        insert contentDocumentLink;

        Invoke_SendBulkEmail.EmailInput emailInput = new Invoke_SendBulkEmail.EmailInput();
        emailInput.setToAddrList = new List<String>{};
        emailInput.ccList = new List<String>{};
        //emailInput.emailTemplateDevName = 'Test_Template_Dev';
       // emailInput.subject = 'Test Email Subject';
        //emailInput.orgWideEmail = 'noreply@example.com';
        emailInput.senderDisplayName = 'Test Sender';
        emailInput.replyTo = 'replyto@example.com';
        emailInput.whatId = testAccount.Id; // Example record Id
        emailInput.targetObjectId = con.Id; // Example contact Id


        //[1] JP Sulit - Nov-7-2024 - Pass values to list parameters added in EmailInput inner class
        //START
        emailInput.attachmentList = new List<ContentVersion> {cv};
        emailInput.whatIdList = new List<String> {emailInput.whatId}; 
        emailInput.targetObjectIdList = new List<String> {emailInput.targetObjectId};
        emailInput.targetObjectFieldName = 'Id';
        emailInput.whatFieldName = 'AccountId';
        emailInput.saveAsActivity = true;
        //END

        List<Invoke_SendBulkEmail.EmailInput> emailInputList = new List<Invoke_SendBulkEmail.EmailInput>{ emailInput };

        // Use Test.startTest and Test.stopTest to capture actual execution
        Test.startTest();
        List<Invoke_SendBulkEmail.EmailOutput> result = Invoke_SendBulkEmail.invokeSendEmail(emailInputList);
        Test.stopTest();
    }
}