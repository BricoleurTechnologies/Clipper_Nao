/**
 * @date May-23-2024
 * @author Bricoleur Technologies
 * @description Test class for ExchangeRateApiClass
 */

@isTest
public class ExchangeRateApiClassTest {

    @TestSetup
    static void makeData(){
        Exchange_Rates_API_Setting__c setting = new Exchange_Rates_API_Setting__c(
        	Name = Constants.EXCHANGE_RATE_SETTING_NAME,
            Access_Key__c = '2eb886fe5d04ba358ed2a8835d81fbe6',
            Api_Url__c = 'https://api.exchangeratesapi.io/v1/'
        );
        insert setting;
    }

    @isTest
    static void fetchLatestExchangeRateTest() {
        
        Test.setMock(HttpCalloutMock.class, new ExchangeRateApiClassMock());

        ExchangeRateApiClassMock mockClass = new ExchangeRateApiClassMock();
        HttpResponse resp = mockClass.respond(new HttpRequest());
        
        Test.startTest();
            ExchangeRateApiClass.fetchLatestExchangeRate();
        Test.stopTest();

        System.assert(resp.getStatusCode() == 200);
    }

    @isTest
    static void fetchLatestExchangeRateErrorTest() {
        
        Test.setMock(HttpCalloutMock.class, new ExchangeRateApiErrorMock());

        ExchangeRateApiErrorMock mockClass = new ExchangeRateApiErrorMock();
        HttpResponse resp = mockClass.respond(new HttpRequest());
        
        Test.startTest();
            ExchangeRateApiClass.fetchLatestExchangeRate();
        Test.stopTest();

        System.assert(resp.getStatusCode() == 404);
    }
}