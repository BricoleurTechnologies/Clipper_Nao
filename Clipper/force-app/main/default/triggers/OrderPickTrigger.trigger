/**
 * @description Trigger for Order_Pick__c object
 * @date Aug-19-2024
 * @author Bricoleur Technologies
 */

trigger OrderPickTrigger on Order_Pick__c (after insert, after update) {

   List<TriggerSetting__mdt> triggerSetting = [SELECT Id, DeveloperName, Active__c FROM TriggerSetting__mdt
   WHERE DeveloperName = 'OrderPickTrigger'];

   if(triggerSetting.isEmpty()) return;

   if(triggerSetting[0].Active__c == TRUE) {
      new OrderPickTriggerHandler().run();
   }
}