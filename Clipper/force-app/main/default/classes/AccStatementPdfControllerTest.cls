/**
 * @description Test class for AccStatementPdfController
 * @author JP Sulit
 * @date Oct-28-2024 (Created)
 */

 @isTest
public class AccStatementPdfControllerTest {
    @TestSetup
    static void setupTestData() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Invoice record
        Invoice__c testInvoice = new Invoice__c(
            Account_Bric__c = testAccount.Id
        );
        insert testInvoice;

        // You can add additional related records if necessary
    }

    @IsTest
    static void testConstructor() {
        // Simulate the parameters that would be passed to the controller
        String testObjectName = 'Account';
        String testRecordId = [SELECT Id FROM Account LIMIT 1].Id;
        String testChildObjName = 'Invoice__c';
        String testLogoUrl = 'http://example.com/logo.png';

        // Simulate the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/AccountStatementPDF'));
        ApexPages.currentPage().getParameters().put('sObjectType', testObjectName);
        ApexPages.currentPage().getParameters().put('Id', testRecordId);
        ApexPages.currentPage().getParameters().put('childSObjectType', testChildObjName);
        ApexPages.currentPage().getParameters().put('pdfLogo', testLogoUrl);

        // Instantiate the controller
        AccStatementPdfController controller = new AccStatementPdfController();

        // Validate that the constructor initialized the properties correctly
        System.assertEquals(testLogoUrl, controller.logoUrl, 'Expected logoUrl to be set.');
        System.assertNotEquals(null, controller.recordList, 'recordList should not be null.');
    }

    @IsTest
    static void testRecordListPopulation() {
        // Simulate the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/AccountStatementPDF'));
        ApexPages.currentPage().getParameters().put('sObjectType', 'Account');
        ApexPages.currentPage().getParameters().put('Id', [SELECT Id FROM Account LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('childSObjectType', 'Invoice__c');

        // Instantiate the controller
        AccStatementPdfController controller = new AccStatementPdfController();

        // Validate that the recordList is populated as expected
        System.assertNotEquals(null, controller.recordList, 'recordList should be populated.');
        System.assert(controller.recordList.size() > 0, 'recordList should contain records.');
    }
}