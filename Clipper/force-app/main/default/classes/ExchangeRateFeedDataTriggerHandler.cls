/**
 * @date May-21-2024
 * @author Bricoleur Technologies
 * @description Trigger handler for ExchangeRateFeedDataTrigger
 */

public class ExchangeRateFeedDataTriggerHandler {

    public static void onAfterInsert(List<Exchange_Rate_Feed_Data__c> newList) {
        
        Map<String, Object> ratesMap = new Map<String, Object>();
        Map<String, Map<String, Object>> exchangeRatesMap = new Map<String, Map<String, Object>>();
        List<Exchange_Rate_Feed_Rate__c> exchangeRateList = new List<Exchange_Rate_Feed_Rate__c>();

        for(Exchange_Rate_Feed_Data__c erf : newList) {
            if(erf.Status__c == Constants.EXCHANGE_RATE_FEED_STATUS_RETRIEVED) {
                String jsonString = erf.Exchange_Rate_JSON__c;           
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
                exchangeRatesMap.put(erf.Id, (Map<String, Object>) result.get(Constants.EXCHANGE_RATE_JSON_RATES));
            }
        }

        for(String erfId : exchangeRatesMap.keySet()) {
            for(String currKey : exchangeRatesMap.get(erfId).keySet()) {
                Exchange_Rate_Feed_Rate__c exchangeRate = new Exchange_Rate_Feed_Rate__c(
                    Exchange_Rate_Feed_Data__c = erfId,
                    Currency_Code__c = currKey,
                    Rate__c = (Decimal) exchangeRatesMap.get(erfId).get(currKey),
                    As_At_Date__c = Date.today()
                );
                exchangeRateList.add(exchangeRate);
            }
        }

        insert exchangeRateList;
    }
}