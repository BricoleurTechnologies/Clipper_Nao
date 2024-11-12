public class XeroCreditNoteOrderRequestFlow {
    Public class PostCreditNoteOrderAsync implements Queueable, Database.AllowsCallouts
    {
        private String Endpoint;
        private Map<String , String> RequestHeader;
        private String RequestBody;
        private String RequestMethod;
        private String SalesforceRecordId;
        private String ContactID;
        private Boolean AllocateInvoiceBoolean;
        
        public void initializeProperties()
        {
            this.Endpoint = CONSTANTS.GENERIC_BLANK;
            this.RequestHeader = new Map<String , String>();
            this.RequestBody = CONSTANTS.GENERIC_BLANK;
            this.RequestMethod = CONSTANTS.GENERIC_BLANK;
        }
         public Boolean getAllocateInvoiceBoolean()
        {
            return this.AllocateInvoiceBoolean;
        }
        
        public String getEndpoint()
        {
            return this.Endpoint;
        }
        
        public Map<String , String> getRequestHeader()
        {
            return this.RequestHeader;
        }
        
        public String getRequestBody()
        {
            return this.RequestBody;
        }
        
        public String getRequestMethod()
        {
            return this.RequestMethod;
        }
        
        public String getSalesforceRecordId()
        {
            return this.SalesforceRecordId;
        }
        
        public String getContactID()
        {
            return this.ContactID;
        }
        public void setAllocateInvoiceBoolean(boolean AllocateInvoiceBoolean)
        {
            this.AllocateInvoiceBoolean = AllocateInvoiceBoolean;
        }
        public void setEndpoint(String endpoint)
        {
            this.Endpoint = endpoint;
        }
        
        public void setRequestHeader(Map<String , String> requestHeader)
        {
            this.RequestHeader = requestHeader;
        }
        
        public void setRequestBody(String requestBody)
        {
            this.RequestBody = requestBody;
        }
        
        public void setRequestMethod(String requestMethod)
        {
            this.RequestMethod = requestMethod;
        }
        
        public void setSalesforceRecordId(String salesforceRecordId)
        {
            this.SalesforceRecordId = salesforceRecordId;
        }
        
        public void setContactID(string contactID)
        {
            this.ContactID = contactID;
        }
        
        
        public void execute(QueueableContext context)
        {
            system.debug('@@@'+this.AllocateInvoiceBoolean);
            system.debug('execute');
            HttpResponse response = RestHandler.ExecuteRequest(this.RequestHeader , this.Endpoint , this.RequestBody , this.RequestMethod);
          system.debug('@@'+this.RequestHeader + this.Endpoint + this.RequestBody + this.RequestMethod);
            string responseBodyString=response?.getBody();
                
            if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString) && this.AllocateInvoiceBoolean==false){                
               return;
            }
            system.debug('responseBodyString:: ' + responseBodyString);
            RestResponseCollectionXero.GetCreditNoteResponseBody responseBody = (RestResponseCollectionXero.GetCreditNoteResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetCreditNoteResponseBody.class) ;
            system.debug('responseBody'+responseBody);
            if(responseBody == NULL && this.AllocateInvoiceBoolean==false){
                return;
            }
            if(response?.getStatusCode()==200 && this.AllocateInvoiceBoolean==false && responseBodyString!=null){
             PostXeroRequest.UpdateOrderFromCreditNoteOrder(this.SalesforceRecordId , responseBody.CreditNotes[0]?.CreditNoteID , responseBody);  
             return;
            }
            
        }
    }
    
    @InvocableMethod(label = 'Sync Order to Xero as Credit Note Order' description = 'Sends Salesforce Record to Sync with Xero Credit Note Order.')
    public static void SendOrderToXeroFlow(List<XeroReqFlowParamsCreditNoteOrder> params)
    {
        system.debug('execute1');
        if(params == NULL || params.isEmpty()) return;
        if(params[0].AllocateInvoice==false){
        PostCreditNoteOrderBody(params[0]);
        }
        if(params[0].AllocateInvoice==true){
           AllocateInvoiceToCreditNoteOrderBody(params[0]); 
            
        }
        
    }
    
   
    
    Public static void PostCreditNoteOrderBody(XeroReqFlowParamsCreditNoteOrder params)
    {
        system.debug('execute2');
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c+'/CreditNotes';
       
        
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
         System.debug('requestHeader'+requestHeader);
        System.debug('endpoint'+endpoint);
        
        RestRequestCollectionXero.CreditNoteOrder requestBody = new RestRequestCollectionXero.CreditNoteOrder();
        requestBody = SetPostCreditNoteOrderBody(params);
            
            String requestBodyString = JSON.serialize(requestBody);
        system.debug('requestBodyString'+requestBodyString);
        Map<String , String> requestBodyReplacementList = new Map<String , String>{CONSTANTS.INTEGRATION_KEY_TYPE_X => CONSTANTS.INTEGRATION_KEY_TYPE,
            CONSTANTS.INTEGRATION_KEY_DATE_X => CONSTANTS.INTEGRATION_KEY_DATE};   
                requestBodyString = XeroRequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
        
        XeroCreditNoteOrderRequestFlow.PostCreditNoteOrderAsync postPurchaseOrder = new XeroCreditNoteOrderRequestFlow.PostCreditNoteOrderAsync();
        postPurchaseOrder.setEndpoint(endpoint);
        postPurchaseOrder.setRequestHeader(requestHeader);
        postPurchaseOrder.setRequestBody(requestBodyString);
        postPurchaseOrder.setRequestMethod(CONSTANTS.INTEGRATION_REST_METHOD_POST);        
        postPurchaseOrder.setSalesforceRecordId(params.SalesforceID);
        postPurchaseOrder.setAllocateInvoiceBoolean(params.AllocateInvoice);
        
        System.enqueueJob(postPurchaseOrder);
    }
    
    Public static void AllocateInvoiceToCreditNoteOrderBody(XeroReqFlowParamsCreditNoteOrder params)
    {
        system.debug('execute3');
        string CreditNoteID=params.CreditNoteID;
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c+'/CreditNotes/'+CreditNoteID+'/Allocations';
        
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        
        RestRequestCollectionXero.AllocateInvoiceBody requestBody = new RestRequestCollectionXero.AllocateInvoiceBody();
        requestBody = SetPostInvoiceBody(params);
            
            String requestBodyString = JSON.serialize(requestBody);
        system.debug('requestBodyString'+requestBodyString);
        Map<String , String> requestBodyReplacementList = new Map<String , String>{CONSTANTS.INTEGRATION_KEY_TYPE_X => CONSTANTS.INTEGRATION_KEY_TYPE,
            CONSTANTS.INTEGRATION_KEY_DATE_X => CONSTANTS.INTEGRATION_KEY_DATE};   
                requestBodyString = XeroRequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
        
        XeroCreditNoteOrderRequestFlow.PostCreditNoteOrderAsync postPurchaseOrder = new XeroCreditNoteOrderRequestFlow.PostCreditNoteOrderAsync();
        postPurchaseOrder.setEndpoint(endpoint);
        postPurchaseOrder.setRequestHeader(requestHeader);
        postPurchaseOrder.setRequestBody(requestBodyString);
        postPurchaseOrder.setRequestMethod(CONSTANTS.INTEGRATION_REST_METHOD_PUT);        
        postPurchaseOrder.setAllocateInvoiceBoolean(params.AllocateInvoice);
        
        System.enqueueJob(postPurchaseOrder);
    }
    
    Public static RestRequestCollectionXero.AllocateInvoiceBody SetPostInvoiceBody(XeroReqFlowParamsCreditNoteOrder params)
    {
        system.debug('params'+params.InvoiceID);
        RestRequestCollectionXero.AllocateInvoiceBody requestBody = new RestRequestCollectionXero.AllocateInvoiceBody();
        if(params.Amount>0){
         requestBody.Amount=params.Amount;   
        }
        
                system.debug('requestBody'+requestBody);

        requestBody.Invoice= SetAllocateInvoice(params.InvoiceID);
     system.debug('requestBody'+requestBody);
        
        return requestBody;
    }
    
    Public static RestRequestCollectionXero.CreditNoteOrder SetPostCreditNoteOrderBody(XeroReqFlowParamsCreditNoteOrder params)
    {
        RestRequestCollectionXero.CreditNoteOrder requestBody = new RestRequestCollectionXero.CreditNoteOrder();
        requestBody.type=params.type;
        requestBody.Reference = params.Reference;
        requestBody.Contact = SetXeroContact(params.ContactId);
        requestBody.Date_x = params.Date_x;
        requestBody.DeliveryDate = params.DeliveryDate;
        if(params.lineItems!=null){
         requestBody.LineItems = SetXeroLineItems(params.lineItems); 
         requestBody.LineAmountTypes = params.LineAmountTypes;
        }
        
        requestBody.Status = params.Status;
        
        
        
        system.debug('requestBody'+requestBody);
        system.debug('requestBody.LineItems'+requestBody.LineItems);
        return requestBody;
    }
    
    Public static RestRequestCollectionXero.CreditNoteOrderXeroContact SetXeroContact(String contactId)
    {
        RestRequestCollectionXero.CreditNoteOrderXeroContact xeroContact = new RestRequestCollectionXero.CreditNoteOrderXeroContact();
        xeroContact.ContactID = contactId;
        
        return xeroContact;
    }
      Public static RestRequestCollectionXero.AllocateInvoice SetAllocateInvoice(String invoiceId)
    {
        RestRequestCollectionXero.AllocateInvoice xeroInvoiceID = new RestRequestCollectionXero.AllocateInvoice();
        xeroInvoiceID.InvoiceID = invoiceId;
        
        return xeroInvoiceID;
    }
    
    Public static List<RestRequestCollectionXero.XeroLineItem> SetXeroLineItems(List<XeroReqFlowLineItemParams> lineItems)
    {
        List<RestRequestCollectionXero.XeroLineItem> xeroLineItemList = new List<RestRequestCollectionXero.XeroLineItem>();
        
        for(XeroReqFlowLineItemParams lineItem : lineItems)
        {
            RestRequestCollectionXero.XeroLineItem xeroLine = new RestRequestCollectionXero.XeroLineItem();
            xeroLine.LineItemID = lineItem.LineItemId;
            xeroLine.Description = lineItem.Description;
            xeroLine.Quantity = lineItem.Quantity;
            xeroLine.UnitAmount = lineItem.UnitAmount;
            xeroLine.AccountCode = lineItem.AccountCode != NULL && !String.IsBlank(lineItem.AccountCode) ? lineItem.AccountCode : CONSTANTS.XERO_OBJECT_INVOICE_LINE_ITEM_ACCOUNT_CODE_200;
            xeroLine.TaxType = lineItem.TaxType;
            xeroLine.TaxAmount = lineItem.TaxAmount;
            xeroLine.LineAmount = lineItem.LineAmount;
            xeroLine.DiscountRate = lineItem.DiscountRate;
        //    xeroLine.ItemCode = lineItem.ItemCode;
            
            xeroLineItemList.add(xeroLine);
        }
        
        return xeroLineItemList;
    }
    
    Public static void updateAccountXeroId(String orderID, String xeroContactID){
        Order orderRec = [SELECT Id,AccountId FROM Order WHERE Id=:orderID];                
        if(xeroContactID != '' && xeroContactID != NULL){
            Account accRecord = new Account();
            accRecord.Id = orderRec.AccountId;
            accRecord.XeroId__c = xeroContactID;
            update accRecord;
        }
    }

}