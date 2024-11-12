/*
 * Author:       Bricoleur Technologies
 * Created Date:   July 7, 2021
 * Description:   Apex Controller Class for syncWithXeroLwc LWC
 * Test Class:     XeroRequestTest
 * History:        July 7, 2021 - Creation
 *           
*/
public class SyncWithXeroController_NoPersonAccount {

  @AuraEnabled
    public static LWCObjects.ResponseToast SendToXero(String recordId , String sObjectName)
    {
        LWCObjects.ResponseToast response = new LWCObjects.ResponseToast();
        
        Map<String , Object> flowParams = new Map<String , Object>{CONSTANTS.FLOW_SYNC_TO_XERO_VARIABLE_RECORD_ID => recordId , CONSTANTS.FLOW_SYNC_TO_XERO_VARIABLE_SOBJECT => sObjectName};
        Flow.Interview.SyncToXero_NoPersonAccount syncToXeroFlow = new Flow.Interview.SyncToXero_NoPersonAccount(flowParams);
        
        try
        {
            syncToXeroFlow.start();
            Utilities.SetResponseToast(response , TRUE , CONSTANTS.TOAST_XERO_SYNC_SUCCESSFUL);
        }
        catch(Exception err)
        {
            Utilities.CreateExceptionLog(err);
            Utilities.SetResponseToast(response , FALSE , CONSTANTS.TOAST_XERO_SYNC_UNSUCCESSFUL);
        }
        
        return response;
    }
}