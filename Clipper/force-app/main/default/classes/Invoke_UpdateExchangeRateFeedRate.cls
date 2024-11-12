/**
 * @date May-23-2024
 * @author Bricoleur Technologies
 * @description Invocable class to update Exchange Rate Feed Rate status
 */

public class Invoke_UpdateExchangeRateFeedRate {

    @InvocableMethod(label='Update Exchange rate feed rate')
    public static void updateErfr(List<FlowInput> input) {
        updateErfr(input[0].recordId, input[0].status);
    }

    @future(callout=true)
    public static void updateErfr(String erfrId, String statusStr) {
        List<Exchange_Rate_Feed_Rate__c> erfrList = new List<Exchange_Rate_Feed_Rate__c>();
        Exchange_Rate_Feed_Rate__c erfr = new Exchange_Rate_Feed_Rate__c(
            Id = erfrId,
            Status__c = statusStr
        );
        erfrList.add(erfr);
        System.debug('erfrList bric '+erfrList);
        update erfrList;
    }

    public class FlowInput {
        @InvocableVariable
        public String recordId;
        @InvocableVariable
        public String status;
    }
}