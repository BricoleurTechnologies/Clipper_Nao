/**
 * @description Handler class for OrderPickTrigger
 * @date Aug-19-2024
 * @author Bricoleur Technologies
 */

public without sharing class OrderPickTriggerHandler extends TriggerHandlerNAO {
    
    private Map<Id, Order_Pick__c> opNewMap;
    private Map<Id, Order_Pick__c> opOldMap;

    public OrderPickTriggerHandler() {
        this.opNewMap = (Map<Id, Order_Pick__c>) Trigger.newMap;
        this.opOldMap = (Map<Id, Order_Pick__c>) Trigger.oldMap;
    }

    public override void afterUpdate() {
        OrderPickTriggerHelper.processOrderPickLines(opNewMap, opOldMap);
    }
}