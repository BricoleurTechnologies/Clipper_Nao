public class BatchProcessRCaPIdataToRCjSON implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query ='Select id,data__C,Name,Received__c from RC_API_Data__c where processed__c = false';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext context, List<RC_API_Data__c> rcAPIDataList) {
        if(!rcAPIDataList.isEmpty()){
            
            list<RC_JSON__c> rcJSONobjList = new List<RC_JSON__c>();
            
            for(RC_API_Data__c acApiDatOBJ:rcAPIDataList){
                
                RestResponseFromRealEstate.enquirie apiOBJData = (RestResponseFromRealEstate.enquirie)JSON.deserialize(acApiDatOBJ.Data__c, RestResponseFromRealEstate.enquirie.class) ;
                if(apiOBJData.type=='REALCOMMERCIAL_COM_AU_LEASE'||apiOBJData.type=='REALCOMMERCIAL_COM_AU_BUY'){
                    
                    rcJSONobjList.add(setRCJsonBody(apiOBJData));
                }
            }
            if(!rcJSONobjList.isEmpty()){
                database.insert(rcJSONobjList);
            }
        }
    }
    public void finish(Database.BatchableContext context) {
    }
    
    Public RC_JSON__c setRCJsonBody(RestResponseFromRealEstate.enquirie apiOBJData){
        
        RC_JSON__c rcJSONOBJ = new RC_JSON__c();
        
        rcJSONOBJ.Comments__c=apiOBJData.comments;  
        rcJSONOBJ.Email__c=apiOBJData.contactDetails.email;
        rcJSONOBJ.Enquiry_Id__c=apiOBJData.id;  
        rcJSONOBJ.Full_Name__c=apiOBJData.contactDetails.fullName;  
        rcJSONOBJ.Listing_Id__c=apiOBJData.listing.id;  
        rcJSONOBJ.Phone__c=apiOBJData.contactDetails.phone;
        rcJSONOBJ.Post_Code__c=apiOBJData.contactDetails.postcode;
        rcJSONOBJ.Processed__c=false;  
        rcJSONOBJ.Received__c=datetime.valueof(apiOBJData.receivedAt);  
        rcJSONOBJ.Requested_Information__c=apiOBJData.requestedInformation[0];  
        rcJSONOBJ.Type__c=apiOBJData.type;
        
        if(rcJSONOBJ!=null){
            return rcJSONOBJ;   
        }else{
            return null;
        }
        
    }
    
    Public void getOrCreateContact(RC_JSON__c rcJSONobj){
        if(rcJSONobj!=null){
            List<contact> contactListToInsert = new List<contact>();
            string contactID = '';
            string projectID= '';
            contact existingContact =[Select id,Email from contact where Email =:rcJSONobj.Email__c limit 1];
            Project__c existingProject = [select id from Project__c where Real_Commercial_ID__c =: rcJSONobj.Listing_Id__c limit 1];
            
            if(existingProject!=null){
                projectID=existingProject.id;
                }
            
            if(existingContact!=null){
             contactID =  existingContact.id; 
            }else{
		 List<string> contactNameList = splitFullName(rcJSONobj.Name);
            
            contact con = new contact();
            con.FirstName=contactNameList[0];
            con.LastName=contactNameList[1];
            con.Phone  =rcJSONobj.Phone__c;  
            con.Email=rcJSONobj.Email__c;
            con.MailingPostalCode=rcJSONobj.Post_Code__c;
            contactListToInsert.add(con);
             }
            if(!contactListToInsert.isEmpty()){
                database.insert(contactListToInsert);
                contactID=contactListToInsert[0].id;
            }
        } 
    }
    
    public List<string> splitFullName(String FullName){
        List<String> returnFirstNameLastName = New List<String>();
        String fullNameValue = FullName; 
        
        String[] nameParts = fullNameValue.split(' ', 2);
        
        String FirstString;
        String SecondString;
        
        if (nameParts.size() == 2) {
            FirstString = nameParts[0];
            SecondString = nameParts[1];
        } else {
            FirstString = fullNameValue;
            SecondString = '-';
        }
        
        System.debug('FirstString: ' + FirstString);
        System.debug('SecondString: ' + SecondString);
         returnFirstNameLastName.add(FirstString);
         returnFirstNameLastName.add(SecondString);
        return returnFirstNameLastName;
        
    }
}