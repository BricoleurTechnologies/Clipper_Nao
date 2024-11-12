@isTest
public class OrderTriggerHandlerTest {
    
    
    public static final Id salesOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
    public static final Id purchaseOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
    public static final Id supplierProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Supplier_Product').getRecordTypeId();
    public static final Id standardProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
    
    @testSetup static void setup(){
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Supplier_Pricebook__c = standardPricebookId;
        insert acc;
        
        Product2 supProd = new Product2(Name='Test Supplier Product', ProductCode= 'DEF', RecordTypeId = supplierProductRecordTypeId);
        insert supProd;
        
        PricebookEntry supPbe = new PricebookEntry();
        supPbe.Product2Id = supProd.Id;
        supPbe.Pricebook2Id = standardPricebookId;
        supPbe.UnitPrice = 100;
        insert supPbe;
        
        Product2 prod = new Product2(Name='Test Product', ProductCode= 'ABC', RecordTypeId = standardProductRecordTypeId, Supplier_Product__c = supProd.Id, Conversion_Factor__c = 150);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = prod.Id;
        pbe.Pricebook2Id = standardPricebookId;
        pbe.UnitPrice = 100;
        insert pbe;
        
        
        Schema.Location locationRecord = new Schema.Location();
        locationRecord.Name = 'Warehouse';
        locationRecord.LocationType = 'Warehouse';
        insert locationRecord;
        
        Location_Product__c locProd = new Location_Product__c();
        locProd.Product__c = prod.Id;
        locProd.Location__c = locationRecord.Id;
        insert locProd;
        
        Order salesOrderRecord = new Order();
        salesOrderRecord.AccountId = acc.Id;
        salesOrderRecord.EffectiveDate = Date.today();
        salesOrderRecord.RecordTypeId = salesOrderRecordTypeId;
        salesOrderRecord.Status = 'Draft';
        salesOrderRecord.Pricebook2Id = standardPricebookId;
        salesOrderRecord.Inventory_Location__c = locationRecord.Id;
        insert salesOrderRecord;
        
        Order purchaseOrderRecord = new Order();
        purchaseOrderRecord.AccountId = acc.Id;
        purchaseOrderRecord.EffectiveDate = Date.today();
        purchaseOrderRecord.RecordTypeId = purchaseOrderRecordTypeId;
        purchaseOrderRecord.Status = 'Draft';
        purchaseOrderRecord.Pricebook2Id = standardPricebookId;
        purchaseOrderRecord.Inventory_Location__c = locationRecord.Id;
        purchaseOrderRecord.Completed__c = false;
        insert purchaseOrderRecord;
        
        OrderItem purchaseOrderItemRecord = new OrderItem();
        purchaseOrderItemRecord.OrderId = purchaseOrderRecord.Id;
        purchaseOrderItemRecord.PricebookEntryId = supPbe.Id;
        purchaseOrderItemRecord.Product2Id = supProd.Id;
        purchaseOrderItemRecord.Location__c = locProd.Location__c;
        purchaseOrderItemRecord.Quantity = 1;
        purchaseOrderItemRecord.UnitPrice = 20;
        insert purchaseOrderItemRecord;
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = purchaseOrderRecord.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        OrderItem purchaseOrderItemRecord2 = new OrderItem();
        purchaseOrderItemRecord2.OrderId = purchaseOrderRecord.Id;
        purchaseOrderItemRecord2.PricebookEntryId = supPbe.Id;
        purchaseOrderItemRecord2.Product2Id = supProd.Id;
        purchaseOrderItemRecord2.Location__c = locProd.Location__c;
        purchaseOrderItemRecord2.Quantity = 1;
        purchaseOrderItemRecord2.UnitPrice = 20;
        insert purchaseOrderItemRecord2;
        
        Inventory_Movement__c invMovement = new Inventory_Movement__c(Product__c = prod.Id, Location__c = locationRecord.Id, Movement__c = 100);
        insert invMovement;
        
        NAO_ERP_Custom_Settings__c naoErp =  new NAO_ERP_Custom_Settings__c(Ignore_Purchase_Orders_Before_Activation__c = null,
                                                                            Ignore_SO_before_Activation_Date__c = null,
                                                                            Name = 'Order Date Settings');
        insert naoErp;
        
        Goods_Received_Notice_bric__c grn = new Goods_Received_Notice_bric__c(GRN_Reference_Number__c = '123',
                                                                              Order_bric__c = purchaseOrderRecord.Id,
                                                                              Status__c = 'Open');
        insert grn;
        
        Purchase_Order_Products_Received_bric__c grnLine1 =  new Purchase_Order_Products_Received_bric__c(Goods_Received_Notice_bric__c = grn.Id,
                                                                                                          Order_bric__c = purchaseOrderRecord.Id,
                                                                                                          Order_Product_bric__c = purchaseOrderItemRecord.Id,
                                                                                                          Product_bric__c = purchaseOrderItemRecord.Product2Id,
                                                                                                          Order_Quantity__c = purchaseOrderItemRecord.Quantity,
                                                                                                          Amount_Received__c = 0);
        insert grnLine1;
        
        Purchase_Order_Products_Received_bric__c grnLine2 =  new Purchase_Order_Products_Received_bric__c(Goods_Received_Notice_bric__c = grn.Id,
                                                                                                          Order_bric__c = purchaseOrderRecord.Id,
                                                                                                          Order_Product_bric__c = purchaseOrderItemRecord2.Id,
                                                                                                          Product_bric__c = purchaseOrderItemRecord2.Product2Id,
                                                                                                          Order_Quantity__c = purchaseOrderItemRecord2.Quantity,
                                                                                                          Amount_Received__c = 0);
        insert grnLine2;
    }
    
    static testMethod void insertPurchaseOrder_Test(){
        
        Product2 prod = [SELECT Id from Product2 WHERE RecordTypeId =: supplierProductRecordTypeId];
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Account acc = [SELECT Id FROM Account];
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();
        
        Order purchaseOrderRecord = new Order();
        purchaseOrderRecord.AccountId = acc.Id;
        purchaseOrderRecord.EffectiveDate = Date.today();
        purchaseOrderRecord.RecordTypeId = purchaseOrderRecordTypeId;
        purchaseOrderRecord.Status = 'Draft';
        purchaseOrderRecord.Pricebook2Id = standardPricebookId;
        purchaseOrderRecord.Inventory_Location__c = locProd.Location__c;
        insert purchaseOrderRecord;
        
        Test.stopTest();
        
    }
    
    static testMethod void updateSalesOrder_Test(){
        
        Product2 prod = [SELECT Id from Product2 WHERE RecordTypeId =: standardProductRecordTypeId];
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order salesOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: salesOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();   
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = salesOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        salesOrder.Pricebook2Id = standardPricebookId;
        salesOrder.Inventory_Location__c = locProd.Location__c;
        salesOrder.Status = 'Activated';
        salesOrder.Picked__c = TRUE;
        update salesOrder;
        Test.stopTest();
        
    }
    
    static testMethod void updatePurchaseOrder_Test(){
        
        Product2 prod = [SELECT Id from Product2 WHERE RecordTypeId =: supplierProductRecordTypeId];
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order purchaseOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: purchaseOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();    
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = purchaseOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        purchaseOrder.Pricebook2Id = standardPricebookId;
        purchaseOrder.Inventory_Location__c = locProd.Location__c;
        purchaseOrder.Status = 'Activated';
        update purchaseOrder;
        Test.stopTest();
        
    }
    
    /*
*   Created By: JP Sulit (jp@bricoleurtech.com)
*   Created Date: Feb 16, 2024
*/
    static testMethod void upsertInvMovementRetrospectiveTest() {
        
        Product2 prod = [SELECT Id from Product2 WHERE RecordTypeId =: standardProductRecordTypeId];
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order salesOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: salesOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();   
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = salesOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        salesOrder.Pricebook2Id = standardPricebookId;
        salesOrder.Inventory_Location__c = locProd.Location__c;
        salesOrder.Status = 'Activated';
        salesOrder.Picked__c = TRUE;
        update salesOrder;
        
        OrderTriggerHandler.upsertInvMovementRetrospective(new List<Order> {salesOrder});
        Test.stopTest();   
    }
    
    /*
*   Created By: JP Sulit (jp@bricoleurtech.com)
*   Created Date: Feb 16, 2024
*/
    static testMethod void calculateProductTotalPOTest() {
        
        Product2 prod = [SELECT Id from Product2 WHERE RecordTypeId =: standardProductRecordTypeId];
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order salesOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: salesOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();   
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = salesOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        salesOrder.Pricebook2Id = standardPricebookId;
        salesOrder.Inventory_Location__c = locProd.Location__c;
        salesOrder.Status = 'Activated';
        salesOrder.Picked__c = TRUE;
        update salesOrder;
        
        OrderTriggerHandler.calculateProductTotalPO(new Set<Id> {prod.Id});
        Test.stopTest();   
    }
    
    /*
*   Created By: JP Sulit (jp@bricoleurtech.com)
*   Created Date: Feb 16, 2024
*/
    static testMethod void updatePurchaseOrderCS_Test(){
        
        NAO_ERP_Custom_Settings__c naoErpQry =  [SELECT Name,
                                                 Ignore_Purchase_Orders_Before_Activation__c,
                                                 Ignore_SO_before_Activation_Date__c
                                                 FROM NAO_ERP_Custom_Settings__c
                                                 WHERE Name = 'Order Date Settings'];
        
        naoErpQry.Ignore_Purchase_Orders_Before_Activation__c = Date.today().addDays(3);
        naoErpQry.Ignore_SO_before_Activation_Date__c = Date.today().addDays(5);
        update naoErpQry;
        
        
        Product2 prod = [SELECT Id, Use_This_Product_for_Re_order__c from Product2 WHERE RecordTypeId =: supplierProductRecordTypeId];
        prod.Use_This_Product_for_Re_order__c = false;
        update prod;
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order purchaseOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: purchaseOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();    
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = purchaseOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        purchaseOrder.Pricebook2Id = standardPricebookId;
        purchaseOrder.Inventory_Location__c = locProd.Location__c;
        purchaseOrder.Status = 'Activated';
        update purchaseOrder;
        
        Map<Id, Set<String>> completedOrderProductsMap = ClipperSettingUtility.getCompletedOrderProducts(new Set<Id> {purchaseOrder.Id});
        ClipperSettingUtility.calcTotalPurchaseOrders(completedOrderProductsMap);
        OrderTriggerHandler.calcTotalPurchaseOrders(completedOrderProductsMap);
        Test.stopTest();
        
    }
    
    /*
*   Created By: JP Sulit (jp@bricoleurtech.com)
*   Created Date: Feb 19, 2024
*/
    static testMethod void updatePoProdSupplier_Test(){
        
        Account acc = [SELECT Id, Type from Account limit 1];
        acc.Type = 'Supplier';
        update acc;
        
        Product2 prod = [SELECT Id, Use_This_Product_for_Re_order__c from Product2 WHERE RecordTypeId =: supplierProductRecordTypeId];
        prod.Use_This_Product_for_Re_order__c = false;
        prod.Supplier_Product__c = null;
        update prod;
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order purchaseOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: purchaseOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Product_Suppliers_bric__c ps = new Product_Suppliers_bric__c(Conversion_Factor__c = 100,
                                                                     Product_bric__c = [SELECT Id from Product2 WHERE RecordTypeId =: standardProductRecordTypeId].Id,
                                                                     Supplier_Product_bric__c = prod.Id,
                                                                     Supplier_bric__c = acc.Id);
        insert ps;
        
        Test.startTest();    
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = purchaseOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        purchaseOrder.Pricebook2Id = standardPricebookId;
        purchaseOrder.Inventory_Location__c = locProd.Location__c;
        purchaseOrder.Status = 'Activated';
        update purchaseOrder;
        
        Map<Id, Set<String>> completedOrderProductsMap = ClipperSettingUtility.getCompletedOrderProducts(new Set<Id> {purchaseOrder.Id});
        ClipperSettingUtility.calcTotalPurchaseOrders(completedOrderProductsMap);
        OrderTriggerHandler.calcTotalPurchaseOrders(completedOrderProductsMap);
        Test.stopTest();
        
    }
    
    static testMethod void productReorderTest(){
        
        Account acc = [SELECT Id, Type from Account limit 1];
        acc.Type = 'Supplier';
        update acc;
        
        Product2 prod = [SELECT Id, Use_This_Product_for_Re_order__c from Product2 WHERE RecordTypeId =: supplierProductRecordTypeId];
        prod.Use_This_Product_for_Re_order__c = false;
        prod.Supplier_Product__c = null;
        update prod;
        
        Product2 stdProd = [SELECT Id, Use_This_Product_for_Re_order__c from Product2 WHERE RecordTypeId =: standardProductRecordTypeId];
        prod.Use_This_Product_for_Re_order__c = true;
        update prod;
        
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order purchaseOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: purchaseOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Product_Suppliers_bric__c ps = new Product_Suppliers_bric__c(Conversion_Factor__c = 100,
                                                                     Product_bric__c = stdProd.Id,
                                                                     Supplier_Product_bric__c = prod.Id,
                                                                     Supplier_bric__c = acc.Id);
        insert ps;
        
        Test.startTest();    
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = purchaseOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        purchaseOrder.Pricebook2Id = standardPricebookId;
        purchaseOrder.Inventory_Location__c = locProd.Location__c;
        purchaseOrder.Status = 'Activated';
        update purchaseOrder;
        
        Map<Id, Set<String>> completedOrderProductsMap = ClipperSettingUtility.getCompletedOrderProducts(new Set<Id> {purchaseOrder.Id});
        ClipperSettingUtility.calcTotalPurchaseOrders(completedOrderProductsMap);
        OrderTriggerHandler.calcTotalPurchaseOrders(completedOrderProductsMap);
        Test.stopTest();
        
    }
    static testMethod void orderCompleted_Test(){
        
        // NAO_ERP_Custom_Settings__c naoErpQry =  [SELECT Name,
        //                                                 Ignore_Purchase_Orders_Before_Activation__c,
        //                                                 Ignore_SO_before_Activation_Date__c
        //                                                 FROM NAO_ERP_Custom_Settings__c
        //                                                 WHERE Name = 'Order Date Settings'];
        
        // naoErpQry.Ignore_Purchase_Orders_Before_Activation__c = Date.today().addDays(3);
        // naoErpQry.Ignore_SO_before_Activation_Date__c = Date.today().addDays(5);
        // update naoErpQry;
        
        Goods_Received_Notice_bric__c grn = [SELECT Id, Status__c FROM Goods_Received_Notice_bric__c limit 1];
        grn.Status__c = 'Completed';
        update grn;
        
        List<Purchase_Order_Products_Received_bric__c> grnLineList = [SELECT Order_Product_bric__c, Product_bric__c, Goods_Received_Notice_bric__r.Order_bric__r.Inventory_Location__c,
                                                                      Amount_Received__c, Goods_Received_Notice_bric__r.Status__c FROM Purchase_Order_Products_Received_bric__c where Goods_Received_Notice_bric__c =: grn.Id];
        
        for(Purchase_Order_Products_Received_bric__c grnLine : grnLineList) {
            System.debug('grnLine bric '+grnLine.Goods_Received_Notice_bric__r.Status__c);
        }
        
        Product2 prod = [SELECT Id, Use_This_Product_for_Re_order__c from Product2 WHERE RecordTypeId =: supplierProductRecordTypeId];
        prod.Use_This_Product_for_Re_order__c = false;
        update prod;
        PricebookEntry pbe = [SELECT Id from PricebookEntry where Product2Id =: prod.Id];
        Location_Product__c locProd = [SELECT Location__c,Id,Product__c FROM Location_Product__c];
        Order purchaseOrder = [SELECT Id,RecordTypeId,Pricebook2Id,Inventory_Location__c from Order WHERE RecordTypeId =: purchaseOrderRecordTypeId];
        
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();    
        
        OrderItem ordItem = new OrderItem();
        ordItem.OrderId = purchaseOrder.Id;
        ordItem.PricebookEntryId = pbe.Id;
        ordItem.Location__c = locProd.Location__c;
        ordItem.Quantity = 1;
        ordItem.UnitPrice = 20;
        insert ordItem;
        
        purchaseOrder.Pricebook2Id = standardPricebookId;
        purchaseOrder.Inventory_Location__c = locProd.Location__c;
        purchaseOrder.Status = 'Completed';
        update purchaseOrder;
        
        Map<Id, Set<String>> completedOrderProductsMap = ClipperSettingUtility.getCompletedOrderProducts(new Set<Id> {purchaseOrder.Id});
        ClipperSettingUtility.calcTotalPurchaseOrders(completedOrderProductsMap);
        OrderTriggerHandler.calcTotalPurchaseOrders(completedOrderProductsMap);
        Test.stopTest();
        
    }
/*
* Author : Nagendra Yanadigalla
* Apex Class : OrderTriggerHandler
* Apex Method : getNextOrderDates
*/
    //STARTS
    @isTest
    static void testGetNextOrderDatesDaily() {
        Id salesOrderTemplateRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order_Template' AND SObjectType = 'Order' LIMIT 1].Id;
        Id salesOrderRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order' AND SObjectType = 'Order' LIMIT 1].Id;
        
        // Create Account and Contacts
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact billToContact = new Contact(LastName = 'Bill To Contact', AccountId = acc.Id);
        insert billToContact;
        
        Contact shipToContact = new Contact(LastName = 'Ship To Contact', AccountId = acc.Id);
        insert shipToContact;
        // Test for daily recurrence
        Order order = new Order(
            AccountId = acc.Id,
            billToContactid = billToContact.Id,
            shipToContactid = shipToContact.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate= Date.today() - 5,
            Status = 'Draft',
            RecordTypeId = salesOrderTemplateRTId,
            Name = 'Test Daily Order',
            Recurrence_Frequency__c = 'Daily',
            Snooze_Order__c = false,
            Recurrence_End_Date__c = Date.today().addDays(10)
        );
        insert order;
        
        // Call the method
        Map<Id, Date> result = OrderTriggerHandler.getNextOrderDates(new List<Order>{order});
        
        // Validate that the next occurrence date is the following day
        System.assertEquals(Date.today().addDays(1), result.get(order.Id), 'Next occurrence should be the following day');
    }
    @isTest
    static void testGetNextOrderDatesWeekly() {
        
        Id salesOrderTemplateRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order_Template' AND SObjectType = 'Order' LIMIT 1].Id;
        Id salesOrderRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order' AND SObjectType = 'Order' LIMIT 1].Id;
        
        // Create Account and Contacts
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact billToContact = new Contact(LastName = 'Bill To Contact', AccountId = acc.Id);
        insert billToContact;
        
        Contact shipToContact = new Contact(LastName = 'Ship To Contact', AccountId = acc.Id);
        insert shipToContact;
        // Test for Weekly recurrence
        Order order = new Order(
            AccountId = acc.Id,
            billToContactid = billToContact.Id,
            shipToContactid = shipToContact.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate= Date.today() - 5,
            Status = 'Draft',
            RecordTypeId = salesOrderTemplateRTId,
            Name = 'Test Weekly Order',
            Recurrence_Frequency__c = 'Weekly',
            Recurrence_Weekdays__c = 'Sunday;Thursday',
            Snooze_Order__c = false,
            Recurrence_End_Date__c = Date.today().addDays(30)
        );
        insert order;
        
        // Call the method
        Map<Id, Date> result = OrderTriggerHandler.getNextOrderDates(new List<Order>{order});
        
        // Determine the expected next occurrence 
        Date today = Date.today();
        Date expectedNextDate = null;
        List<Integer> recurrenceDays = new List<Integer>{1, 5}; 
            
            for (Integer i = 1; i <= 7; i++) {
                Date potentialDate = today.addDays(i);
                Integer dayOfWeek = potentialDate.toStartOfWeek().daysBetween(potentialDate) + 1;
                if (recurrenceDays.contains(dayOfWeek)) {
                    expectedNextDate = potentialDate;
                    break;
                }
            }
        
        // Validate that the calculated next occurrence matches the method result
        System.assertEquals(expectedNextDate, result.get(order.Id), 'Next occurrence should be the closest recurrence weekday');
    }
    
    @isTest
    static void testGetNextOrderDatesMonthlySpecificDay() {
        
        Id salesOrderTemplateRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order_Template' AND SObjectType = 'Order' LIMIT 1].Id;
        Id salesOrderRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order' AND SObjectType = 'Order' LIMIT 1].Id;
        
        // Create Account and Contacts
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact billToContact = new Contact(LastName = 'Bill To Contact', AccountId = acc.Id);
        insert billToContact;
        
        Contact shipToContact = new Contact(LastName = 'Ship To Contact', AccountId = acc.Id);
        insert shipToContact;
        // Test for Monthly recurrence
        Order order = new Order(
            AccountId = acc.Id,
            billToContactid = billToContact.Id,
            shipToContactid = shipToContact.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate= Date.today() - 5,
            Status = 'Draft',
            RecordTypeId = salesOrderTemplateRTId,
            Name = 'Test Monthly Order',
            Recurrence_Frequency__c = 'Monthly',
            Recurrence_When__c = 'Specific Days',
            Specific_Day__c = '5',  
            Snooze_Order__c = false,
            Recurrence_End_Date__c = Date.today().addMonths(2)
        );
        insert order;
        
        // Call the method
        Map<Id, Date> result = OrderTriggerHandler.getNextOrderDates(new List<Order>{order});
        
        // Validate that the next occurrence is the specified day
        Date expectedNextDate = Date.newInstance(Date.today().year(), Date.today().month(), 5);
        if (expectedNextDate < Date.today()) {
            expectedNextDate = expectedNextDate.addMonths(1);
        }
        System.assertEquals(expectedNextDate, result.get(order.Id), 'Next occurrence should be the specified day of the month');
    }
    
    @isTest
    static void testGetNextOrderDatesMonthlyRelativeDay() {
        
        Id salesOrderTemplateRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order_Template' AND SObjectType = 'Order' LIMIT 1].Id;
        Id salesOrderRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order' AND SObjectType = 'Order' LIMIT 1].Id;
        
        // Create Account and Contacts
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact billToContact = new Contact(LastName = 'Bill To Contact', AccountId = acc.Id);
        insert billToContact;
        
        Contact shipToContact = new Contact(LastName = 'Ship To Contact', AccountId = acc.Id);
        insert shipToContact;
        // Test for Monthly recurrence
        Order order = new Order(
            AccountId = acc.Id,
            billToContactid = billToContact.Id,
            shipToContactid = shipToContact.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate= Date.today() - 5,
            Status = 'Draft',
            RecordTypeId = salesOrderTemplateRTId,
            Name = 'Test Monthly Order Relative',
            Recurrence_Frequency__c = 'Monthly',
            Recurrence_When__c = 'Relative Days',
            Relative_Day__c = 'First', 
            Relative_Day_Repeat_On__c = 'Monday', 
            Snooze_Order__c = false,
            Recurrence_End_Date__c = Date.today().addMonths(2)
        );
        Order order1 = new Order(
            AccountId = acc.Id,
            billToContactid = billToContact.Id,
            shipToContactid = shipToContact.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate= Date.today() - 5,
            Status = 'Draft',
            RecordTypeId = salesOrderTemplateRTId,
            Name = 'Test Monthly Order Relative',
            Recurrence_Frequency__c = 'Monthly',
            Recurrence_When__c = 'Relative Days',
            Relative_Day__c = 'First', 
            Relative_Day_Repeat_On__c = 'Monday', 
            Snooze_Order__c = true,
            Snooze_End_Date__c = Date.today()+10,
            Recurrence_End_Date__c = Date.today().addMonths(2)
        );
        insert order1;
        insert order;
        
        // Call the method
        Map<Id, Date> result = OrderTriggerHandler.getNextOrderDates(new List<Order>{order,order1});
      }
    
    @isTest
    static void testGetNextOrderDatesWithSnooze() {
        
        Id salesOrderTemplateRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order_Template' AND SObjectType = 'Order' LIMIT 1].Id;
        Id salesOrderRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order' AND SObjectType = 'Order' LIMIT 1].Id;
        
        // Create Account and Contacts
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact billToContact = new Contact(LastName = 'Bill To Contact', AccountId = acc.Id);
        insert billToContact;
        
        Contact shipToContact = new Contact(LastName = 'Ship To Contact', AccountId = acc.Id);
        insert shipToContact;
        // Test for daily recurrence
        Order order = new Order(
            AccountId = acc.Id,
            billToContactid = billToContact.Id,
            shipToContactid = shipToContact.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate= Date.today() - 5,
            Status = 'Draft',
            RecordTypeId = salesOrderTemplateRTId,
            Name = 'Test Snoozed Order',
            Recurrence_Frequency__c = 'Daily',
            Snooze_Order__c = true,
            Snooze_Start_Date__c = Date.today().addDays(-2),
            Snooze_End_Date__c = Date.today().addDays(3)
        );
        insert order;
        
        // Call the method
        Map<Id, Date> result = OrderTriggerHandler.getNextOrderDates(new List<Order>{order});
        
        // Validate that the next occurrence is the day after snooze end date
        Date expectedNextDate = Date.today().addDays(4);
        System.assertEquals(expectedNextDate, result.get(order.Id), 'Next occurrence should be the day after snooze end date');
    }
    //ENDS
}