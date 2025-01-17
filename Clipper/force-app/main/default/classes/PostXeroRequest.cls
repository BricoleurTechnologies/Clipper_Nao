/*
 * Author:          Alfonso Maquilan
 * Created Date:    May 5, 2021
 * Description:     Apex Class to Handle post request operations of Xero
 * Test Class:      XeroRequestTest
 * History:         May 05, 2021 - Creation
 *                  July 2, 2021 - Added checking for if person account enabled
*/
public class PostXeroRequest 
{    
    public static Boolean isPersonAccountEnabled = Utilities.CheckIfPersonAccountEnabled();
    
    private class MapXeroInvoiceToSalesforceSObjectReturn
    {
        private List<XeroInvoiceAndSObject> XeroInvoiceAndSObjectList;
        private List<SObject> SObjectList;
    }
    
    private class XeroInvoiceAndSObject
    {
        private RestResponseCollectionXero.Invoice XeroInvoice;
        private SObject InvoiceSObject;
    }
    
    private class XeroInvoiceFieldMapping
    {
        private XeroInboundFieldMapping__c InvoiceFieldMapping;
        private XeroInboundFieldMapping__c InvoiceLineItemFieldMapping;
    }
    
    public static Boolean UpdateAccountFromXero(String acctId , RestResponseCollectionXero.XeroContact xeroContact) 
    {
        Boolean isSuccess;
        
        Account acctRecordToUpdate = new Account();
        acctRecordToUpdate.Id = acctId;
        acctRecordToUpdate.XeroId__c = xeroContact.ContactID;
        if(xeroContact.Balances!=null){
           acctRecordToUpdate.AccountsReceivable_Outstanding__c=xeroContact.Balances.AccountsReceivable.Outstanding;
           acctRecordToUpdate.AccountsReceivable_Overdue__c=xeroContact.Balances.AccountsReceivable.Overdue;
           acctRecordToUpdate.AccountsPayable_Outstanding__c=xeroContact.Balances.AccountsPayable.Outstanding;
           acctRecordToUpdate.AccountsPayable__c=xeroContact.Balances.AccountsPayable.Overdue; 
        }
           
        system.debug('acctRecordToUpdate'+acctRecordToUpdate);
        try 
        {
            Database.Update(acctRecordToUpdate);
           // isSuccess = true;
        }
        catch(Exception err)
        {
            Utilities.CreateExceptionLog(err);
            isSuccess = false;   
        }
        
        return isSuccess;
    }
    
    public static Boolean UpdateAccountFromXeroBatch(List<RestResponseCollectionXero.XeroContact> xeroContactList , List<String> xeroContactIdList)
    {
        Boolean isSuccess;
        
        Map<String , Account> acctsToUpdateMap = RetrieveAccountsToUpdateByXeroId(xeroContactIdList);
        Map<String , Account> personAcctsToUpdateMap = new Map<String , Account>();

        if(Utilities.CheckIfPersonAccountEnabled()){
            personAcctsToUpdateMap = RetrievePersonAccountsToUpdateByXeroId(xeroContactIdList);
            MapPersonAccountFieldsFromXero(xeroContactList , personAcctsToUpdateMap);
            
            if(acctsToUpdateMap.values().isEmpty() && personAcctsToUpdateMap.values().isEmpty()){
                isSuccess = FALSE;
                return isSuccess;
            }
        
        } 
        
        if(acctsToUpdateMap.values().isEmpty() && !Utilities.CheckIfPersonAccountEnabled()){
                isSuccess = FALSE;
                return isSuccess;
        } 
        
        MapAccountFieldsFromXero(xeroContactList , acctsToUpdateMap);
        
        
        try
        {   
            if(Utilities.CheckIfPersonAccountEnabled()){
                Database.Update(personAcctsToUpdateMap.values());
            }
            Database.Update(acctsToUpdateMap.values());
            isSuccess = TRUE;
        }
        catch(Exception err)
        {
            Utilities.CreateExceptionLog(err);
            isSuccess = FALSE;   
        }
        
        return isSuccess;
    }
    
    public static Boolean UpdateOpportunityAndLineItemsFromXero(String oppId , String xeroInvoiceId, String xeroContactId , List<RestResponseCollectionXero.LineItem> invoiceLineItemList)
    {
        Boolean isSuccess;
        Savepoint sp = Database.setSavepoint();
        
        Opportunity oppRecordToUpdate = new Opportunity();
        oppRecordToUpdate.Id = oppId;
        oppRecordToUpdate.XeroId__c = xeroInvoiceId;
        
        Opportunity oppRecord = [SELECT Id,AccountId FROM Opportunity WHERE Id=:oppId];
        Account accRecord = [SELECT Id, XeroId__c FROM Account WHERE Id=:oppRecord.AccountId];
        if(accRecord?.XeroId__c == '' || accRecord?.XeroId__c == null){
            accRecord.XeroId__c = xeroContactId;
        }
        
        try
        {
            Database.Update(oppRecordToUpdate);
            Database.Update(accRecord);
            isSuccess = true;
        }
        catch(Exception err)
        {
            Database.rollback(sp);
            Utilities.CreateExceptionLog(err);
            isSuccess = false;
        }
        
        return isSuccess;
    }
    
    public static Boolean UpdateOpportunityAndLineItemsFromXeroQuote(String oppId, List<RestResponseCollectionXero.Quote> quoteList)
    {
        Boolean isSuccess;
        Savepoint sp = Database.setSavepoint();
        
        //GET Opportunity
        Opportunity opptyRecord = [SELECT Id, Pricebook2Id
                                   FROM Opportunity WHERE Id =: oppId];
        
        //GET Product2ID
        Map<String,PriceBookEntry> productXeroItemCodeMap = new Map<String,PriceBookEntry>();
        for(PriceBookEntry pbe :  [SELECT Id, Product2Id, Product2.Id, Product2.ProductCode,PriceBook2.Id 
                                   FROM PriceBookEntry 
                                   WHERE PriceBook2.Id =: opptyRecord.Pricebook2Id
                                   AND Product2.ProductCode != NULL
                                  AND IsActive = TRUE])
        {
            if(pbe.Product2.ProductCode != NULL && pbe.Product2.ProductCode != ''){
                productXeroItemCodeMap.put(pbe.Product2.ProductCode,pbe);
            }
        }
        
        //GET OppLineItems
        List<OpportunityLineItem> oppLineCurrent = [SELECT Id, XeroId__c,ProductCode,OpportunityId 
                                                          FROM OpportunityLineItem
                                                          WHERE OpportunityId =:oppId];
        
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<OpportunityLineItem> oppLineItemToUpdateList = new List<OpportunityLineItem>();

        for(RestResponseCollectionXero.Quote quote : quoteList){
            Opportunity oppRecordToUpdate = new Opportunity();
            oppRecordToUpdate.Id = oppId;
            oppRecordToUpdate.Xero_Quote_ID__c = quote.QuoteID;
            oppRecordToUpdate.Xero_Quote_Number__c = quote.QuoteNumber;
            oppRecordToUpdate.Xero_Reference__c = quote.Reference;
            oppRecordToUpdate.CloseDate = Date.valueOf(quote.DateString?.replace(CONSTANTS.XERO_OBJECT_INVOICE_DUE_DATE_EXTENSION , CONSTANTS.GENERIC_BLANK));
            if(quote.LineItems.size() < 1) oppRecordToUpdate.Amount = quote.Total;
            oppRecordToUpdate.Description = quote.Summary;
            oppRecordToUpdate.Title_Bric__c = quote.Title;
            oppRecordToUpdate.Terms_Bric__c = quote.Terms;
            oppRecordToUpdate.Total_Tax_Bric__c = quote.TotalTax;            
            oppRecordToUpdate.SubTotal_Bric__c = quote.SubTotal;
            if(!String.isBlank(quote.DateString)) oppRecordToUpdate.Issued_Date_Bric__c = Date.valueOf(quote.DateString?.replace(CONSTANTS.XERO_OBJECT_INVOICE_DUE_DATE_EXTENSION , CONSTANTS.GENERIC_BLANK));
            if(!String.isBlank(quote.ExpiryDateString)) oppRecordToUpdate.Expiry_Date_Bric__c = Date.valueOf(quote.ExpiryDateString?.replace(CONSTANTS.XERO_OBJECT_INVOICE_DUE_DATE_EXTENSION , CONSTANTS.GENERIC_BLANK));
            oppRecordToUpdate.Xero_Quote_Status__c = quote.Status;

            if(oppRecordToUpdate.Id != NULL){
                oppListToUpdate.add(oppRecordToUpdate);
                
                for(RestResponseCollectionXero.LineItem quoteLineItem : quote.LineItems)
                {
                    if(quoteLineItem.Description != 'Placeholder'){
                        OpportunityLineItem oppLineItemToUpdate = new OpportunityLineItem();
                        oppLineItemToUpdate.XeroId__c = quoteLineItem.LineItemID;                
                        oppLineItemToUpdate.Quantity = quoteLineItem.Quantity != null && quoteLineItem.Quantity != 0 ? quoteLineItem.Quantity : 1;
                        oppLineItemToUpdate.TotalPrice = quoteLineItem.LineAmount != null ? quoteLineItem.LineAmount : 0;
                        oppLineItemToUpdate.Description = quoteLineItem.Description;
                        oppLineItemToUpdate.OpportunityId = oppRecordToUpdate.Id;   
                        oppLineItemToUpdate.PricebookEntryId = productXeroItemCodeMap.get(quoteLineItem.ItemCode)?.Id;                        
                        oppLineItemToUpdateList.add(oppLineItemToUpdate);
                    }
                }
            }
        }
        try
        {
            if(!oppListToUpdate.isEmpty()) Database.Update(oppListToUpdate,false);
            if(!oppLineCurrent.isEmpty()) Database.Delete(oppLineCurrent,false);
            if(!oppLineItemToUpdateList.isEmpty()) Database.Insert(oppLineItemToUpdateList,false);
            isSuccess = true;
        }
        catch(Exception err)
        {
            Database.rollback(sp);
            Utilities.CreateExceptionLog(err);
            isSuccess = false;
        }
        
        return isSuccess;
    }
    
     public static Boolean UpdateOrderAndLineItemsFromXero(String orderId , String xeroInvoiceId, String xeroContactId , List<RestResponseCollectionXero.LineItem> invoiceLineItemList)
    {
        Boolean isSuccess;
        Savepoint sp = Database.setSavepoint();
        
        Order orderRecordToUpdate = new Order();
        orderRecordToUpdate.Id = orderId;
        orderRecordToUpdate.XeroId__c = xeroInvoiceId;
        orderRecordToUpdate.Xero_Status__c = 'Sent to Xero';
        
        Order orderRecord = [SELECT Id,AccountId FROM Order WHERE Id=:orderId];
        Account accRecord = [SELECT Id, XeroId__c FROM Account WHERE Id=:orderRecord.AccountId];
        if(accRecord?.XeroId__c == '' || accRecord?.XeroId__c == null){
            accRecord.XeroId__c = xeroContactId;
        }
        
                
        try
        {
            Database.Update(orderRecordToUpdate);
            Database.Update(accRecord);
            isSuccess = true;
        }
        catch(Exception err)
        {
            Database.rollback(sp);
            Utilities.CreateExceptionLog(err);
            isSuccess = false;
        }
        
        return isSuccess;
    }

    public static Boolean UpdateQuoteAndLineItemsFromXeroQuote(String quoteId, List<RestResponseCollectionXero.Quote> quoteList)
    {
        Boolean isSuccess;
        Savepoint sp = Database.setSavepoint();
        
        //GET Quote
        Quote quoteRecord = [SELECT Id, Pricebook2Id
                                   FROM Quote WHERE Id =: quoteId];
        
        //GET Product2ID
        Map<String,PriceBookEntry> productXeroItemCodeMap = new Map<String,PriceBookEntry>();
        for(PriceBookEntry pbe :  [SELECT Id, Product2Id, Product2.Id, Product2.ProductCode,PriceBook2.Id 
                                   FROM PriceBookEntry 
                                   WHERE PriceBook2.Id =: quoteRecord.Pricebook2Id
                                   AND Product2.ProductCode != NULL
                                   AND IsActive = TRUE])
        {
            if(pbe.Product2.ProductCode != NULL && pbe.Product2.ProductCode != ''){
                productXeroItemCodeMap.put(pbe.Product2.ProductCode,pbe);
            }
        }
        
        //GET QuoteLineItems
        List<QuoteLineItem> quoteLineCurrent = [SELECT Id, Product2.ProductCode,QuoteId 
                                                          FROM QuoteLineItem
                                                          WHERE QuoteId =:quoteId];
        
        List<Quote> quoteListToUpdate = new List<Quote>();
        List<QuoteLineItem> quoteLineItemToUpdateList = new List<QuoteLineItem>();

        for(RestResponseCollectionXero.Quote quote : quoteList){
            Quote quoteRecordToUpdate = new Quote();
            quoteRecordToUpdate.Id = quoteId;
            quoteRecordToUpdate.Xero_Quote_ID__c = quote.QuoteID;
            quoteRecordToUpdate.Xero_Quote_Number__c = quote.QuoteNumber;
            quoteRecordToUpdate.Name = quote.QuoteNumber;
            quoteRecordToUpdate.Description = quote.Summary?.abbreviate(32000);
            if(!String.isBlank(quote.Title)) quoteRecordToUpdate.Title__c = quote.Title;
            quoteRecordToUpdate.Terms__c = quote.Terms;
            quoteRecordToUpdate.Tax = quote.TotalTax;            
            if(!String.isBlank(quote.DateString)) quoteRecordToUpdate.Issued_Date__c = Date.valueOf(quote.DateString?.replace(CONSTANTS.XERO_OBJECT_INVOICE_DUE_DATE_EXTENSION , CONSTANTS.GENERIC_BLANK));
            if(!String.isBlank(quote.ExpiryDateString)) quoteRecordToUpdate.ExpirationDate = Date.valueOf(quote.ExpiryDateString?.replace(CONSTANTS.XERO_OBJECT_INVOICE_DUE_DATE_EXTENSION , CONSTANTS.GENERIC_BLANK));
            quoteRecordToUpdate.Status = quote.Status;

            if(quoteRecordToUpdate.Id != NULL){
                quoteListToUpdate.add(quoteRecordToUpdate);
                
                for(RestResponseCollectionXero.LineItem quoteLineItem : quote.LineItems)
                {
                    if(quoteLineItem.Description != 'Placeholder' && quoteLineItem.ItemCode != null && quoteLineItem.ItemCode != ''){
                        QuoteLineItem quoteLineItemToUpdate = new QuoteLineItem();
                        quoteLineItemToUpdate.XeroId__c = quoteLineItem.LineItemID;                
                        quoteLineItemToUpdate.Quantity = quoteLineItem.Quantity != null && quoteLineItem.Quantity != 0 ? quoteLineItem.Quantity : 1;
                        quoteLineItemToUpdate.UnitPrice = quoteLineItem.UnitAmount != null ? quoteLineItem.UnitAmount : 0;
                        quoteLineItemToUpdate.Description = quoteLineItem.Description?.abbreviate(255);
                        quoteLineItemToUpdate.QuoteId = quoteRecordToUpdate.Id;   
                        quoteLineItemToUpdate.Discount = quoteLineItem.DiscountRate;
                        quoteLineItemToUpdate.PricebookEntryId = productXeroItemCodeMap.get(quoteLineItem.ItemCode)?.Id;                        
                        quoteLineItemToUpdateList.add(quoteLineItemToUpdate);
                    }
                }
            }
        }
        try
        {
            if(!quoteListToUpdate.isEmpty()) Database.Update(quoteListToUpdate);
            if(!quoteLineCurrent.isEmpty()) Database.Delete(quoteLineCurrent,false);
            if(!quoteLineItemToUpdateList.isEmpty()) Database.Insert(quoteLineItemToUpdateList,false);
            isSuccess = true;
        }
        catch(Exception err)
        {
            Database.rollback(sp);
            Utilities.CreateExceptionLog(err);
            isSuccess = false;
        }
        
        return isSuccess;
    }
    
    public static Boolean UpdateInvoiceAndInvoiceLineItemsFromXeroBatch(List<RestResponseCollectionXero.Invoice> invoiceList , List<String> xeroInvoiceIdList)
    {
        Boolean isSuccess = FALSE;
        Savepoint sp = Database.setSavepoint();
        
        XeroInvoiceFieldMapping xeroInvoiceMapping = RetrieveInvoiceFieldMapping();
        
        if(xeroInvoiceMapping.InvoiceFieldMapping == NULL || xeroInvoiceMapping.InvoiceLineItemFieldMapping == NULL) return isSuccess;
        
        MapXeroInvoiceToSalesforceSObjectReturn mapXeroReturnValue = MapXeroInvoiceToSalesforceSObject(invoiceList , xeroInvoiceMapping.invoiceFieldMapping);
        
        try
        {
            if(!mapXeroReturnValue.SObjectList.isEmpty()) Database.Upsert(mapXeroReturnValue.SObjectList,false);
            
            List<SObject> invoiceLineItemSObjectList = MapXeroLineItemToSalesforceObject(mapXeroReturnValue.XeroInvoiceAndSObjectList , xeroInvoiceMapping.invoiceLineItemFieldMapping);
            
            if(!invoiceLineItemSObjectList.isEmpty()) Database.Upsert(invoiceLineItemSObjectList,false);

            isSuccess = TRUE;
        }
        catch(Exception err)
        {
            Database.rollback(sp);
            Utilities.CreateExceptionLog(err);  
        }
        
        return isSuccess;
    }
    
    public static Boolean UpdateProductFromXero(String productId, RestResponseCollectionXero.Item xeroItem)
    {
        Boolean isSuccess;
        Savepoint sp = Database.setSavepoint();
        
        Product2 prodToUpdate = new Product2();
        prodToUpdate.Id = productId;
        prodToUpdate.XeroId__c = xeroItem.ItemID;
        
        try
        {
            Database.Update(prodToUpdate);
            isSuccess = true;
        }
        catch(Exception err)
        {
            Database.rollback(sp);
            Utilities.CreateExceptionLog(err);
            isSuccess = false;
        }
        
        return isSuccess;
    }
    
    public static Boolean UpdateOrderFromXeroPurchaseOrder(String orderID, String xeroPurchaseOrderId, RestResponseCollectionXero.PurchaseOrder purchaseOrder)
    {
        Boolean isSuccess;
        Savepoint sp = Database.setSavepoint();
        
        Order orderToUpdate = new Order();
        orderToUpdate.Id = orderID;
        orderToUpdate.Xero_PurchaseOrderID__c = xeroPurchaseOrderId;
        orderToUpdate.Xero_Purchase_Order_Status__c = purchaseOrder.Status;
        orderToUpdate.Xero_Purchase_Order_Number__c = purchaseOrder.PurchaseOrderNumber ;
        
        try
        {
            Database.Update(orderToUpdate);
            isSuccess = true;
        }
        catch(Exception err)
        {
            Database.rollback(sp);
            Utilities.CreateExceptionLog(err);
            isSuccess = false;
        }
        
        return isSuccess;
    }
    
    public static Boolean UpdateOrderFromCreditNoteOrder(String orderID, String xeroCreditNoteOrderId, RestResponseCollectionXero.GetCreditNoteResponseBody ResponseBody)
    {
        system.debug('orderID'+orderID);
        system.debug('xeroCreditNoteOrderId'+xeroCreditNoteOrderId);
        system.debug('ResponseBody'+ResponseBody);
        Boolean isSuccess;
        Savepoint sp = Database.setSavepoint();
        
        Order orderToUpdate = new Order();
        orderToUpdate.Id = orderID;
        orderToUpdate.XeroID__c = xeroCreditNoteOrderId; //change
      //  orderToUpdate.Xero_Status__c = ResponseBody.Status;
       orderToUpdate.Xero_Purchase_Order_Number__c = ResponseBody.CreditNotes[0].CreditNoteNumber ;//change
        
        try
        {
            Database.Update(orderToUpdate);
            isSuccess = true;
        }
        catch(Exception err)
        {
            Database.rollback(sp);
            Utilities.CreateExceptionLog(err);
            isSuccess = false;
        }
        
        return isSuccess;
    }
    
    private static Map<String , Account> RetrieveAccountsToUpdateByXeroId(List<String> xeroContactIdList)
    {
        Map<String , Account> acctsToUpdateMap = new Map<String , Account>();
        
        String accountSOQL = Utilities.GenerateAccountSOQL();
        
       	accountSOQL +=  ' WHERE XeroId__c IN : xeroContactIDList';

        if(Utilities.CheckIfPersonAccountEnabled()){
            accountSOQL += ' AND IsPersonAccount = FALSE';
        }
        
        List<Account> accList = Database.Query(accountSOQL);
               
        for(Account acctToUpdate : accList)
        {
            acctsToUpdateMap.put(acctToUpdate.XeroId__c , acctToUpdate);
        }
        
        return acctsToUpdateMap;
    }

    private static Map<String , Account> RetrievePersonAccountsToUpdateByXeroId(List<String> xeroContactIdList)
    {
        Map<String , Account> acctsToUpdateMap = new Map<String , Account>();
        
        String accountSOQL = Utilities.GenerateAccountSOQL();
        
       	accountSOQL +=  ' WHERE IsPersonAccount = TRUE AND XeroId__c IN : xeroContactIDList';
        
        List<Account> accList = Database.Query(accountSOQL);
               
        for(Account acctToUpdate : accList)
        {
            acctsToUpdateMap.put(acctToUpdate.XeroId__c , acctToUpdate);
        }
        
        return acctsToUpdateMap;
    }
    
    private static Boolean MapAccountFieldsFromXero(List<RestResponseCollectionXero.XeroContact> xeroContactList , Map<String , Account> acctsToUpdateMap)
    {
        Boolean isSuccess = FALSE;
              
        List<XeroInboundFieldMapping__c> contactFieldMapping = [SELECT FieldMapping__c FROM XeroInboundFieldMapping__c 
                                                                WHERE Active__c = TRUE 
                                                                AND   XeroObject__c = :CONSTANTS.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_CONTACT 
                                                                    AND Is_Person_Account_Bric__c = FALSE
                                                                LIMIT 1];
            
        if(contactFieldMapping.isEmpty()) return isSuccess; 
               
        
        List<String> fieldMappingList = contactFieldMapping[0].FieldMapping__c.split(CONSTANTS.GENERIC_COMMA);
       
        
        for(RestResponseCollectionXero.XeroContact xeroContact : xeroContactList)
        {
            Account acctRecord = acctsToUpdateMap.get(xeroContact.ContactId);
            
            if(acctRecord == NULL) continue;
            
           
            for(String fieldMapping : fieldMappingList)
            {
                List<String> fields = fieldMapping.split(CONSTANTS.GENERIC_EQUALS);
                if(fields.isEmpty()) continue;
                
                String acctField = fields[0];
                String xeroField = fields[1];
                
                acctRecord.put(acctField , xeroContact.GetField(xeroField)); 
            }
            
        }
        
        isSuccess = TRUE;
        return isSuccess;
    }
    
    private static Boolean MapPersonAccountFieldsFromXero(List<RestResponseCollectionXero.XeroContact> xeroContactList , Map<String , Account> acctsToUpdateMap)
    {
        Boolean isSuccess = FALSE;
        List<XeroInboundFieldMapping__c> personContactFieldMapping = new List<XeroInboundFieldMapping__c>();
        List<String> pesonAccountfieldMappingList = new List<String>();
  
        
             personContactFieldMapping = [SELECT FieldMapping__c FROM XeroInboundFieldMapping__c 
                                                                WHERE Active__c = TRUE 
                                                                AND   XeroObject__c = :CONSTANTS.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_CONTACT 
                                                                    AND Is_Person_Account_Bric__c = TRUE
                                                                LIMIT 1];   
            
            if(personContactFieldMapping.isEmpty()) return isSuccess; 
            
            if(!personContactFieldMapping.isEmpty()){
                pesonAccountfieldMappingList = personContactFieldMapping[0].FieldMapping__c.split(CONSTANTS.GENERIC_COMMA);
            }
        
        for(RestResponseCollectionXero.XeroContact xeroContact : xeroContactList)
        {
            Account acctRecord = acctsToUpdateMap.get(xeroContact.ContactId);
            
            if(acctRecord == NULL) continue;            
    
                for(String fieldMapping : pesonAccountfieldMappingList)
                {
                    List<String> fields = fieldMapping.split(CONSTANTS.GENERIC_EQUALS);
                    if(fields.isEmpty()) continue;
                    
                    String acctField = fields[0];
                    String xeroField = fields[1];
                    
                    if(acctField == 'LastName'){
                        
                     	if((xeroContact.GetField(xeroField) == '' || xeroContact.GetField(xeroField) == NULL) && (xeroContact.GetField('FirstName') != NULL || xeroContact.GetField('FirstName') != '')){

                            acctRecord.put(acctField , xeroContact.GetField('FirstName')); 
                            
                        } else{
                            acctRecord.put(acctField , xeroContact.GetField(xeroField)); 
                        }
                    } else if(acctField == 'FirstName'){
                        
                        if((xeroContact.GetField('LastName') == '' || xeroContact.GetField('LastName') == NULL) && (xeroContact.GetField(xeroField) != NULL || xeroContact.GetField(xeroField) != '')){

                            acctRecord.put(acctField , NULL); 
                            
                        } else {
                            acctRecord.put(acctField , xeroContact.GetField(xeroField));
                        }
                        
                    } else if((xeroContact.GetField('LastName') == '' || xeroContact.GetField('LastName') == NULL) && (xeroContact.GetField('FirstName') == NULL || xeroContact.GetField('FirstName') == '')){
                    	
                        return isSuccess;
                        
                	} else {
                        
                        acctRecord.put(acctField , xeroContact.GetField(xeroField)); 
                        
                    }
                     
                    
                }
            
        }
        
        isSuccess = TRUE;
        return isSuccess;
    }
    
    private static XeroInvoiceFieldMapping RetrieveInvoiceFieldMapping()
    {
        XeroInvoiceFieldMapping xeroInvoiceMapping = new XeroInvoiceFieldMapping();
        
        for(XeroInboundFieldMapping__c fieldMapping : [SELECT XeroObject__c, FieldMapping__c, SalesforceObject__c, SalesforceLookupField__c
                                                       FROM XeroInboundFieldMapping__c 
                                                       WHERE Active__c = TRUE 
                                                       AND  (    XeroObject__c = :CONSTANTS.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE
                                                             OR  XeroObject__c = :CONSTANTS.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE_LINE_ITEM)
                                                                LIMIT 2])
        {
            if(fieldMapping.XeroObject__c == CONSTANTS.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE) xeroInvoiceMapping.InvoiceFieldMapping = fieldMapping;
            else if(fieldMapping.XeroObject__c == CONSTANTS.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE_LINE_ITEM) xeroInvoiceMapping.InvoiceLineItemFieldMapping = fieldMapping;
        }
        
        return xeroInvoiceMapping;
    }
    
    private static MapXeroInvoiceToSalesforceSObjectReturn MapXeroInvoiceToSalesforceSObject(List<RestResponseCollectionXero.Invoice> invoiceList , XeroInboundFieldMapping__c invoiceFieldMapping)
    {
        MapXeroInvoiceToSalesforceSObjectReturn returnValue = new MapXeroInvoiceToSalesforceSObjectReturn();
        returnValue.XeroInvoiceAndSObjectList = new List<XeroInvoiceAndSObject>();
        returnValue.SObjectList = new List<SObject>();
               
        for(RestResponseCollectionXero.Invoice invoice : invoiceList)
        {
        
            XeroInvoiceAndSObject xeroInvoiceAndSObject = new XeroInvoiceAndSObject();
            
            invoice.DueDateString = invoice.DueDateString?.replace(CONSTANTS.XERO_OBJECT_INVOICE_DUE_DATE_EXTENSION , CONSTANTS.GENERIC_BLANK);
            
            SObject invoiceSObj = Schema.getGlobalDescribe().get(invoiceFieldMapping.SalesforceObject__c)?.newSObject();   
            if(invoiceSObj == NULL) return returnValue;
            
            for(String fieldMapping : invoiceFieldMapping.FieldMapping__c?.split(CONSTANTS.GENERIC_COMMA))
            {
                List<String> fields = fieldMapping.split(CONSTANTS.GENERIC_EQUALS);
                if(fields.isEmpty()) continue;
                
                String salesforceField = fields[0];
                String xeroField = fields[1];
                Object xeroFieldValue = invoice.GetField(xeroField);
                
                if(xeroField == CONSTANTS.RESPONSE_COLLECTION_XERO_INVOICE_DUE_DATE_STRING || xeroField == CONSTANTS.RESPONSE_COLLECTION_XERO_INVOICE_DATE_STRING)
                {
                    if(Utilities.CheckStringIfNullOrBlank(String.valueOf(xeroFieldValue)))
                    {
                        xeroFieldValue = Date.valueOf(xeroFieldValue + CONSTANTS.GENERIC_SPACE + CONSTANTS.DATE_AND_TIME_TIME_EXTENSION);   
                    }
                }
                
                invoiceSObj.put(salesforceField , xeroFieldValue);
            }
            
            xeroInvoiceAndSObject.XeroInvoice = invoice;
            xeroInvoiceAndSObject.InvoiceSObject = invoiceSObj;
            returnValue.SObjectList.add(invoiceSObj);
            returnValue.XeroInvoiceAndSObjectList.add(xeroInvoiceAndSObject);
        }
        
        return returnValue;
    }
    
    private static List<SObject> MapXeroLineItemToSalesforceObject(List<XeroInvoiceAndSObject> XeroInvoiceAndSObjectList , XeroInboundFieldMapping__c invoiceLineItemFieldMapping)
    {
        List<SObject> InvoiceLineItemSObjectList = new List<SObject>();
        
        for(XeroInvoiceAndSObject xeroInvoiceAndSObject : XeroInvoiceAndSObjectList)
        {
            Id invoiceSObjectId = (Id)xeroInvoiceAndSObject.InvoiceSObject.get(CONSTANTS.SOBJECT_FIELD_ID);
            
            if(invoiceSObjectId == NULL) continue;
            
            for(RestResponseCollectionXero.LineItem invoiceLineItem : xeroInvoiceAndSObject.XeroInvoice.LineItems)
            {
                SObject invoiceLineItemSObjToUpdate = Schema.getGlobalDescribe().get(invoiceLineItemFieldMapping.SalesforceObject__c)?.newSObject();   
                if(invoiceLineItemSObjToUpdate == NULL) continue;
                
                for(String fieldMapping : invoiceLineItemFieldMapping.FieldMapping__c?.split(CONSTANTS.GENERIC_COMMA))
                {
                    List<String> fields = fieldMapping.split(CONSTANTS.GENERIC_EQUALS);
                    if(fields.isEmpty()) continue;
                    
                    String salesforceField = fields[0];
                    String xeroField = fields[1];
                    
                    invoiceLineItemSObjToUpdate.put(salesforceField , invoiceLineItem.GetField(xeroField));
                }
                
                if(Utilities.CheckStringIfNullOrBlank(invoiceLineItemFieldMapping.SalesforceLookupField__c))
                {
                    invoiceLineItemSObjToUpdate.put(invoiceLineItemFieldMapping.SalesforceLookupField__c , invoiceSObjectId);
                }
                
                InvoiceLineItemSObjectList.add(invoiceLineItemSObjToUpdate);
            }
        }
        
        return InvoiceLineItemSObjectList;
    }
    
    
    
}