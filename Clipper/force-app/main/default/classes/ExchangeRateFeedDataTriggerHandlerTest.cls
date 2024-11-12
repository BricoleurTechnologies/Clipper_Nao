/**
 * @date May-23-2024
 * @author Bricoleur Technologies
 * @description Test class for ExchangeRateFeedDataTriggerHandler
 */

@isTest
public class ExchangeRateFeedDataTriggerHandlerTest {
    @IsTest
    static void onAfterInsertTest(){
        
        Exchange_Rate_Feed_Data__c exchangeRate = new Exchange_Rate_Feed_Data__c(
            Exchange_Rate_JSON__c = '{"success":true,"timestamp":1716422399,"historical":true,"base":"AUD","date":"2024-05-22","rates":{"CNY":4.792929,"EUR":0.611449,"GBP":0.520343,"PHP":38.456881,"USD":0.661888}}',
            Status__c = 'Retrieved'
        );

        Test.startTest();
            insert exchangeRate;
        Test.stopTest();

        System.assert(exchangeRate != null);
    }
}