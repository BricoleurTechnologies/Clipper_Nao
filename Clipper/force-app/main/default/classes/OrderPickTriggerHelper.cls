/**
 * @description Helper class for OrderPickTriggerHandler
 * @date Aug-19-2024
 * @author Bricoleur Technologies
 */

 public without sharing class OrderPickTriggerHelper {

    public static void processOrderPickLines(Map<Id, Order_Pick__c> newMap, Map<Id, Order_Pick__c> oldMap) {
        
        Set<String> orderPickIdSet = new Set<String>();
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> locIdSet = new Set<Id>();
        Set<Id> prodIdSet = new Set<Id>();
        Set<String> locProdKeySet = new Set<String>();
        Map<Id, Order_Pick_Line__c> orderPickLineMap = new Map<Id, Order_Pick_Line__c>();
        Map<Id, Id> orderLocIdMap = new Map<Id, Id>();

        for(Order_Pick__c op : newMap.values()) {

            if(op.Picked_bric__c != oldMap.get(op.Id).Picked_bric__c && op.Picked_bric__c) {
                orderPickIdSet.add(op.Id);
                orderIdSet.add(op.Order__c);
            }
        }

        if(!orderPickIdSet.isEmpty()) {

            for(Order o : [SELECT Id, Inventory_Location__c FROM Order WHERE Id IN : orderIdSet]) {
                System.debug('o.Inventory_Location__c aug 30 '+o.Inventory_Location__c);
                orderLocIdMap.put(o.Id, o.Inventory_Location__c);
                locIdSet.add(o.Inventory_Location__c);
            }

            System.debug('orderLocIdMap aug 30 '+orderLocIdMap);

            for(Order_Pick_Line__c opl : [SELECT Id, 
                                                Order_Product__c,
                                                Picked_Quantity__c,
                                                Order_Product__r.OrderId,
                                                Order_Product__r.Product2Id 
                                                FROM Order_Pick_Line__c 
                                                WHERE Order_Pick__c IN :  orderPickIdSet
                                                AND Picked_Quantity__c != 0]) {
                System.debug('Order_Product__r.Product2Id aug 30 bric '+opl.Order_Product__r.Product2Id);
                System.debug('Order_Product__r.OrderId aug 30 bric '+opl.Order_Product__r.OrderId);
                prodIdSet.add(opl.Order_Product__r.Product2Id);
                if(!orderLocIdMap.isEmpty() &&  orderLocIdMap.containsKey(opl.Order_Product__r.OrderId)) {
                    System.debug('orderLocIdMap.get(opl.Order_Product__r.OrderId) aug 30 '+orderLocIdMap.get(opl.Order_Product__r.OrderId));
                    locProdKeySet.add(orderLocIdMap.get(opl.Order_Product__r.OrderId)+ '-' +opl.Order_Product__r.Product2Id);
                }
                orderPickLineMap.put(opl.Order_Product__c, opl);
            }

            System.debug('orderIdSet aug 30 bric '+orderIdSet);
            System.debug('locIdSet aug 30 bric '+locIdSet);
            System.debug('prodIdSet aug 30 bric '+prodIdSet);
            System.debug('locProdKeySet aug 30 bric '+locProdKeySet);

            if(!orderPickLineMap.isEmpty()) {
                NaoSettingUtil.createUpdateInventoryMovement(orderPickLineMap);
                NaoSettingUtil.calcOrderProductPicked(orderPickLineMap);
            }

            NaoSettingUtil.calculateTotalSalesOrders(orderIdSet, locIdSet, prodIdSet, locProdKeySet);
        }
    }
}