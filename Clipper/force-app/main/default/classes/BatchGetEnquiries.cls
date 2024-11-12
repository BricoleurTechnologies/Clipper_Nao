public class BatchGetEnquiries implements Database.Batchable<RestResponseFromRealEstate.enquirie>,Database.AllowsCallouts, Database.Stateful{
    
    public DateTime batchStartTime;
    public Boolean isSuccess;
    public Iterable<RestResponseFromRealEstate.enquirie> start(Database.BatchableContext context)
    {   
        isSuccess = true;
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        XeroProductSyncSetting__c xeroProductSettings = XeroProductSyncSetting__c.getInstance('Default');
        String modifiedSince = getUTCDateTime(xeroProductSettings?.Modified_After__c);
        batchStartTime = System.now();
            
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return new List<RestResponseFromRealEstate.enquirie>();
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        if(modifiedSince != null && modifiedSince != '') requestHeader.put(CONSTANTS.INTEGRATION_XERO_HEADER_KEY_IF_MODIFIED_SINCE,modifiedSince);

       // HttpResponse response = RestHandler.ExecuteRequest(requestHeader,endpoint + CONSTANTS.INTEGRATION_XERO_ENDPOINT_ITEMS,null,CONSTANTS.INTEGRATION_REST_METHOD_GET);
		String responseBodyString ='{"embedded":{"enquiries":[{"id":"string","agencyId":"string","receivedAt":"2024-05-29T06:09:54.751Z","processedAt":"2024-05-29T06:09:54.751Z","comments":"string","requestedInformation":["string"],"suppliedMarketStatus":"string","agentRecipients":["string"],"contactDetails":{"fullName":"string","email":"string","phone":"string","postcode":"string","preferredContactMethod":"PHONE"},"emailSubject":"string","links":{"self":{"href":"string"}},"type":"DEVELOPER_BUILDER_DESIGN","listing":{"id":"string","externalListingId":"string","parentId":"string","address":"string"}}]},"links":{"self":{"href":"string"},"next":{"href":"string"}}}';      
        //response?.getBody();
        system.debug('responseBodyString:'+responseBodyString);
        
      /*  if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){
            Utilities.CreateExceptionLog(null, response?.getStatusCode() + ' --- ' + responseBodyString);
            isSuccess = false;
            return new List<RestResponseFromRealEstate.enquiries>();
        }*/
        
        RestResponseFromRealEstate.GetEnquiryResponseBody responseBody = (RestResponseFromRealEstate.GetEnquiryResponseBody)JSON.deserialize(responseBodyString, RestResponseFromRealEstate.GetEnquiryResponseBody.class) ;
       system.debug('responseBody'+responseBody);
        if(responseBody == NULL) return new List<RestResponseFromRealEstate.enquirie>();
        system.debug('responseBody.Items ::: ' + responseBody.embedded.enquiries);
        return responseBody.embedded.enquiries;
        //RestResponseFromRealEstate.enquiries
    }
    
    public void execute(Database.BatchableContext context, List<RestResponseFromRealEstate.enquirie> enquiryList) {

        
        List<RC_API_Data__c> RCApiDataList = new List<RC_API_Data__c>();
        
        if(enquiryList.size() > 0){
            for(RestResponseFromRealEstate.enquirie embeddedOBJ : enquiryList){
                RC_API_Data__c rcApiDataOBJ = new RC_API_Data__c();
                rcApiDataOBJ.Received__c  = date.today();
                rcApiDataOBJ.Data__c = string.valueof(embeddedOBJ);
                RCApiDataList.add(rcApiDataOBJ);
            }
        }
        
        if(RCApiDataList.size() > 0){
            Database.insert(RCApiDataList,false);
        }
        
    }
    
    public void finish(Database.BatchableContext context) {
        XeroProductSyncSetting__c xeroProductSettings = XeroProductSyncSetting__c.getInstance('Default');
        if(xeroProductSettings != NULL && isSuccess)
        {
            xeroProductSettings.Modified_After__c = batchStartTime;
            Database.Update(xeroProductSettings);
        } 
    }
    
    public String getUTCDateTime(DateTime dt){
        if(dt != null){
            Datetime GMTDate = Datetime.newInstance(
                dt.year(),
                dt.month(),
                dt.day(),
                dt.hour(),
                dt.minute(),
                dt.second());
            String formatted = GMTDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss');
            return formatted;
        }else{            
            return null;
        }
    }
}