public class WrapperForPDF {
  /*  @AuraEnabled @InvocableVariable	public string stockTakeID;
     @AuraEnabled @InvocableVariable public string endDate;
     @AuraEnabled @InvocableVariable public string startDate;
    @AuraEnabled @InvocableVariable public string freezeDate; 
    @AuraEnabled @InvocableVariable public string wareHouse;
    @AuraEnabled @InvocableVariable public List<String> wareHouseLocationOBJ;*/
    
    @AuraEnabled @InvocableVariable public List<string> LocationprodIDList;
   @AuraEnabled @InvocableVariable public Boolean IncludeCurrentStockCount;
        @AuraEnabled @InvocableVariable public string locationId;

    
    }