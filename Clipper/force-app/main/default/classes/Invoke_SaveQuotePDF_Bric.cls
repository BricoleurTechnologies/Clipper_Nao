/*
* Author: Bricoleur Technologies - JP Sulit (jp@bricoleurtech.com)
* Created Date: Oct 29, 2023
* Description: Saves online quote form pdf from when quote is accepted.
* Test Class: Invoke_SaveQuotePDFTest_Bric
* History: Oct 29, 2023 - Created       
*/

public without sharing class Invoke_SaveQuotePDF_Bric 
{
    @InvocableMethod(label='Save PDF to Opp')
    public static List<FlowOutputs> savePdfToQuote(List<FlowInputs> input)
    {
        List<FlowOutputs> resultList = new List<FlowOutputs>();
        FlowOutputs output = new FlowOutputs();

        if(input[0].oppId != null)
        {
            try 
            {
                if(input[0].digitalQuoteAccepted == 'Yes')
                {
                    fileUpload(input[0].oppId,
                                input[0].oppName,
                                input[0].oppClientEmail);
                }
            } 
            catch(Exception e) 
            {
                output.exceptionMsg = e.getMessage();
            }
            System.debug('output.exceptionMsg '+output.exceptionMsg);
            resultList.add(output);
        }       
        return resultList;
    }

    @future(callout=true)
    public static void fileUpload(String oppId,
                                        String oppName,
                                        String oppClientEmail)
    {
        PageReference pr = new PageReference(Label.Online_Quote_Form_PDF_URL_VF_Bric+oppId);
       
        ContentVersion cv = new ContentVersion();
        cv.Title = oppName +'_'+ DateTime.now();
        cv.PathOnClient = cv.Title +'.pdf';
        cv.VersionData = !Test.isRunningTest()?pr.getContentAsPdf():Blob.valueOf('Hello World');
        cv.Origin = 'C';
        //cv.FirstPublishLocationId = [SELECT Account.PersonContactId FROM Opportunity WHERE Id =: oppId].Account.PersonContactId;
        insert cv;

        if(cv != null)
        {
            Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cdId;
            cdl.LinkedEntityId = oppId;
            cdl.ShareType = 'V';
            insert cdl;
        }
    }

    public class FlowInputs 
    {
        @InvocableVariable
        public String oppId;
        @InvocableVariable
        public String oppName;
        @InvocableVariable
        public String oppClientEmail;
        @InvocableVariable
        public String digitalQuoteAccepted;
    }

    public class FlowOutputs
    {
        @InvocableVariable
        public String exceptionMsg;
    }
}