/*
* Author: Bricoleur Technologies - John Paulo M. Sulit (jp@bricoleurtech.com)
* Created Date: Oct 27, 2023
* Description: Controller for OnlineQuoteForm page
* Test Class: OnlineQuoteFormControllerTest_Bric
* History: 	Oct 27, 2023 - Created
*           Dec 20, 2023 - Added feature to convert time value to string
*/

public without sharing class OnlineQuoteFormController_Bric {
    
    public String oppId {get; set;}
    public String additionalMsg {get; set;}
    public String declineReason {get; set;}
    public String IPAddress {get; set;}
    public String locResp {get; set;}
    public String acceptedTimeStr {get; set;}
    public Opportunity opp {get; set;}
    public Boolean displayTcError {get; set;}

    /*public OnlineQuoteFormController_Bric(ApexPages.StandardController controller) 
    {
        this.opp = (Opportunity) controller.getRecord();
        queryOpp();
    }*/

    public OnlineQuoteFormController_Bric() 
    {
        IPAddress = ApexPages.currentPage().getHeaders().get('True-Client-IP');
        if(String.isBlank(IPAddress)) 
        {
            IPAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        }  
        if(String.isBlank(IPAddress)) 
        {
            IPAddress = ApexPages.currentPage().getHeaders().get('X-Forwarded-For');
        } 
        displayTcError = false;
        getUserLocation(IPAddress);
        queryOpp();
    }


    public PageReference acceptQuote()
    {
        if(String.isNotBlank(oppId))
        {
            Opportunity oppToUpdate = new Opportunity();
            oppToUpdate.Id = oppId;
            //oppToUpdate.Client_Accepted_Bric__c = System.now();
            oppToUpdate.Digital_Quote_Accepted_Bric__c = 'Yes';
            oppToUpdate.StageName = 'Q Accepted';
            oppToUpdate.Location_Response_Bric__c = locResp;
            oppToUpdate.Customer_IP_Address_Bric__c = IPAddress;
            oppToUpdate.Manually_Approved_Bric__c = false;
            
            try
            {
                update oppToUpdate;
                PageReference pageRef = new PageReference(Label.Online_Quote_Form_URL_VF_Bric+oppId);
                pageRef.setRedirect(true);
                return pageRef;
            }
            catch(Exception e)
            {
                System.debug(e.getMessage());
            }
        }
        return null;
    }

    public PageReference declineQuote()
    {
        if(String.isNotBlank(oppId))
        {
            Opportunity oppToUpdate = new Opportunity();
            oppToUpdate.Id = oppId;
            oppToUpdate.Digital_Quote_Accepted_Bric__c = 'No';
            oppToUpdate.Decline_Message_Bric__c = additionalMsg;
            oppToUpdate.Reason_for_Decline_Bric__c = declineReason;
            oppToUpdate.Client_Declined_Bric__c = System.now();
            oppToUpdate.StageName = 'Q Declined';
            oppToUpdate.Location_Response_Bric__c = locResp;
            oppToUpdate.Customer_IP_Address_Bric__c = IPAddress;
            oppToUpdate.Manually_Approved_Bric__c = false;

            try
            {
                update oppToUpdate;
                PageReference pageRef = new PageReference(Label.Online_Quote_Form_URL_VF_Bric+oppId);
                pageRef.setRedirect(true);
                return pageRef;
            }
            catch(Exception e)
            {
                System.debug(e.getMessage());
            }
        }
        return null;
    }

    public List<SelectOption> getDeclineReasons()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','Please select a reason for decline'));
        options.add(new SelectOption('Need quote updated/changed','Need quote updated/changed'));
        options.add(new SelectOption('Too Expensive','Too Expensive'));
        options.add(new SelectOption('Not Ready Now','Not Ready Now'));
        options.add(new SelectOption('Found someone else to do the job','Found someone else to do the job'));
        return options;
    }

    public void getUserLocation(String userIpAddress)
    {
        if(!Test.isRunningTest())
        {
            Http httpProtocol = new Http();
            HttpRequest request = new HttpRequest();
            String endpoint = 'http://ipinfo.io/'+userIPAddress+'/json';
            request.setEndPoint(endpoint);
            request.setMethod('GET');
            HttpResponse response = httpProtocol.send(request);
            locResp = response.getBody();
        }
        // JSONParser parser = JSON.createParser(response.getBody());
        // while (parser.nextToken() != null) 
        // {
        //     if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'city')) 
        //     {
        //         parser.nextToken();
        //         strCity = parser.getText();
        //     }
        //     if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'region')) 
        //     {
        //         parser.nextToken();
        //         strRegion = parser.getText();
        //     }
        //     if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'country')) 
        //     {
        //         parser.nextToken();
        //         strCountry = parser.getText();
        //     }
        //     if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'postal')) 
        //     {
        //         parser.nextToken();
        //         strPostal = parser.getText();
        //     }
        // }
    }

    public void queryOpp()
    {
        oppId = ApexPages.currentPage().getParameters().get('Id');

        if(String.isNotBlank(oppId))
        {
            opp = new Opportunity();
            opp = [SELECT Id, 
                            /*Opportunity.Account.FirstName,
                            Opportunity.Account.LastName,
                            Opportunity.Account.Business_Name_Bric__c,*/
                            Job_Address_Bric__c,
                            Job_Suburb_Bric__c,
                            Job_State_Bric__c,
                            Job_Post_Code_Bric__c,
                            Opportunity.Account.Phone,
                   			Opportunity.Account.Name,
                            /*Opportunity.Account.PersonMobilePhone,
                            Opportunity.Account.PersonEmail,*/
                            Quote_Number_Bric__c,
                            //GST_Bric__c,
                            Amount,
                            Client_Accepted_Bric__c,
                            Digital_Quote_Accepted_Bric__c,
                            Opp_ID_Bric__c,
                            (SELECT Id,
                                    Product2.Name,
                                    Quote_Description_Long_Bric__c,
                                    Quantity,
                                    UnitPrice,
                                    TotalPrice FROM OpportunityLineItems) FROM Opportunity
                            WHERE Id =: oppId];    
                            
            if(opp.Client_Accepted_Bric__c != null)
            {
                //acceptedTimeStr = opp.Client_Accepted_Bric__c.format('h:mm a');
            }
        }
    }
}