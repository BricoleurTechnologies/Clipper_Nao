public class XeroGetContactViaContactID {
    Public class GetContactViaContactIDAsync implements Queueable, Database.AllowsCallouts
    {
        private String Endpoint;
        private Map<String , String> RequestHeader;
        private String RequestBody;
        private String RequestMethod;
        private String SalesforceRecordId;
        private String xeroContactID;
        private Boolean flag;
        private String accountID;
        
        public void initializeProperties()
        {
            this.Endpoint = CONSTANTS.GENERIC_BLANK;
            this.RequestHeader = new Map<String , String>();
            this.RequestBody = CONSTANTS.GENERIC_BLANK;
            this.RequestMethod = CONSTANTS.GENERIC_BLANK;
        }
        public Boolean flag()
        {
            return this.flag;
        }
        public String getaccountID()
        {
            return this.accountID;
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
            return this.xeroContactID;
        }
        public void Flag(boolean Flag)
        {
            this.Flag = Flag;
        }
        public void setAccountID(String accountID)
        {
            this.accountID = accountID;
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
        
        public void setxeroContactID(string xerocontactID)
        {
            this.xeroContactID = xerocontactID;
        }
        
        
        public void execute(QueueableContext context)
        {
           
            system.debug('execute');
            HttpResponse response = RestHandler.ExecuteRequest(this.RequestHeader , this.Endpoint , this.RequestBody , this.RequestMethod);
          system.debug('@@'+this.RequestHeader + this.Endpoint + this.RequestBody + this.RequestMethod);
           String responseBodyString = response?.getBody();
                
            if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){                
            //   return;
            }
            
             RestResponseCollectionXero.GetContactResponseBody responseBody = (RestResponseCollectionXero.GetContactResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetContactResponseBody.class);

            System.debug('responseBody'+responseBody);
       // if(responseBody == NULL || responseBody.Contacts.isEmpty()) return;
         
            
          //  if(responseBody != NULL ){
                PostXeroRequest.UpdateAccountFromXero(this.accountID , responseBody?.Contacts[0]);
                return;
           // }
                 
        }
    }
    
 @InvocableMethod(label = 'Get Contact From Xero' description = 'Get corresponding Xero Contact')
    public static void SearchContactInXero(List<XeroReqGetFlowParamsContact> params)
    {
        system.debug('params'+params);
        if(params[0].flag=true){
            GetContactViaXeroContactID(params[0].AccountRecord , params[0].ContactID);
            system.debug('Accountparams'+params[0].AccountRecord);
            system.debug('contactparams'+params[0].ContactID);
        }
    }
    
   
    
       private static void GetContactViaXeroContactID(Account acctRecord, String xeroContactID)
    {
        if(!Utilities.CheckStringIfNullOrBlank(xeroContactID)) return;
        
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(tenantId == NULL) return;
        
       Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        String calloutEndpoint = endpoint + CONSTANTS.INTEGRATION_XERO_ENDPOINT_CONTACTS + '/'+xeroContactID;
		System.debug('requestHeader'+requestHeader);
        System.debug('calloutEndpoint'+calloutEndpoint);
       
        XeroGetContactViaContactID.GetContactViaContactIDAsync postPurchaseOrder = new XeroGetContactViaContactID.GetContactViaContactIDAsync();
        postPurchaseOrder.setEndpoint(calloutEndpoint);
        postPurchaseOrder.setRequestHeader(requestHeader);
        postPurchaseOrder.setRequestMethod(CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        postPurchaseOrder.setSalesforceRecordId(xeroContactID);
        postPurchaseOrder.setAccountID(acctRecord.id);
        System.enqueueJob(postPurchaseOrder);
        
  

       // if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)) return;
        
       
    }

}