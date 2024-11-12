@isTest
public class OrderPickPdfControllerTest {

    public static final Id salesOrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();

    private static List<Order_Pick__c> orderPickList = new List<Order_Pick__c>(); 

    @TestSetup
    static void testData() {
        List<Account> accList = CreateAccount(1, true);
        List<Opportunity> oppList = CreateOpportunity(1, accList[0].Id, true);
        List<Product2> prodList = CreateProducts(3, true);
        List<Schema.Location> locationList = createLocations(1, true);
        List<PricebookEntryParameters> pbeParamList = new List<PricebookEntryParameters>();
        for(Integer i = 0; i < prodList.size(); i++) {
            PricebookEntryParameters pbeParam = new PricebookEntryParameters();
            pbeParam.PricebookId = Test.getStandardPricebookId();
            pbeParam.ProductId = prodList[i].Id;
            pbeParam.UnitPrice = i + 10;
            pbeParamList.add(pbeParam); 
        }
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        List<PricebookEntry> pbeList1 = CreatePricebookEntries(1, pbeParamList[0], true);
        List<PricebookEntry> pbeList2 = CreatePricebookEntries(1, pbeParamList[1], true);
        List<PricebookEntry> pbeList3 = CreatePricebookEntries(1, pbeParamList[2], true);
        pbeList.addAll(new List<PricebookEntry> {pbeList1[0], pbeList2[0], pbeList3[0]});
        List<OpportunityLineItemParameters> oppLineParamList = new List<OpportunityLineItemParameters>();
        for(Integer i = 0; i < pbeList.size(); i++) {
            OpportunityLineItemParameters oppLineParam = new OpportunityLineItemParameters();
            oppLineParam.OppId = oppList[0].Id;
            oppLineParam.PbeId = pbeList[i].Id;
            oppLineParam.Quantity = i + 10;
            oppLineParam.PbeUnitPrice = pbeList[i].UnitPrice;
            oppLineParamList.add(oppLineParam); 
        }
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppLineList1 = CreateOpportunityLineItems(10, oppLineParamList[0], true);
        List<OpportunityLineItem> oppLineList2 = CreateOpportunityLineItems(10, oppLineParamList[1], true);
        List<OpportunityLineItem> oppLineList3 = CreateOpportunityLineItems(10, oppLineParamList[2], true);
        OrderParameters orderParam = new OrderParameters();
        orderParam.accId = accList[0].Id;
        orderParam.oppId = oppList[0].Id;
        orderParam.warehouseId = locationList[0].Id;
        List<Order> orderList = createOrders(1, orderParam, true);
        List<OrderItem> orderItemList = createOrderProducts(pbeList, orderList[0].Id, true);
        orderPickList = createOrderPicks(1, orderList[0].Id, locationList[0].Id, true);
        List<Order_Pick_Line__c> orderPickLineList = createOrderPickLines(orderPickList[0].Id, orderItemList, true);
    }

    @IsTest
    static void testConstructor() {
        // Simulate the parameters that would be passed to the controller
        String testObjectName = 'Order_Pick__c';
        String testRecordId = [SELECT Id FROM Order_Pick__c LIMIT 1].Id;
        String testChildObjName = 'Order_Pick_Line__c';
        String testLogoUrl = 'http://example.com/logo.png';

        // Simulate the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/PickingTicketPDF'));
        ApexPages.currentPage().getParameters().put('sObjectType', testObjectName);
        ApexPages.currentPage().getParameters().put('Id', testRecordId);
        ApexPages.currentPage().getParameters().put('childSObjectType', testChildObjName);
        ApexPages.currentPage().getParameters().put('pdfLogo', testLogoUrl);
    }

    @IsTest
    static void testRecordListPopulation() {
        // Simulate the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/PickingTicketPDF'));
        ApexPages.currentPage().getParameters().put('sObjectType', 'Order_Pick__c');
        ApexPages.currentPage().getParameters().put('Id', [SELECT Id FROM Order_Pick__c LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('childSObjectType', 'Order_Pick_Line__c');

        // Instantiate the controller
        OrderPickPdfController controller = new OrderPickPdfController();

        // Validate that the recordList is populated as expected
        System.assertNotEquals(null, controller.recordList, 'recordList should be populated.');
        System.assert(controller.recordList.size() > 0, 'recordList should contain records.');
    }

    public class PricebookEntryParameters
    {
        public String PricebookId; 
        public String ProductId;
        public Decimal UnitPrice;
    }
    
    public class OpportunityLineItemParameters
    {
        public String OppId;
        public String PbeId;
        public Decimal Quantity;
        public Decimal PbeUnitPrice;
    }
    
    public static List<Account> CreateAccount(Integer qty , Boolean isInsert)
    {
        List<Account> accountList = new List<Account>();
        
        for(Integer ctr = 0; ctr < qty; ctr++)
        {
            Account accountRecord = new Account();
            accountRecord.Name = 'testAccount' + ctr;
            
            accountList.add(accountRecord);
        }
        
        if(isInsert) 
            Insert accountList;
        return accountList;
    }
    
    public static List<Account> CreateAccounts(Integer quantity , Boolean isInsert)
    {
        List<Account> accountsToInsert = new List<Account>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            Account newAccount = new Account();
            newAccount.Name = 'testAccount' + ctr;
            newAccount.Phone = '22222';
            newAccount.Fax = '33333';
            newAccount.ShippingStreet = 'testStreet' + ctr;
            newAccount.ShippingCity = 'testCity' + ctr;
            newAccount.ShippingState = 'testState' + ctr;
            newAccount.ShippingPostalCode = 'testPostalCode' + ctr;
            newAccount.ShippingCountry = 'testCountry' + ctr;
            accountsToInsert.add(newAccount);
        }
        
        if(!accountsToInsert.isEmpty() && isInsert) Insert accountsToInsert;
        
        return accountsToInsert;
    }
    
    public static List<Contact> createContacts(List<Account> acctList, Boolean isInsert)
    {
        List<Contact> conList = new List<Contact>();
        Integer ctr = 0;
        for(Account acc :  acctList)
        {
            Contact con = new Contact();
            con.FirstName = 'Fname '+ctr;
            con.LastName = 'LName '+ctr;
            con.AccountId = acc.Id;
            con.Email = 'sample'+ctr+'@email.com';
            con.MobilePhone = '1234567890';
            conList.add(con);
            ctr++;
        }
        if(isInsert)
            insert conList;
        return conList;
    }


    public static List<Contact> CreateContacts(Integer quantity , String acctId, Boolean isInsert)
    {
        List<Contact> contactsToInsert = new List<Contact>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            Contact newContact = new Contact();
            newContact.FirstName = 'testFirstName';
            newContact.LastName = 'testLastName' + ctr;
            newContact.AccountId = acctId;   
            contactsToInsert.add(newContact);
        }
        
        if(!contactsToInsert.isEmpty() && isInsert) Insert contactsToInsert;
        
        return contactsToInsert;
    }
    
    public static List<Opportunity> CreateOpportunities(Integer quantity , String acctId , String conId , Boolean isInsert)
    {
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            Opportunity newOpportunity = new Opportunity();
            newOpportunity.Name = 'testOpportunity' + ctr;
            newOpportunity.StageName = 'Prospecting';
            newOpportunity.CloseDate = System.today();
            newOpportunity.AccountId = acctId;
            newOpportunity.ContactId = conId;
            opportunitiesToInsert.add(newOpportunity);
        }
        
        if(!opportunitiesToInsert.isEmpty() && isInsert) Insert opportunitiesToInsert;
        
        return opportunitiesToInsert;
    }
    
    public static List<Product2> CreateProducts(Integer quantity , Boolean isInsert)
    {
        List<Product2> productsToInsert = new List<Product2>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            Product2 newProduct = new Product2();
            newProduct.Name = 'testProduct' + ctr;
            newProduct.ProductCode = 'testCode' + ctr;
            newProduct.isActive = TRUE;
            productsToInsert.add(newProduct);
        }
        
        if(!productsToInsert.isEmpty() && isInsert) Insert productsToInsert;
        
        return productsToInsert;
    }
    
    public static List<PricebookEntry> CreatePricebookEntries(Integer quantity , PricebookEntryParameters Params, Boolean isInsert)
    {
        List<PricebookEntry> pricebookEntriesToInsert = new List<PricebookEntry>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            PricebookEntry newPricebookEntry = new PricebookEntry();
            newPricebookEntry.Pricebook2Id = Params.PricebookId;
            newPricebookEntry.Product2Id = Params.ProductId;
            newPricebookEntry.UnitPrice = Params.UnitPrice;
            newPricebookEntry.IsActive = TRUE;
            pricebookEntriesToInsert.add(newPricebookEntry);
        }
        
        if(!pricebookEntriesToInsert.isEmpty() && isInsert) Insert pricebookEntriesToInsert;
        
        return pricebookEntriesToInsert;
    }

    public static List<Opportunity> CreateOpportunity(Integer qty , String accountId , Boolean isInsert)
    {
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer ctr = 0; ctr < qty; ctr++)
        {
            Opportunity opportunityRec = new Opportunity();
            opportunityRec.Name = 'testOpportunity' + qty;
            opportunityRec.StageName = 'Qualification';
            opportunityRec.CloseDate = System.today().addDays(30);
            opportunityRec.AccountId = accountId;
            
            opportunityList.add(opportunityRec);
        }
        
        if(isInsert) 
            Insert opportunityList;
        return opportunityList;
    }
    
    public static List<OpportunityLineItem> CreateOpportunityLineItems(Integer quantity , OpportunityLineItemParameters params, Boolean isInsert)
    {
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        
        for(Integer ctr = 0; ctr < quantity; ctr++)
        {
            OpportunityLineItem newOpportunityLineItem = new OpportunityLineItem();
            newOpportunityLineItem.OpportunityId = params.OppId;
            newOpportunityLineItem.PricebookEntryId = params.PbeId;
            newOpportunityLineItem.Quantity = params.Quantity;
            newOpportunityLineItem.TotalPrice = params.PbeUnitPrice;
            opportunityLineItemsToInsert.add(newOpportunityLineItem);
        }
        
        if(!opportunityLineItemsToInsert.isEmpty() && isInsert) Insert opportunityLineItemsToInsert;
        
        return opportunityLineItemsToInsert;
    }
    
    public static List<ContentVersion> createContentVersions(Integer qty, Boolean isInsert)
    {
        List<ContentVersion> cvList = new List<ContentVersion>();
        
        for(Integer x = 0; x < qty; x++)
        {
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Image '+x;
            cv.PathOnClient = 'TestImage'+x+'.jpg';
            cv.VersionData = Blob.valueOf('Test Content');
            cv.IsMajorVersion = true;
            cvList.add(cv);
        }
        if(isInsert)
            insert cvList;
        return cvList;
    }
    
    public static List<ContentDocumentLink> createContentDocumentLinks(Set<String> setOfCdIds, String saId, Boolean isInsert)
    { 
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for(String cdId : setOfCdIds)
        {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = saId;
            cdl.ContentDocumentId = cdId;
            cdl.shareType = 'V';
            cdlList.add(cdl);
        }
        if(isInsert)
            insert cdlList;
        return cdlList;
    }
    
    public static List<PricebookEntry> createPBE(List<Product2> prodList, Boolean isInsert) 
    {
        List<PriceBookEntry> pbeList = new List<PricebookEntry>();
        for(Product2 prod : prodList)
        {
            PricebookEntry pbe = new PricebookEntry();
            pbe.Pricebook2Id = Test.getStandardPricebookId();
            pbe.Product2Id = prod.Id;
            pbe.UnitPrice = 10;
            pbe.isActive = true;
            pbeList.add(pbe);
        }
        if(isInsert)
            insert pbeList;
        return pbeList;
    }
    
    public static List<Order_Pick__c> createOrderPicks(Integer cnt, String orderId, String warehouseId, Boolean isInsert) {

    List<Order_Pick__c> opList = new List<Order_Pick__c>();
    
    for(Integer i = 0; i < cnt; i++) 
    {
        Order_Pick__c op = new Order_Pick__c();
        op.Order__c = orderId;
        op.Warehouse_bric__c = warehouseId;
        opList.add(op);
    }

    if(isInsert)
        insert opList;
    return opList;
    }

    public static List<Order_Pick_Line__c> createOrderPickLines(String orderPickId, List<OrderItem> oiList, Boolean isInsert) {
    
    List<Order_Pick_Line__c> opLineList = new List<Order_Pick_Line__c>();
    
    for(OrderItem oi : oiList) {
        Order_Pick_Line__c opl = new Order_Pick_Line__c();
        opl.Order_Pick__c = orderPickId;
        opl.Order_Product__c = oi.Id;
        opl.Product__c = oi.Product2Id;
        opl.Open_Order_Quantity__c = oi.Quantity;
        opLineList.add(opl);
    }
    
    if(isInsert)
        insert opLineList;
    return opLineList;
    }

    public class OrderParameters {
    public String accId;
    public String oppId;
    public String warehouseId;
    }

    public static List<Order> createOrders(Integer cnt, OrderParameters orderParam, Boolean isInsert) {
    
        List<Order> orderList = new List<Order>();

        for(Integer i = 0; i < cnt; i++) {
            Order o = new Order();
            o.AccountId = orderParam.accId;
            o.OpportunityId = orderParam.oppId;
            o.EffectiveDate = System.today();
            o.Status = 'Draft';
            o.PriceBook2Id = Test.getStandardPricebookId();
            orderList.add(o);
        }

        if(isInsert)
            insert orderList;
        return orderList;
    }

    public static List<OrderItem> createOrderProducts(List<PricebookEntry> pbeList, String orderId, Boolean isInsert) {
    
    List<OrderItem> orderItemList = new List<OrderItem>();

    for(PricebookEntry pbe : pbeList) {
        OrderItem lineItem = new OrderItem();
        lineItem.OrderId = orderId;
        lineItem.Quantity = 1;
        lineItem.UnitPrice = pbe.UnitPrice;
        lineItem.Product2id = pbe.Product2Id;
        lineItem.PricebookEntryId = pbe.Id;
        orderItemList.add(lineItem);
    }

    if(isInsert)
        insert orderItemList;
    return orderItemList;
    }

    public static List<Schema.Location> createLocations(Integer cnt, Boolean isInsert) {
    
    List<Schema.Location> locationList = new List<Schema.Location>();
    
    for(Integer i = 0; i < cnt; i++) {
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location '+i;
        loc.LocationType = 'Warehouse';
        locationList.add(loc);
    }

    if(isInsert)
        insert locationList;
    return locationList;
    }
}