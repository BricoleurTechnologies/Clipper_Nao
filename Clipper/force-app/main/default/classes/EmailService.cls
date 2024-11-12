/**
 * @description Utility class to send emails
 * @date Sept-11-2024
 * @author JP Sulit (Created)
 * [1] JP Sulit - Nov-6-2024 - Added function that sends bulkified emails
 */

public class EmailService {

    //[1] JP Sulit - Nov-6-2024 - Added function that sends bulkified emails
    public static List<Messaging.SingleEmailMessage> sendBulkEmail(List<EmailWrapper> wrapperEmailList) {
        
        List<Messaging.SingleEmailMessage> bulkEmail = new List<Messaging.SingleEmailMessage>();

        for(EmailWrapper wrapperEmail : wrapperEmailList) {

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();        
            email.setToAddresses(wrapperEmail.setToAddrList);
            email.setTargetObjectId(wrapperEmail.targetObjectId);
            email.setWhatId(wrapperEmail.whatId);
            email.setReplyTo(wrapperEmail.replyTo);
            email.setSaveAsActivity(wrapperEmail.saveAsActivity);
            email.setEntityAttachments(new List<String>{wrapperEmail.attachmentId});
            
            if(!String.isBlank(wrapperEmail.orgWideEmail)){
                email.setOrgWideEmailAddressId(wrapperEmail.orgWideEmail);
            }
            else{
                email.setSenderDisplayName(wrapperEmail.senderDisplayName);
            }
            
            email.setTemplateId(wrapperEmail.emailTemplateId);

            if(wrapperEmail.ccList != null && !wrapperEmail.ccList.isEmpty()) {
                email.setCcAddresses(wrapperEmail.ccList);
            }

            bulkEmail.add(email);
        }

        return bulkEmail;
    }

    public static Messaging.SingleEmailMessage sendEmail(EmailWrapper wrapperEmail) {
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        /*Map<Id, sObject> sObjectMap = new Map<Id, sObject>([SELECT Id, Account_Name__c FROM Order WHERE Id =: wrapperEmail.whatId]);

        List<Messaging.RenderEmailTemplateBodyResult> renderEmail = Messaging.renderEmailTemplate(wrapperEmail.targetObjectId, wrapperEmail.whatId, new List<String>{emailTemplateList[0].HtmlValue});

        System.debug('renderEmail bric '+renderEmail);

        if(emailTemplateList != null && !Test.isRunningTest()) {
            //email.setTemplateId(emailTemplateList[0]?.Id);
            //email.setPlainTextBody(emailTemplateList[0].Body);
            email.setHtmlBody(renderEmail[0].getMergedBody());
        } 
		*/
        
        email.setToAddresses(wrapperEmail.setToAddrList);
        email.setTargetObjectId(wrapperEmail.targetObjectId);
        email.setWhatId(wrapperEmail.whatId);
        email.setReplyTo(wrapperEmail.replyTo);
        email.setSaveAsActivity(wrapperEmail.saveAsActivity);
        email.setEntityAttachments(new List<String>{wrapperEmail.attachmentId});
        
        
        //Sender
        if(!String.isBlank(wrapperEmail.orgWideEmail)){
            email.setOrgWideEmailAddressId(wrapperEmail.orgWideEmail);
        }
        else{
            email.setSenderDisplayName(wrapperEmail.senderDisplayName);
        }
        
        //Template
        email.setTemplateId(wrapperEmail.emailTemplateId);

        if(wrapperEmail.ccList != null && !wrapperEmail.ccList.isEmpty()) {
            email.setCcAddresses(wrapperEmail.ccList);
        }
        
		/*
        List<Messaging.EmailFileAttachment> efaList = setEmailAttachments(new Set<String> {wrapperEmail.whatId});
        
        if(!efaList.isEmpty()) {
            email.setFileAttachments(efaList);
        }*/

        return email;
    }

    @testVisible
    private static List<Messaging.EmailFileAttachment> setEmailAttachments(Set<String> whatIdSet) {
        
        List<Messaging.EmailFileAttachment> efaList = new List<Messaging.EmailFileAttachment>();
        Set<Id> cdIdSet = new Set<Id>();

        for(ContentDocumentLink cdl : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : whatIdSet]) {
            cdIdSet.add(cdl.ContentDocumentId);
        }

        if(!cdIdSet.isEmpty()) {
            for(ContentVersion cv : [SELECT Id, Title, VersionData, FileType FROM ContentVersion WHERE ContentDocumentId IN : cdIdSet AND IsLatest = true]) {
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(cv.Title+'.'+cv.FileType.toLowerCase()); 
                attachment.setBody(cv.VersionData);
                efaList.add(attachment);
            }
        }
        
        return efaList;
    } 

    public class EmailWrapper {

        public List<String> setToAddrList;
        public List<String> ccList;
        
        public String emailTemplateId;
        public String subject;
        public String orgWideEmail;
        public String senderDisplayName;
        public String replyTo;
        public String targetObjectId;
        public String whatId;
        public String attachmentId;
        public Boolean saveAsActivity;
    }
}