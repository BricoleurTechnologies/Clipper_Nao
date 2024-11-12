/*
 * Author:          Alfonso Maquilan
 * Created Date:    June 02, 2021
 * Description:     Apex Class for Xero Outbound Get Contact callout Invoked from Flow
 * Test Class:      N/A
 * History:         Jun. 02, 2021 - Creation
 * 			        Aug. 11, 2021 - Updated GenerateEndpointParameter method to encode everything after the WHERE parameter
*/
public class XeroSearchContactRequestFlow 
{
 @InvocableMethod(label = 'Get From Xero' description = 'Get corresponding Xero Contact')
    public static void SearchContactInXero(List<XeroReqGetFlowParamsContact> params)
    {
        
        
        if(params[0].flag=false){
            system.debug('params[0].flag'+params[0].flag);
           if(params == NULL || params.isEmpty()) return; 
           GetContact(params[0].AccountRecord , params[0].Parameter , params[0].ParameterValue); 
            
        }
        if(params[0].flag=true){
          //  GetContactViaXeroContactID(params[0].AccountRecord , params[0].ContactID);
            system.debug('Accountparams'+params[0].AccountRecord);
        }
    }
    private static void GetContactViaXeroContactID(Account acctRecord, String xeroContactID)
    {
        if(!Utilities.CheckStringIfNullOrBlank(xeroContactID)) return;
        
       // XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = '921f2c05-c51b-4c6f-ac03-f208b692b0e3';//apiSettings?.TenantID__c;
        String endpoint = 'https://api.xero.com/api.xro/2.0';//apiSettings?.Endpoint__c;
        
        if(tenantId == NULL) return;
        
       Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        String calloutEndpoint = endpoint + CONSTANTS.INTEGRATION_XERO_ENDPOINT_CONTACTS + '/'+xeroContactID;
		System.debug('requestHeader'+requestHeader);
        System.debug('calloutEndpoint'+calloutEndpoint);
        HttpResponse response = RestHandler.ExecuteRequest(requestHeader , calloutEndpoint , NULL, CONSTANTS.INTEGRATION_REST_METHOD_GET); 
        system.debug('response'+response);
        String responseBodyString = '{"Id":"542ff436-45cb-4cf4-9586-7f2851fc14d1","Status":"OK","ProviderName":"API Explorer","DateTimeUTC":"/Date(1698902402002)/","Contacts":[{"ContactID":"6c2aa3ab-610d-4b11-b82b-97dfd57c7a8b","ContactStatus":"ACTIVE","Name":"test","FirstName":"","LastName":"","EmailAddress":"","BankAccountDetails":"","TaxNumber":"","Addresses":[{"AddressType":"STREET","AddressLine1":"","City":"","Region":"","PostalCode":"","Country":""},{"AddressType":"POBOX","AddressLine1":"","City":"","Region":"","PostalCode":"","Country":""}],"Phones":[{"PhoneType":"DDI","PhoneNumber":"","PhoneAreaCode":"","PhoneCountryCode":""},{"PhoneType":"DEFAULT","PhoneNumber":"","PhoneAreaCode":"","PhoneCountryCode":""},{"PhoneType":"FAX","PhoneNumber":"","PhoneAreaCode":"","PhoneCountryCode":""},{"PhoneType":"MOBILE","PhoneNumber":"","PhoneAreaCode":"","PhoneCountryCode":""}],"UpdatedDateUTC":"/Date(1697171963263+0000)/","ContactGroups":[],"IsSupplier":true,"IsCustomer":true,"Balances":{"AccountsReceivable":{"Outstanding":230,"Overdue":230},"AccountsPayable":{"Outstanding":0,"Overdue":0}},"ContactPersons":[],"HasAttachments":false,"Attachments":[],"HasValidationErrors":false}]}';//response?.getBody();
        system.debug('responseBodyString'+responseBodyString);

       // if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)) return;
        
        RestResponseCollectionXero.GetContactResponseBody responseBody = (RestResponseCollectionXero.GetContactResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetContactResponseBody.class);
			System.debug('responseBody'+responseBody);
        if(responseBody == NULL || responseBody.Contacts.isEmpty()) return;
        PostXeroRequest.UpdateAccountFromXero(acctRecord.Id , responseBody?.Contacts[0]); 
    }
    
    private static void GetContact(Account acctRecord , String parameter , String parameterValue)
    {
        if(!Utilities.CheckStringIfNullOrBlank(parameterValue)) return;
        
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(tenantId == NULL) return;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        String calloutEndpoint = endpoint + CONSTANTS.INTEGRATION_XERO_ENDPOINT_CONTACTS + GenerateEndpointParameter(parameter , parameterValue);

        HttpResponse response = RestHandler.ExecuteRequest(requestHeader , calloutEndpoint , NULL, CONSTANTS.INTEGRATION_REST_METHOD_GET); 
        String responseBodyString = response?.getBody();

        if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)) return;
        
        RestResponseCollectionXero.GetContactResponseBody responseBody = (RestResponseCollectionXero.GetContactResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetContactResponseBody.class);

        if(responseBody == NULL || responseBody.Contacts.isEmpty()) return;
        PostXeroRequest.UpdateAccountFromXero(acctRecord.Id , responseBody?.Contacts[0]); 
    }
    
    private static String GenerateEndpointParameter(String parameter , String parameterValue)
    {
        String encodedParameter = parameter + CONSTANTS.GENERIC_EQUALS + '"' + parameterValue + '"';
        encodedParameter = EncodingUtil.urlEncode(encodedParameter, 'UTF-8');
        return CONSTANTS.INTEGRATION_XERO_ENDPOINT_PARAMETER_WHERE + CONSTANTS.GENERIC_EQUALS + encodedParameter;
    }
}