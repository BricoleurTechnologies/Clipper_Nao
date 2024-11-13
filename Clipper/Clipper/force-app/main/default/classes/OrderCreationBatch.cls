global class OrderCreationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date today = Date.today();
        String query = 'SELECT Id,Recurrence_Frequency__c,Recurrence_End_Date__c, AccountId, BillToContactId, ShipToContactId, ' +
            'Next_Recurring_Order_Date__c, Generate_Draft_Order_Days_Prior__c, ' +
            'Description, Inventory_Location__c, Type, Pricebook2Id, ' +
            'Recurring__c, Snooze_order__c, BillingAddress, ShippingAddress ' +
            'FROM Order ' +
            'WHERE RecordType.DeveloperName = \'Sales_Order_Template\' ' +
            'AND Recurring__c = TRUE ' +
            'AND Snooze_order__c = FALSE ' +
            'AND Next_Recurring_Order_Date__c = :today';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Order> orderTemplates) {
        List<Order> newOrdersToInsert = new List<Order>();
        List<OrderItem> newOrderLineItemsToInsert = new List<OrderItem>();
        List<Exception_Log__c> errorLogs = new List<Exception_Log__c>();

        Id salesOrderRecordTypeId = getSalesOrderRecordTypeId();

        for (Order orderTemplate : orderTemplates) {
            if (!existingOrderExists(orderTemplate)) {
                try {
                    Order newOrder = createOrder(orderTemplate, salesOrderRecordTypeId);
                    newOrdersToInsert.add(newOrder);
                    updateNextRecurringOrderDate(orderTemplate); // Update the next recurring date
                } catch (Exception e) {
                    errorLogs.add(logException(e));
                }
            }
        }

        if (!newOrdersToInsert.isEmpty()) {
            try {
                insert newOrdersToInsert;
            } catch (Exception e) {
                errorLogs.add(logException(e));
            }

            insertOrderLineItems(newOrdersToInsert, orderTemplates, newOrderLineItemsToInsert, errorLogs);
        }

        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }

    private Id getSalesOrderRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE DeveloperName = 'Sales_Order' LIMIT 1].Id;
    }

    private Boolean existingOrderExists(Order orderTemplate) {
        return ![SELECT Id FROM Order 
                  WHERE RecordType.DeveloperName = 'Sales_Order' 
                  AND AccountId = :orderTemplate.AccountId 
                  AND EffectiveDate = :Date.today() 
                  AND Replace_Scheduled_Order__c = TRUE].isEmpty();
    }

    private Order createOrder(Order orderTemplate, Id salesOrderRecordTypeId) {
        Order newOrder = new Order();
        newOrder.AccountId = orderTemplate.AccountId;
        newOrder.BillToContactId = orderTemplate.BillToContactId;
        newOrder.ShipToContactId = orderTemplate.ShipToContactId;

        Date orderStartDate = orderTemplate.Next_Recurring_Order_Date__c;
        if (orderTemplate.Generate_Draft_Order_Days_Prior__c != null) {
            orderStartDate = orderStartDate.addDays(Integer.valueOf(orderTemplate.Generate_Draft_Order_Days_Prior__c));
        }
        newOrder.EffectiveDate = orderStartDate;
        newOrder.Status = 'Draft';
        newOrder.Description = orderTemplate.Description;
        newOrder.Inventory_Location__c = orderTemplate.Inventory_Location__c;
        newOrder.Type = orderTemplate.Type;
        newOrder.Pricebook2Id = orderTemplate.Pricebook2Id;
        newOrder.RecordTypeId = salesOrderRecordTypeId;
        //newOrder.BillingAddress = orderTemplate.BillingAddress;
        //newOrder.ShippingAddress = orderTemplate.ShippingAddress;
        
        return newOrder;
    }

    private void updateNextRecurringOrderDate(Order orderTemplate) {
        // Call the helper method from OrderTriggerHandler to calculate the next recurring date
        Map<Id, Date> nextDates = OrderTriggerHandler.getNextOrderDates(new List<Order>{orderTemplate});
        if (nextDates.containsKey(orderTemplate.Id)) {
            orderTemplate.Next_Recurring_Order_Date__c = nextDates.get(orderTemplate.Id);
            update orderTemplate;
        }
    }

    private void insertOrderLineItems(List<Order> newOrders, List<Order> orderTemplates, 
                                      List<OrderItem> newOrderLineItemsToInsert, List<Exception_Log__c> errorLogs) {
        for (Order createdOrder : newOrders) {
            for (Order orderTemplate : orderTemplates) {
                if (createdOrder.AccountId == orderTemplate.AccountId) {
                    List<OrderItem> orderLineItems = fetchOrderLineItems(orderTemplate, createdOrder.Pricebook2Id);

                    for (OrderItem lineItem : orderLineItems) {
                        OrderItem newLineItem = createOrderLineItem(createdOrder.Id, lineItem);
                        newOrderLineItemsToInsert.add(newLineItem);
                    }
                }
            }
        }

        if (!newOrderLineItemsToInsert.isEmpty()) {
            try {
                insert newOrderLineItemsToInsert;
            } catch (Exception e) {
                errorLogs.add(logException(e));
            }
        }
    }

    private List<OrderItem> fetchOrderLineItems(Order orderTemplate, Id pricebook2Id) {
        return [SELECT Product2Id, PricebookEntryId, UnitPrice, Quantity, ListPrice, TotalPrice, AvailableQuantity 
                FROM OrderItem 
                WHERE OrderId = :orderTemplate.Id 
                AND PricebookEntry.Pricebook2Id = :pricebook2Id];
    }

    private OrderItem createOrderLineItem(Id orderId, OrderItem templateLineItem) {
        OrderItem newLineItem = new OrderItem();
        newLineItem.OrderId = orderId;
        newLineItem.Product2Id = templateLineItem.Product2Id;
        newLineItem.Quantity = templateLineItem.Quantity;
        newLineItem.UnitPrice = templateLineItem.UnitPrice;
        newLineItem.PricebookEntryId = templateLineItem.PricebookEntryId;
        //newLineItem.AvailableQuantity = templateLineItem.AvailableQuantity ; // Not writeable
        if (Schema.sObjectType.OrderItem.fields.ListPrice.isUpdateable()) {
            newLineItem.ListPrice = templateLineItem.ListPrice;
        }
          //  newLineItem.TotalPrice = templateLineItem.TotalPrice; // Not writeable
     
        
        return newLineItem;
    }

    private Exception_Log__c logException(Exception e) {
        return new Exception_Log__c(
            ExceptionMessage__c = e.getMessage(),
            StackTrace__c = e.getStackTraceString()
        );
    }

    global void finish(Database.BatchableContext BC) {}
}