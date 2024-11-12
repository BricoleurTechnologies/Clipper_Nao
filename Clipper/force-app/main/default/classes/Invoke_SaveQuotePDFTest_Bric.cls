/*
* Author: Bricoleur Technologies - John Paulo M. Sulit (jp@bricoleurtech.com)
* Created Date: Dec 13, 2023
* Description: Test class for Invoke_SaveQuotePDF_Bric
* History: 	Dec 13, 2023 - Created
*/

@isTest
public class Invoke_SaveQuotePDFTest_Bric {
    private static testMethod void saveQuotePdfTest()
    {
        List<Account> acctList = TestDataFactory.CreateAccount(1, true);
        List<Contact> conList = TestDataFactory.createContacts(acctList, true);
        List<Opportunity> oppList = TestDataFactory.CreateOpportunity(1, acctList[0].Id, false);
        oppList[0].ContactId = conList[0].Id;
        insert oppList;
        List<Product2> prodList = TestDataFactory.CreateProducts(5, true);
        List<PricebookEntry> pbeList = TestDataFactory.createPBE(prodList, true);
        TestDataFactory.OpportunityLineItemParameters oliParam = new TestDataFactory.OpportunityLineItemParameters();
        oliParam.oppId = oppList[0].Id;
        oliParam.PbeId = pbeList[0].Id;
        oliParam.Quantity = 1; 
        oliParam.PbeUnitPrice = pbeList[0].UnitPrice; 
        List<OpportunityLineItem> oliList = TestDataFactory.CreateOpportunityLineItems(3, oliParam, true);

        /*Field_Image_Settings_Bric__c fiCs = TestDataFactory.createFieldImageSettings(Constants.CS_NAME, false, true);
        insert fiCs;*/

        Invoke_SaveQuotePDF_Bric.FlowInputs input = new Invoke_SaveQuotePDF_Bric.FlowInputs();
        input.oppId = oppList[0].Id;
        input.oppName = oppList[0].Name;
        input.oppClientEmail = 'test@email.com';
        input.digitalQuoteAccepted = 'Yes';

        Test.startTest();
            Invoke_SaveQuotePDF_Bric.savePdfToQuote(new List<Invoke_SaveQuotePDF_Bric.FlowInputs> {input});
        Test.stopTest();
    }
}