/*
* Author: Bricoleur Technologies - John Paulo M. Sulit (jp@bricoleurtech.com)
* Created Date: Dec 13, 2023
* Description: Test class for OnlineQuoteFormController_Bric
* History: 	Dec 13, 2023 - Created
*/

@isTest
public class OnlineQuoteFormControllerTest_Bric {
    private static testMethod void queryOppTest()
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
        PageReference testPage = Page.OnlineQuoteForm; 
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(oppList[0].Id));
        OnlineQuoteFormController_Bric ctrl = new OnlineQuoteFormController_Bric();
        Test.startTest();
            ctrl.queryOpp();
        Test.stopTest();
    }

    private static testMethod void declineQuoteTest()
    {
        /*Field_Image_Settings_Bric__c fiCs = TestDataFactory.createFieldImageSettings(Constants.CS_NAME, false, true);
        insert fiCs;*/

        List<Account> acctList = TestDataFactory.CreateAccount(1, false);
        acctList[0].Email__c = 'test@email.com';
        insert acctList;
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
        PageReference testPage = Page.OnlineQuoteForm; 
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(oppList[0].Id));
        OnlineQuoteFormController_Bric ctrl = new OnlineQuoteFormController_Bric();
        Test.startTest();
            ctrl.declineQuote();
        Test.stopTest();
    }
    private static testMethod void acceptQuoteTest()
    {
        /*Field_Image_Settings_Bric__c fiCs = TestDataFactory.createFieldImageSettings(Constants.CS_NAME, false, true);
        insert fiCs;*/

        List<Account> acctList = TestDataFactory.CreateAccount(1, false);
        acctList[0].Email__c = 'test@email.com';
        insert acctList;
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
        PageReference testPage = Page.OnlineQuoteForm; 
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(oppList[0].Id));
        OnlineQuoteFormController_Bric ctrl = new OnlineQuoteFormController_Bric();
        Test.startTest();
            ctrl.acceptQuote();
        Test.stopTest();
    }
    private static testMethod void declineReasonsTest()
    {
        OnlineQuoteFormController_Bric ctrl = new OnlineQuoteFormController_Bric();
        Test.startTest();
            ctrl.getDeclineReasons();
        Test.stopTest();
    }

    private static testMethod void userLocTest()
    {
        Test.setMock(HttpCalloutMock.class, new UserLocationMock_Bric());
        OnlineQuoteFormController_Bric ctrl = new OnlineQuoteFormController_Bric();
        Test.startTest();
            ctrl.getUserLocation('120.29.77.43');
        Test.stopTest();
    }
}