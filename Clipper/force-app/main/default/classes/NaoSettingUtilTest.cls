@isTest
public class NaoSettingUtilTest {
    private static List<Order_Pick__c> orderPickList = new List<Order_Pick__c>(); 

    @TestSetup
    static void testData() {
        List<Account> accList = NAOTestDataBuilder.CreateAccount(1, true);
        List<Opportunity> oppList = NAOTestDataBuilder.CreateOpportunity(1, accList[0].Id, true);
        List<Product2> prodList = NAOTestDataBuilder.CreateProducts(3, true);
        List<Schema.Location> locationList = NAOTestDataBuilder.createLocations(1, true);
        List<NAOTestDataBuilder.PricebookEntryParameters> pbeParamList = new List<NAOTestDataBuilder.PricebookEntryParameters>();
        for(Integer i = 0; i < prodList.size(); i++) {
            NAOTestDataBuilder.PricebookEntryParameters pbeParam = new NAOTestDataBuilder.PricebookEntryParameters();
            pbeParam.PricebookId = Test.getStandardPricebookId();
            pbeParam.ProductId = prodList[i].Id;
            pbeParam.UnitPrice = i + 10;
            pbeParamList.add(pbeParam); 
        }
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        List<PricebookEntry> pbeList1 = NAOTestDataBuilder.CreatePricebookEntries(1, pbeParamList[0], true);
        List<PricebookEntry> pbeList2 = NAOTestDataBuilder.CreatePricebookEntries(1, pbeParamList[1], true);
        List<PricebookEntry> pbeList3 = NAOTestDataBuilder.CreatePricebookEntries(1, pbeParamList[2], true);
        pbeList.addAll(new List<PricebookEntry> {pbeList1[0], pbeList2[0], pbeList3[0]});
        List<NAOTestDataBuilder.OpportunityLineItemParameters> oppLineParamList = new List<NAOTestDataBuilder.OpportunityLineItemParameters>();
        for(Integer i = 0; i < pbeList.size(); i++) {
            NAOTestDataBuilder.OpportunityLineItemParameters oppLineParam = new NAOTestDataBuilder.OpportunityLineItemParameters();
            oppLineParam.OppId = oppList[0].Id;
            oppLineParam.PbeId = pbeList[i].Id;
            oppLineParam.Quantity = i + 10;
            oppLineParam.PbeUnitPrice = pbeList[i].UnitPrice;
            oppLineParamList.add(oppLineParam); 
        }
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppLineList1 = NAOTestDataBuilder.CreateOpportunityLineItems(10, oppLineParamList[0], true);
        List<OpportunityLineItem> oppLineList2 = NAOTestDataBuilder.CreateOpportunityLineItems(10, oppLineParamList[1], true);
        List<OpportunityLineItem> oppLineList3 = NAOTestDataBuilder.CreateOpportunityLineItems(10, oppLineParamList[2], true);
        NAOTestDataBuilder.OrderParameters orderParam = new NAOTestDataBuilder.OrderParameters();
        orderParam.accId = accList[0].Id;
        orderParam.oppId = oppList[0].Id;
        orderParam.warehouseId = locationList[0].Id;
        List<Order> orderList = NAOTestDataBuilder.createOrders(1, orderParam, true);
        List<OrderItem> orderItemList = NAOTestDataBuilder.createOrderProducts(pbeList, orderList[0].Id, true);
        orderPickList = NAOTestDataBuilder.createOrderPicks(1, orderList[0].Id, locationList[0].Id, true);
        List<Order_Pick_Line__c> orderPickLineList = NAOTestDataBuilder.createOrderPickLines(orderPickList[0].Id, orderItemList, true);
    }

    @IsTest
    static void naoSettingUtilTest(){
        
        Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id FROM Order]);
        Map<Id, Schema.Location> locationMap = new Map<Id, Schema.Location>([SELECT Id FROM Location]);
        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id FROM Product2]);
        String locProdKey = String.valueOf(locationMap.keySet().iterator().next()) + '-' + String.valueOf(productMap.keySet().iterator().next());
        Map<Id, OrderItem> orderProductMap = new Map<Id, OrderItem>([SELECT Id FROM OrderItem WHERE OrderId IN : orderMap.keySet()]);
        Map<Id, Order_Pick_Line__c> orderPickLineMap = new Map<Id, Order_Pick_Line__c>();
        for(Order_Pick_Line__c opl : [SELECT Id, Picked_Quantity__c, Order_Product__c FROM Order_Pick_Line__c]) {
            orderPickLineMap.put(opl.Order_Product__c, opl);
        }

        Test.startTest();
            NaoSettingUtil.calculateTotalSalesOrders(orderMap.keySet(), locationMap.keySet(), productMap.keySet(), new Set<String>{locProdKey});
            NaoSettingUtil.calcOrderProductPicked(orderPickLineMap);
            NaoSettingUtil.createUpdateInventoryMovement(orderPickLineMap);
        Test.stopTest();   
    }
}