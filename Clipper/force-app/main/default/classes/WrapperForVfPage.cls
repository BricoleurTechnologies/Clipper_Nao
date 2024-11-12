public class WrapperForVfPage {
    private WrapperForPDF obj {get;set;}
    public String recordId {get;set;}
    public String locationProductRecordIDs {get;set;}
    public List<String> locationRecordIdList {get;set;}  //wareHouse location list (text)
    public List<location_product__c> wareHouseLocationOBJ {get;set;} //product list
    public string WareHouseLocation {get;set;}
    public string stockTakeID {get;set;}
    public string endDate {get;set;}
    public string startDate {get;set;}
    public string freezeDate {get;set;}
    public string wareHouse {get;set;}
    public string companyName {get;set;}
    public string owner{get;set;}
    public stocktake__c stocktakeObj {get;set;}
    Public List<attachment> attachmentList{get;set;}
    private boolean currentstockitemChecked{get;set;}
    
    
    public WrapperForPDF getWrapperForPDF()
    {
        return this.obj;
    }
    public void setWrapperForPDF(WrapperForPDF obj)
    {
        this.obj = obj;
    }
    
    public WrapperForVfPage(ApexPages.StandardSetController stdController){
        String locationProductRecordIDs =  ApexPages.currentPage().getParameters().get('locationProductRecordIDs');
        String locationId =  ApexPages.currentPage().getParameters().get('id');
        currentstockitemChecked=Boolean.valueOf(ApexPages.currentPage().getParameters().get('itemChecked'));
        system.debug('id'+locationId);
        system.debug('locationRecordIdList'+locationProductRecordIDs);
        if(locationProductRecordIDs != null && locationProductRecordIDs != '')
        {
            locationProductRecordIDs = locationProductRecordIDs.replace('[','');
            locationProductRecordIDs = locationProductRecordIDs.replace(']','');
            locationRecordIdList = locationProductRecordIDs.split(',');
            wareHouseLocationOBJ = [select id,Location__c,Location__r.Name,In_Stock__c,Warehouse_Location__c,Product__r.name, Product__r.ProductCode  from location_product__c  where ID IN :locationRecordIdList AND location__c =:locationId];
            stocktakeObj= [select id,Warehouse__c,name,createdDate,End_Date__c,Freeze_Date_Time__c, Owner.name from stocktake__c where Warehouse__c=:wareHouseLocationOBJ[0].Location__c limit 1];
            wareHouse=wareHouseLocationOBJ[0].Location__r.Name;
            endDate=  string.valueof(stocktakeObj.End_Date__c); 
            startdate=string.valueof(stocktakeObj.CreatedDate);
            freezedate=string.valueof(stocktakeObj.Freeze_Date_Time__c);
            owner=string.valueof(stocktakeObj.Owner.name);
           Organization CompanyNameObj = [SELECT Id, name FROM Organization WHERE Id = :UserInfo.getOrganizationId()];
			companyName=string.valueof(CompanyNameObj.name);
       
            system.debug('CompanyName:'+companyName);
            
        }
    }
    
    @InvocableMethod(label = 'Generate PDF' description = 'Generate PDF to be sent to customer and attatched to SF Location record')
    public static void generatePDF(List<WrapperForPDF> wrapperObj){
        system.debug('InvocableMethod');
        WrapperForVfPage ext;
        String selectedLocationId = wrapperObj[0].locationId;
        List<String> locationProdIds=wrapperObj[0].LocationprodIDList;
        Schema.Location locationOBJ=[select id,name from Location where ID = : selectedLocationId];         
        List<ContentDocument> filelist = [SELECT Id, Title FROM ContentDocument WHERE Title != ''];
        Map<String,ContentDocument> fileMap = new Map<String,ContentDocument>();
        string allstring = string.join(locationProdIds,',');
        
        for(ContentDocument fileRecord : filelist){
            fileMap.put(fileRecord.Title, fileRecord);
        }
        PageReference pdf =  Page.GeneratePDFvfPage;
        pdf.getParameters().put('id',selectedLocationId);
        pdf.getParameters().put('locationProductRecordIDs',allstring);
        pdf.getParameters().put('itemChecked',String.valueof(wrapperObj[0].IncludeCurrentStockCount));
        pdf.setRedirect(true);
        Blob body;
        try
        {
            body = !Test.isRunningTest()?pdf.getContentAsPDF():Blob.valueOf('This is a test PDF content');
            String fileRecName = locationOBJ.name + '.pdf';
            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S'; 
            cv.PathOnClient = fileRecName;
            cv.Title = fileRecName;
            cv.VersionData = body;
            if(fileMap.get(fileRecName)?.Id != NULL){
                cv.ContentDocumentId = fileMap.get(fileRecName)?.Id;
            }
            insert cv;   
            
            if(cv.ContentDocumentId == null){
                Id cdId = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Title = :fileRecName LIMIT 1]?.ContentDocumentId;                        
                
                ContentDocumentLink cd = New ContentDocumentLink();
                cd.LinkedEntityId = locationOBJ.Id;
                cd.ContentDocumentId = cdId;
                cd.shareType = 'V';
                insert cd; 
                
            }
        }    
        
        catch(DmlException e)
        {                    
            throw new AuraHandledException(e.getMessage());   
        }   
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(new String[]{'sfteam@bricoleurtech.com' });
        message.setSubject('Stock Take Result Summary' );
        message.setHtmlBody('Here\'s a summary for the Stock Take.');
        blob stringBlob;
        stringBlob = PDf.getContentAsPdf();
        Attachment attach=new Attachment();
        attach.Body = stringBlob;
        attach.Name = 'Confirmation of product';
        attach.IsPrivate = false;
        attach.ParentId = locationOBJ.id;
        Messaging.EmailFileAttachment attachmentObj = new Messaging.EmailFileAttachment();
        attachmentObj.setContentType('application/pdf');
        attachmentObj.setFileName('AccountSummary-.pdf');
        attachmentObj.setInline(false);
        attachmentObj.setBody(stringBlob);
        message.setFileAttachments(new Messaging.EmailFileAttachment[]{ attachmentObj });
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ message });
    } 
}