/*
* Author: Bricoleur Technologies - John Paulo M. Sulit (jp@bricoleurtech.com)
* Created Date: Dec 13, 2023
* Description: Test class for Invoke_EmailQuotePDF_Bric
* History: 	Dec 13, 2023 - Created
*/

@isTest
public class Invoke_EmailQuotePDFTest_Bric {
    private static testMethod void emailQuotePdfYesTest()
    {
        /*Field_Image_Settings_Bric__c fiCs = TestDataFactory.createFieldImageSettings(Constants.CS_NAME, false, true);
        insert fiCs;*/
        ContentVersion cv = new ContentVersion(Title = 'Fair Go Policy',
                                                VersionData = Blob.toPDF('Hello World'),
                                                PathOnClient = 'Fair Go Policy.pdf');
        insert cv;

        List<Account> acctList = TestDataFactory.CreateAccount(1, true);
        List<Contact> conList = TestDataFactory.createContacts(acctList, true);
        List<Opportunity> oppList = TestDataFactory.CreateOpportunity(1, acctList[0].Id, false);
        oppList[0].ContactId = conList[0].Id;
        oppList[0].Digital_Quote_Accepted_Bric__c = 'Yes';
        oppList[0].Service_Subcategory_Bric__c = 'Gutter Cleaning';
        insert oppList;
        List<Product2> prodList = TestDataFactory.CreateProducts(5, true);
        List<PricebookEntry> pbeList = TestDataFactory.createPBE(prodList, true);
        TestDataFactory.OpportunityLineItemParameters oliParam = new TestDataFactory.OpportunityLineItemParameters();
        oliParam.oppId = oppList[0].Id;
        oliParam.PbeId = pbeList[0].Id;
        oliParam.Quantity = 1; 
        oliParam.PbeUnitPrice = pbeList[0].UnitPrice; 
        List<OpportunityLineItem> oliList = TestDataFactory.CreateOpportunityLineItems(3, oliParam, true);

        Invoke_EmailQuotePDF_Bric.FlowInputs input = new Invoke_EmailQuotePDF_Bric.FlowInputs();
        input.isQuoteEmail = false;
        input.oppId = oppList[0].Id;
        input.oppName = oppList[0].Name;
        input.oppClientEmail = 'test@email.com';
        input.templateDevName = '';

        Test.startTest();
            Invoke_EmailQuotePDF_Bric.emailQuotePdf(new List<Invoke_EmailQuotePDF_Bric.FlowInputs> {input});
        Test.stopTest();
    }

    private static testMethod void emailQuotePdfNoTest()
    {
        /*Field_Image_Settings_Bric__c fiCs = TestDataFactory.createFieldImageSettings(Constants.CS_NAME, false, true);
        insert fiCs;*/
        ContentVersion cv = new ContentVersion(Title = 'Fair Go Policy',
                                                VersionData = Blob.toPDF('Hello World'),
                                                PathOnClient = 'Fair Go Policy.pdf');
        insert cv;

        List<Account> acctList = TestDataFactory.CreateAccount(1, true);
        List<Contact> conList = TestDataFactory.createContacts(acctList, true);
        List<Opportunity> oppList = TestDataFactory.CreateOpportunity(1, acctList[0].Id, false);
        oppList[0].ContactId = conList[0].Id;
        oppList[0].Digital_Quote_Accepted_Bric__c = 'No';
        oppList[0].Service_Subcategory_Bric__c = 'Gutter Cleaning';
        insert oppList;
        List<Product2> prodList = TestDataFactory.CreateProducts(5, true);
        List<PricebookEntry> pbeList = TestDataFactory.createPBE(prodList, true);
        TestDataFactory.OpportunityLineItemParameters oliParam = new TestDataFactory.OpportunityLineItemParameters();
        oliParam.oppId = oppList[0].Id;
        oliParam.PbeId = pbeList[0].Id;
        oliParam.Quantity = 1; 
        oliParam.PbeUnitPrice = pbeList[0].UnitPrice; 
        List<OpportunityLineItem> oliList = TestDataFactory.CreateOpportunityLineItems(3, oliParam, true);

        Invoke_EmailQuotePDF_Bric.FlowInputs input = new Invoke_EmailQuotePDF_Bric.FlowInputs();
        input.isQuoteEmail = false;
        input.oppId = oppList[0].Id;
        input.oppName = oppList[0].Name;
        input.oppClientEmail = 'test@email.com';
        input.templateDevName = '';

        Test.startTest();
            Invoke_EmailQuotePDF_Bric.emailQuotePdf(new List<Invoke_EmailQuotePDF_Bric.FlowInputs> {input});
        Test.stopTest();
    }

    private static testMethod void emailQuotePdfTest()
    {
        /*Field_Image_Settings_Bric__c fiCs = TestDataFactory.createFieldImageSettings(Constants.CS_NAME, false, true);
        insert fiCs;*/
        ContentVersion cv = new ContentVersion(Title = 'Fair Go Policy',
                                                VersionData = Blob.toPDF('Hello World'),
                                                PathOnClient = 'Fair Go Policy.pdf');
        insert cv;

        List<Account> acctList = TestDataFactory.CreateAccount(1, true);
        List<Contact> conList = TestDataFactory.createContacts(acctList, true);
        List<Opportunity> oppList = TestDataFactory.CreateOpportunity(1, acctList[0].Id, false);
        oppList[0].ContactId = conList[0].Id;
        oppList[0].Service_Subcategory_Bric__c = 'Gutter Cleaning';
        insert oppList;
        List<Product2> prodList = TestDataFactory.CreateProducts(5, true);
        List<PricebookEntry> pbeList = TestDataFactory.createPBE(prodList, true);
        TestDataFactory.OpportunityLineItemParameters oliParam = new TestDataFactory.OpportunityLineItemParameters();
        oliParam.oppId = oppList[0].Id;
        oliParam.PbeId = pbeList[0].Id;
        oliParam.Quantity = 1; 
        oliParam.PbeUnitPrice = pbeList[0].UnitPrice; 
        List<OpportunityLineItem> oliList = TestDataFactory.CreateOpportunityLineItems(3, oliParam, true);

        Invoke_EmailQuotePDF_Bric.FlowInputs input = new Invoke_EmailQuotePDF_Bric.FlowInputs();
        input.isQuoteEmail = true;
        input.oppId = oppList[0].Id;
        input.oppName = oppList[0].Name;
        input.oppClientEmail = 'test@email.com';
        input.templateDevName = 'Send_Quote_Email_Template_1701140923706';

        Test.startTest();
            Invoke_EmailQuotePDF_Bric.emailQuotePdf(new List<Invoke_EmailQuotePDF_Bric.FlowInputs> {input});
        Test.stopTest();
    }
}