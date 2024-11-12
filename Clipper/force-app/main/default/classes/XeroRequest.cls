/*
 * Author:          Alfonso Maquilan
 * Created Date:    May 5, 2021
 * Description:     Apex Class for Xero Outbound Rest Request
 * Test Class:      XeroRequestTest
 * History:         May 05, 2021 - Creation
*/
public class XeroRequest 
{  
    public static Boolean GetContacts(XeroAPISettings__c apiSettings , List<String> xeroContactIdList , Boolean isAsync)
    {
        Boolean isSuccess;
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(apiSettings.TenantID__c);
        
        String requestEndpoint = apiSettings.Endpoint__c + CONSTANTS.INTEGRATION_XERO_ENDPOINT_CONTACTS + CONSTANTS.INTEGRATION_XERO_ENDPOINT_PARAMETER_ID + CONSTANTS.GENERIC_EQUALS;
        
        for(Integer ctr = 0; ctr < xeroContactIdList.size(); ctr++)
        {
            if(ctr + 1 == xeroContactIdList.size()) requestEndpoint = requestEndpoint + xeroContactIdList[ctr];
            else requestEndpoint = requestEndpoint + xeroContactIdList[ctr] + CONSTANTS.GENERIC_COMMA;
        }
        
        HttpResponse response = RestHandler.ExecuteRequest(requestHeader, requestEndpoint, null, CONSTANTS.INTEGRATION_REST_METHOD_GET);
        String responseBodyString = response?.getBody();
        
        if(!XeroRequestUtilities.CheckResponseBodyValidity(response.getStatusCode() , responseBodyString))
        {
            isSuccess = FALSE;
            return isSuccess;
        }
        
        Map<String , String> responseBodyReplacementList = new Map<String , String>{CONSTANTS.INTEGRATION_KEY_TYPE => CONSTANTS.INTEGRATION_KEY_TYPE_X};   
        responseBodyString = XeroRequestUtilities.FormatJSONBodyString(responseBodyString , responseBodyReplacementList);
        RestResponseCollectionXero.GetContactResponseBody responseBody = (RestResponseCollectionXero.GetContactResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetContactResponseBody.class) ;

        if(responseBody == NULL)
        {
            isSuccess = FALSE;
            return isSuccess;
        }

        if(isAsync && !test.isRunningTest()) RunAsyncUpdateFromXero(CONSTANTS.SOBJECT_ACCOUNT , responseBody.Contacts , xeroContactIdList);
        else isSuccess = PostXeroRequest.UpdateAccountFromXeroBatch(responseBody.Contacts , xeroContactIdList);
        
        return isSuccess;
    }
    
    public static Boolean GetInvoices(XeroAPISettings__c apiSettings , List<String> xeroInvoiceIdList , Boolean isAsync)
    {
        Boolean isSuccess;
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(apiSettings.TenantID__c);
        
        String requestEndpoint = apiSettings.Endpoint__c + CONSTANTS.INTEGRATION_XERO_ENDPOINT_INVOICES + CONSTANTS.INTEGRATION_XERO_ENDPOINT_PARAMETER_ID + CONSTANTS.GENERIC_EQUALS;
        
        for(Integer ctr = 0; ctr < xeroInvoiceIdList.size(); ctr++)
        {
            if(ctr + 1 == xeroInvoiceIdList.size()) requestEndpoint = requestEndpoint + xeroInvoiceIdList[ctr];
            else requestEndpoint = requestEndpoint + xeroInvoiceIdList[ctr] + CONSTANTS.GENERIC_COMMA;
        }
        
        HttpResponse response = RestHandler.ExecuteRequest(requestHeader, requestEndpoint, null, CONSTANTS.INTEGRATION_REST_METHOD_GET);
        String responseBodyString = response?.getBody();

        if(!XeroRequestUtilities.CheckResponseBodyValidity(response.getStatusCode() , responseBodyString))
        {
            isSuccess = FALSE;
            return isSuccess;
        }

        Map<String , String> responseBodyReplacementList = new Map<String , String>{CONSTANTS.INTEGRATION_KEY_TYPE => CONSTANTS.INTEGRATION_KEY_TYPE_X};   
        responseBodyString = XeroRequestUtilities.FormatJSONBodyString(responseBodyString , responseBodyReplacementList);
        RestResponseCollectionXero.GetInvoiceResponseBody responseBody = (RestResponseCollectionXero.GetInvoiceResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetInvoiceResponseBody.class) ;
        
        if(responseBody == NULL)
        {
            isSuccess = FALSE;
            return isSuccess;
        }
        
        if(isAsync && !test.isRunningTest()) RunAsyncUpdateFromXero(CONSTANTS.SOBJECT_OPPORTUNITY , responseBody.Invoices , xeroInvoiceIdList);
        else isSuccess = PostXeroRequest.UpdateInvoiceAndInvoiceLineItemsFromXeroBatch(responseBody.Invoices , xeroInvoiceIdList);
        
        return isSuccess;
    }
    
    public static void RunAsyncUpdateFromXero(String updateToRun , List<Object> xeroObjectList , List<String> xeroIdList)
    {
        AsyncUpdateFromXero updateFromXero = new AsyncUpdateFromXero();
        updateFromXero.InstantiateProperties();
        updateFromXero.SetUpdateToRun(updateToRun); 
        updateFromXero.SetXeroObjectList(xeroObjectList);
        updateFromXero.SetXeroIdList(xeroIdList);
        
        System.enqueueJob(updateFromXero);
    }
}