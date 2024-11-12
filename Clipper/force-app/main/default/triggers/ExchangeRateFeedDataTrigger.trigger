/**
 * @date May-20-2024
 * @author Bricoleur Technologies
 * @description Trigger for Exchange_Rate_Feed_Data__c
 */
trigger ExchangeRateFeedDataTrigger on Exchange_Rate_Feed_Data__c (after insert) {
    ExchangeRateFeedDataTriggerHandler.onAfterInsert(Trigger.new);
}