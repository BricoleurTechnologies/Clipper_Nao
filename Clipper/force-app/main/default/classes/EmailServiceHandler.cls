public with sharing class EmailServiceHandler implements Messaging.InboundEmailHandler {
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      
        String trimmedEmailBody = email.plainTextBody.trim().replace('\n','').replace('\r','');
        String minifiedBody = trimmedEmailBody.substringBetween('[image: Property Enquiry]', 'User IP Address:');
        String name, emailAddress, phone, message, listingId, subject, fromAddress, enquiryType;
 
        system.debug('## trimmedEmailBody: ' + trimmedEmailBody);
        subject = email.subject;
        fromAddress = envelope.fromAddress;
        
        if(minifiedBody != null){
            name = ScrapeEmailBody(minifiedBody,'From:>>>>>>', 'Email:>>>>>>');
            emailAddress = ScrapeEmailBody(minifiedBody,'Email:>>>>>>', 'Phone:>>>>>>');
            phone = ScrapeEmailBody(minifiedBody,'Phone:>>>>>>', 'Message:>>>>>>');
            message = ScrapeEmailBody(minifiedBody,'Message:>>>>>>', 'Listing ID');
            listingId = ScrapeEmailBody(minifiedBody,'Listing ID:', '>>>');
            enquiryType = 'Lease';
        }else{
            minifiedBody = trimmedEmailBody.substringBetween('You have received a new lead', 'Remember, you can only use the information');
            name = ScrapeEmailBody(minifiedBody,'Name: ', 'Email: ');
            emailAddress = ScrapeEmailBody(minifiedBody,'Email: ', '<mailto:');
            phone = ScrapeEmailBody(minifiedBody,'Phone: ', 'About me: ');
            message = ScrapeEmailBody(minifiedBody,'I would like to: ', 'Comments:');
            listingId = ScrapeEmailBody(minifiedBody,'Property id: ', 'Property address:');
            enquiryType = 'Sale';
        }
        
        
        List<CRE_Email_bric__c> creEmailList = new List<CRE_Email_bric__c>();
        CRE_Email_bric__c creEmail = new CRE_Email_bric__c();
        creEmail.Received_bric__c = System.now();
        creEmail.Subject_bric__c = subject;
        creEmail.Enquiry_Type_bric__c = enquiryType;
        creEmail.From_bric__c = fromAddress;
        creEmail.Email_bric__c = emailAddress;
        creEmail.Phone_bric__c = phone;
        creEmail.Message_bric__c = message;
        creEmail.Body_bric__c = email.htmlBody;
        creEmail.Listing_Id_bric__c = listingId;
        creEmailList.add(creEmail);
        
      	insert creEmailList;
        return result;
    }
    
    
    public static String ScrapeEmailBody(String emailBody, String startText, String endText){
        String scrapeText = emailBody.substringBetween(startText, endText);
        scrapeText = scrapeText.replace('> ','').replace('>','');
        
        return scrapeText;
        
    }
}