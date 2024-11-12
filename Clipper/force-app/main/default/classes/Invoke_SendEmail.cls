/**
 * @description Invocable class that sends emails
 * @date Sept-11-2024
 * @author JP Sulit (Created)
*/
public class Invoke_SendEmail {

    @InvocableMethod(label='Hanna Send Email' description='Send Email based on Flow Inputs')
    public static List<EmailOutput> invokeSendEmail(List<EmailInput> emails) {

        EmailOutput output = new EmailOutput();
        EmailInput email = emails[0];
		if(email != null) {
            
            EmailService.EmailWrapper emailWrapper = new EmailService.EmailWrapper();
            emailWrapper.setToAddrList = email.setToAddrList;
            emailWrapper.ccList = email.ccList;
            emailWrapper.emailTemplateId = email.emailTemplateId;
            //emailWrapper.subject = email[0].subject;
            emailWrapper.orgWideEmail = email.orgWideEmail;
            emailWrapper.senderDisplayName = email.senderDisplayName;
            emailWrapper.replyTo = email.replyTo;
            emailWrapper.whatId = email.whatId;
            emailWrapper.targetObjectId = email.targetObjectId;
            emailWrapper.attachmentId = email.attachmentId;
            emailWrapper.saveAsActivity = email.saveAsActivity;
            
            
            try {
                Messaging.SingleEmailMessage emailToSend = EmailService.sendEmail(emailWrapper);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailToSend}, false);
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
        @InvocableVariable
        public Boolean saveAsActivity;
    }

    public class EmailOutput {
        @InvocableVariable
        public String errorMsg;
    }
}