public class fetchStockTakeResult {

    @AuraEnabled(cacheable=true)
    public static list<Stocktake_Result__c> fetchStockTakeResults(String recordid){        
                  system.debug('returnList'+recordid);   

        list<Stocktake_Result__c> returnList = [SELECT id,name,Stocktake_Count__c FROM Stocktake_Result__c where  Stocktake__c=:recordid];
        for(Stocktake_Result__c obj:returnList){
        }
            
        return returnList;        
    }
    


}