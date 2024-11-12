/**
 * @description Invocable class that sends emails
 * @date Nov-7-2024
 * @author Bricoleur Technologies
*/
public with sharing class Invoke_SendBulkEmail {
    @InvocableMethod(label='Send Email w/ Attachment' description='Send Email based on Flow Inputs')
    public static List<EmailOutput> invokeSendEmail(List<EmailInput> emails) {

        EmailOutput output = new EmailOutput();
        EmailInput email = emails[0];
		if(email != null) {
            
            Set<String> whatIdSet = new Set<String>(email?.whatIdList);
            Set<String> targetObjIdSet = new Set<String>(email?.targetObjectIdList);
            String sObjName = DocTemplateGenUtil.getObjectNameById(email?.targetObjectIdList[0]);
            Map<Id, Id> cvIdMap = new Map<Id, Id>();

            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            List<EmailService.EmailWrapper> emailWrapperList = new List<EmailService.EmailWrapper>();

            for(ContentVersion cv : email?.attachmentList) {
                if(!cvIdMap.containsKey(cv.Record_ID__c)) {
                    cvIdMap.put(cv.Record_ID__c, cv.Id);
                }
            }

            String sObjQry = SchemaHelper.getObjectQuery(sObjName, '') + ' WHERE Id IN : targetObjIdSet';
            List<sObject> sObjectList = Database.query(sObjQry);

            for(sObject obj : sObjectList) {
                EmailService.EmailWrapper emailWrapper = new EmailService.EmailWrapper();
                Id whatId = (Id) obj.get(email.whatFieldName);
                Id targetObjId = (Id) obj.get(email.targetObjectFieldName);
                emailWrapper.setToAddrList = email.setToAddrList;
                emailWrapper.ccList = email.ccList;
                emailWrapper.emailTemplateId = email.emailTemplateId;
                //emailWrapper.subject = email[0].subject;
                emailWrapper.orgWideEmail = email.orgWideEmail;
                emailWrapper.senderDisplayName = email.senderDisplayName;
                emailWrapper.replyTo = email.replyTo;
                emailWrapper.whatId = whatId;
                emailWrapper.targetObjectId = targetObjId;
                emailWrapper.attachmentId = cvIdMap != null && cvIdMap.containsKey(whatId) ? cvIdMap.get(whatId) : null;
                emailWrapper.saveAsActivity = email.saveAsActivity;
                emailWrapperList.add(emailWrapper);
            }
            
            try {
                List<Messaging.SingleEmailMessage> emailToSend = EmailService.sendBulkEmail(emailWrapperList);
                Messaging.sendEmail(emailToSend, false);
            }
            catch(EmailException e) {
                System.debug('Error: ' + e.getMessage());
                output.errorMsg = e.getMessage();
            }
        }
        return new List<EmailOutput> {output};
    }
    

    public class EmailInput {

        @InvocableVariable(description='List of Email Address Recipients')
        public List<String> setToAddrList;
        @InvocableVariable(description='List of Email Address CCs')
        public List<String> ccList;

        @InvocableVariable(description='Email Template Id' required=true)
        public String emailTemplateId;
        //@InvocableVariable
        //public String subject;
        @InvocableVariable
        public String orgWideEmail;
        @InvocableVariable
        public String senderDisplayName;
        @InvocableVariable
        public String replyTo;
        @InvocableVariable(description='User/Lead/Contact id')
        public String targetObjectId;
        @InvocableVariable(description='Related Record Id of the corresponding Email Template object')
        public String whatId;
        @InvocableVariable(description='Attach Content Version')
        public String attachmentId;
        @InvocableVariable(description='List of Content Version IDs')
        public List<ContentVersion> attachmentList; //[1] JP Sulit - Nov-6-2024 - Updated code to send bulkified emails
        @InvocableVariable(description='List of Related Record Ids')
        public List<String> whatIdList; //[1] JP Sulit - Nov-6-2024 - Updated code to send bulkified emails
        @InvocableVariable(description='List of User/Lead/Contact id')
        public List<String> targetObjectIdList; //[1] JP Sulit - Nov-6-2024 - Updated code to send bulkified emails
        @InvocableVariable(description='Target Object ID Field Name')
        public String targetObjectFieldName; //[1] JP Sulit - Nov-6-2024 - Updated code to send bulkified emails
        @InvocableVariable(description='What ID Field Name')
        public String whatFieldName; //[1] JP Sulit - Nov-6-2024 - Updated code to send bulkified emails
        @InvocableVariable
        public Boolean saveAsActivity;
    }

    public class EmailOutput {
        @InvocableVariable
        public String errorMsg;
    }
}