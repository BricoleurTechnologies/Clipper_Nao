/**
 * @description Queueable class that generates document templates for NAO
 * @author Bricoleur Technologies
 * @date Aug-15-2024
 */

public class DocTemplateGen_Queueable implements Queueable, Database.AllowsCallouts {
    // The request list passed to the Queueable job
    private List<Invoke_DocTemplateGen.Request> requestList;

    // Constructor to pass the request list
    public DocTemplateGen_Queueable(List<Invoke_DocTemplateGen.Request> requestList) {
        this.requestList = requestList;
    }

    // The execute method where the logic is run asynchronously
    public void execute(QueueableContext context) {
        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        List<Database.SaveResult> saveResult = new List<Database.SaveResult>();
        Map<Id, Invoke_DocTemplateGen.Request> requestMap = new Map<Id, Invoke_DocTemplateGen.Request>();

        if(!requestList[0].docTemplates.isEmpty()) {

            Invoke_DocTemplateGen.Request req = requestList[0];
            String qryFields = '';

            String objName = DocTemplateGenUtil.getObjectNameById(req.recordId);

            for (Document_Template__c dt : requestList[0].docTemplates) {

                if(objName == dt.sObject__c && String.isNotBlank(dt.Title_Custom_Field__c)) { 
                    qryFields += dt.Title_Custom_Field__c+',';
                }
            }

            qryFields = qryFields.subString(0, qryFields.length() - 1);

            String objQry = 'SELECT '+qryFields+' FROM '+objName+' WHERE Id = \''+req.recordId+'\' LIMIT 1';
            Map<Id, sObject> sObjectMap = new Map<Id, sObject>(Database.query(objQry));

            // Step 1: Generate PDFs and create ContentVersion objects
            for (Document_Template__c dt : requestList[0].docTemplates) {
                try {
                    // Create a PageReference for the Visualforce page
                    String vfParam = dt.VisualForce_Template__c +'?Id='+req.recordId+'&sObjectType='+dt.sObject__c+'&childSObjectType='+dt.Child_sObject__c+'&pdfLogo='+dt.Logo_Image_URL_Formula__c;

                    PageReference pdfPage = new PageReference('/apex/'+vfParam);

                    // Render the page as a PDF
                    Blob pdfBlob = !Test.isRunningTest() ? pdfPage.getContentAsPDF() : Blob.valueOf('Test');
                    
                    // Create a ContentVersion object for the PDF
                    ContentVersion cv = new ContentVersion();
                    cv.Title = dt.Document_Title_Prefix__c;
                    if(String.isNotBlank(dt.Title_Custom_Field__c)) {
                        if(!sObjectMap.isEmpty() && sObjectMap.containsKey(req.recordId)) {
                            cv.Title += ' - ' + sObjectMap.get(req.recordId).get(dt.Title_Custom_Field__c);
                        }
                    }
                    cv.PathOnClient = cv.Title+'.pdf';
                    cv.VersionData = pdfBlob;
                    cv.IsMajorVersion = true;
                    cv.Record_ID__c = req.recordId;

                    // Collect ContentVersion for bulk insertion
                    contentVersionsToInsert.add(cv);

                    // Map ContentVersion to the Request recordId
                    requestMap.put(cv.Id, req);

                } catch (Exception e) {
                    // Handle any exceptions (you may want to log these)
                    System.debug('Error generating PDF for record ' + req.recordId + ': ' + e.getMessage());
                }
            }

            // Step 2: Insert all ContentVersions in bulk
            if (!contentVersionsToInsert.isEmpty()) {
                
                saveResult = Database.insert(contentVersionsToInsert, false);
                Set<Id> cvIdSet = recordIdSet(saveResult);

                // Step 3: Create ContentDocumentLinks in bulk
                List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
                
                String cvQry = SchemaHelper.getObjectQuery('ContentVersion', '') + ' WHERE Id IN : cvIdSet';
                System.debug('cvQry bric '+cvQry);
                for (ContentVersion cv : Database.query(cvQry)) {

                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cv.ContentDocumentId;
                    cdl.LinkedEntityId = cv.Record_ID__c;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';

                    // Collect ContentDocumentLink for bulk insertion
                    contentDocumentLinksToInsert.add(cdl);
                }

                // Step 4: Insert all ContentDocumentLinks in bulk
                if (!contentDocumentLinksToInsert.isEmpty()) {
                    saveResult = new List<Database.SaveResult>();
                    saveResult = Database.insert(contentDocumentLinksToInsert, false);
                }
            }
        }
    }

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