/**
 * @description Queueable class for Account Statement PDF Generation
 * @author Bricoleur Technologies
 * @date Nov-5-2024
 */
public with sharing class AccountStatementGen_Queueable implements Queueable, Database.AllowsCallouts {

    private List<Invoke_AccountStatementGen.Request> requestList;

    public AccountStatementGen_Queueable(List<Invoke_AccountStatementGen.Request> requestList) {
        this.requestList = requestList;
    }

    public void execute(QueueableContext context) {

        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        List<Database.SaveResult> saveResult = new List<Database.SaveResult>();

        if(requestList[0]?.selectedAccs != null) {
            
            Map<Id, Account> accMap = new Map<Id, Account>(requestList[0]?.selectedAccs);
            Set<Id> accIdSet = accMap.keySet();
            String accQry = SchemaHelper.getObjectQuery('Account', '') + ' WHERE Id IN : accIdSet';
            System.debug('accQry bric '+accQry);

            for(Account acc : Database.query(accQry)) {
                System.debug('acc bric '+acc.Id);
                String vfParam = 'AccountStatementPDF?Id='+acc.Id+'&sObjectType=Account&childSObjectType=Invoice__c&pdfLogo='+Label.Account_Statement_PDF_Logo_URL;
                PageReference pdfPage = new PageReference('/apex/'+vfParam);
                Blob pdfBlob = !Test.isRunningTest() ? pdfPage.getContentAsPDF() : Blob.valueOf('Test');

                ContentVersion cv = new ContentVersion();
                cv.Title = acc.Name;
                cv.PathOnClient = acc.Name+'.pdf';
                cv.VersionData = pdfBlob;
                cv.IsMajorVersion = true;
                cv.Record_ID__c = acc.Id;
                contentVersionsToInsert.add(cv);
            }

            if(contentVersionsToInsert != null) {
                System.debug('contentVersionsToInsert bric '+contentVersionsToInsert);
                saveResult = Database.insert(contentVersionsToInsert, false);
                Set<Id> cvIdSet = recordIdSet(saveResult);

                List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
                
                String cvQry = SchemaHelper.getObjectQuery('ContentVersion', '') + ' WHERE Id IN : cvIdSet AND IsLatest = true ORDER BY CreatedDate DESC';
                
                for (ContentVersion cv : Database.query(cvQry)) {
                    System.debug('cv bric '+cv.Record_ID__c+ ' == '+cv.ContentDocumentId);
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cv.ContentDocumentId;
                    cdl.LinkedEntityId = cv.Record_ID__c;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    contentDocumentLinksToInsert.add(cdl);
                }

                if(contentDocumentLinksToInsert != null) {
                    saveResult = new List<Database.SaveResult>();
                    saveResult = Database.insert(contentDocumentLinksToInsert, false);
                }
            }
        }
    }

    /** 
     * @description Returns a collection of successfully inserted sObject record ids
     * @date Nov-5-2024  
     * @param saveResult
     * */
    private Set<Id> recordIdSet(List<Database.SaveResult> saveResult) {
        
        Set<Id> idSet = new Set<Id>();
        for(Database.SaveResult sr : saveResult) {
            if(sr.isSuccess()) {
                idSet.add(sr.getId());
            }
        }
        return idSet;
    }
}