/**
 * @description Invocable class for Account Statement PDF Generation
 * @author Bricoleur Technologies
 * @date Nov-5-2024
 */
public with sharing class Invoke_AccountStatementGen {
    
    public class Request {
        @InvocableVariable(required=true)
        public List<Account> selectedAccs;
    }

    public class Response {
        @InvocableVariable
        public String errorMsg;
        @InvocableVariable
        public List<String> selectedAccIds; 
    }

    @InvocableMethod(label='Generate & Attach PDF' description='Generates a PDF from a Visualforce page and attaches it to a record')
    public static List<Response> generateAndAttachPDF(List<Request> requestList) {
        AccountStatementGen_Queueable job = new AccountStatementGen_Queueable(requestList);
        System.enqueueJob(job);

        Response resp = new Response();

        if(requestList[0]?.selectedAccs != null) {
            resp.selectedAccIds = new List<String>();
            for(Account acc : requestList[0]?.selectedAccs) {
                resp.selectedAccIds.add(acc.Id);
            }
        }

        return new List<Response> {resp};
    }
}