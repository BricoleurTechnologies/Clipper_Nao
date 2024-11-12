/*
* Author: Bricoleur Technologies - JP Sulit (jp@bricoleurtech.com)
* Created Date: Nov 11, 2023
* Description: Emails online quote form pdf from when quote is accepted.
* Test Class: Invoke_EmailQuotePDFTest_Bric
* History: Nov 11, 2023 - Created       
*          Dec 18, 2023 - Remove func that uploads Fair & Go PDF for Quote Email
*/

public without sharing class Invoke_EmailQuotePDF_Bric 
{
    @InvocableMethod(label='Email PDF to Client')
    public static List<FlowOutputs> emailQuotePdf(List<FlowInputs> input)
    {
        List<FlowOutputs> resultList = new List<FlowOutputs>();
        FlowOutputs output = new FlowOutputs();

        if(input[0].oppId != null)
        {
            try 
            {
                sendEmail(input[0].oppId,
                            input[0].oppName,
                            input[0].oppClientEmail,
                            input[0].templateDevName,
                            input[0].isQuoteEmail);
            } 
            catch (Exception e) 
            {
                output.exceptionMsg = e.getMessage();
            }
            System.debug('output.exceptionMsg '+output.exceptionMsg);
            resultList.add(output);
        }       
        return resultList;
    }

    @future(callout=true)
    public static void sendEmail(String oppId,
                                        String oppName,
                                        String oppClientEmail,
                                        String templateDevName,
                                        Boolean isQuoteEmail)
    {
        Opportunity opp = [SELECT Id, 
                                    Account.Name, 
                                    Service_Subcategory_Bric__c, 
                                    Service_Subcategory_Text_Bric__c,
                                    //Account_First_Name_Bric__c,
                                    Quote_Number_Bric__c,
                                    Owner_Name_Formula_Bric__c,
                                    Owner_Email_Formula_Bric__c,
                                    Digital_Quote_Accepted_Bric__c,
                                    Online_Quote_Form_URL_Bric__c,
                                    //Customer_Name_Formula_Bric__c,
                                    Quote_Email_Content_Bric__c
                                    FROM Opportunity WHERE Id =:  oppId LIMIT 1];

        
        if(String.isBlank(templateDevName))
        {
            if(opp.Digital_Quote_Accepted_Bric__c == 'Yes')
            {
                templateDevName = 'Email_to_customer_when_they_Accept_a_quote_1701135342571';
            }
            else if(opp.Digital_Quote_Accepted_Bric__c == 'No')
            {
                templateDevName = 'Email_to_customer_when_they_DECLINE_a_quote_email_to_be_sent_from_1701134534521';
            }
        }

        EmailTemplate template = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName =: templateDevName LIMIT 1];

        String htmlBody = '';
        String subject = '';
        htmlBody = template.HtmlValue.replace('{{{Opportunity.Account_First_Name_Bric__c}}}', opp.Account.Name);
        htmlBody = htmlBody.replace('{{{Opportunity.Owner_Name_Formula_Bric__c}}}', opp.Owner_Name_Formula_Bric__c);

        if(isQuoteEmail != null && !isQuoteEmail)
        {            
            subject = template.Subject;
            htmlBody = htmlBody.replace('{{{Opportunity.Quote_Number_Bric__c}}}', opp.Quote_Number_Bric__c);
            htmlBody = htmlBody.replace('{{{Opportunity.Owner_Email_Formula_Bric__c}}}', opp.Owner_Email_Formula_Bric__c);
        }
        else 
        {
            subject = template.Subject.replace('{{{Opportunity.Quote_Number_Bric__c}}}', opp.Quote_Number_Bric__c);
            //subject = subject.replace('{{{Opportunity.Customer_Name_Formula_Bric__c}}}', opp.Customer_Name_Formula_Bric__c);
            
            if(String.isNotBlank(opp?.Service_Subcategory_Text_Bric__c))
            {
                htmlBody = htmlBody.replace('{{{Opportunity.Service_Subcategory_Text_Bric__c}}}', opp?.Service_Subcategory_Text_Bric__c);
            }
            else 
            {
                htmlBody = htmlBody.replace('{{{Opportunity.Service_Subcategory_Text_Bric__c}}}', '');
            }

            htmlBody = htmlBody.replace('{{{Opportunity.Online_Quote_Form_URL_Bric__c}}}', opp?.Online_Quote_Form_URL_Bric__c);
            if(String.isNotBlank(opp.Quote_Email_Content_Bric__c))
            {
                htmlBody = htmlBody.replace('{{{Opportunity.Quote_Email_Content_Bric__c}}}', opp?.Quote_Email_Content_Bric__c);
            }
            else 
            {
                htmlBody = htmlBody.replace('<br />{{{Opportunity.Quote_Email_Content_Bric__c}}}<br />', '');
            }
        }

        PageReference pr = new PageReference(Label.Online_Quote_Form_PDF_URL_VF_Bric+oppId);
    
        // ContentVersion cv = new ContentVersion();

        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();

        if(opp.Digital_Quote_Accepted_Bric__c == 'Yes' && !isQuoteEmail)
        {
            attach.setFileName(oppName +'_'+ DateTime.now()+'.pdf');
            attach.Body = !Test.isRunningTest()?pr.getContentAsPdf():Blob.toPDF('Hello World');
            attach.setContentType('application/pdf');
            attach.setInline(true);
        }
        // else if(isQuoteEmail)
        // {
        //     cv = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Title LIKE 'Fair Go Policy%' ORDER BY CreatedDate DESC LIMIT 1];
        //     if(cv != null)
        //         attach.setFileName(cv.Title);
        //         attach.Body = !Test.isRunningTest()?cv.VersionData:Blob.toPDF('Hello World');
        // }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setReplyTo(opp.Owner_Email_Formula_Bric__c);
        if(!isQuoteEmail) mail.setBCcAddresses(new List<String> {opp.Owner_Email_Formula_Bric__c});
        mail.setSenderDisplayName(opp.Owner_Name_Formula_Bric__c);
        mail.setUseSignature(false);
        mail.setToAddresses(new String[]{oppClientEmail});
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        mail.setWhatId(oppId);

        // if(opp.Digital_Quote_Accepted_Bric__c != 'No')
        // {
        if(opp.Digital_Quote_Accepted_Bric__c == 'Yes' && !isQuoteEmail)
        {
            System.debug('attach bric '+attach);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
        }

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
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
        public String templateDevName;
        @InvocableVariable
        public Boolean isQuoteEmail;
    }

    public class FlowOutputs
    {
        @InvocableVariable
        public String exceptionMsg;
    }
}