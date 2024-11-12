global  class BatchInventoryMovement implements Database.Batchable<sObject> {
    
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Name,Original_Count__c,flag__c,Stocktake_Count__c,Stocktake__r.Freeze_Date_Time__c FROM Stocktake_Result__c where flag=true';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Stocktake_Result__c> StockTakeResultList){
        list<Inventory_Movement__c> adjustmentInventoryMovementList=new list<Inventory_Movement__c>();
        list<Inventory_Movement__c> stocktakeInventoryMovementList=new list<Inventory_Movement__c>();
        list<Stocktake_Result__c> updateStocktakeResultList=new list<Stocktake_Result__c>();
        
        String adjustmentRecordTypeId = Schema.SObjectType.Inventory_Movement__c.getRecordTypeInfosByDeveloperName().get('Adjustment').getRecordTypeId();
        String stocktakeRecordTypeId = Schema.SObjectType.Inventory_Movement__c.getRecordTypeInfosByDeveloperName().get('Stocktake').getRecordTypeId();
        
        for(Stocktake_Result__c Sr:StockTakeResultList){
            Inventory_Movement__c adjustmentInvMovement = new Inventory_Movement__c();
            Inventory_Movement__c StocktakeInvMovement = new Inventory_Movement__c();
            
            /*     Creating Inventory Record with Adjustment Record Type   */
            
            adjustmentInvMovement.recordtypeID=adjustmentRecordTypeId;
            adjustmentInvMovement.Movement__c=Integer.valueof(Sr.Stocktake_Count__c) - Integer.valueof(sr.Original_Count__c);
            adjustmentInvMovement.As_At__c=Sr.Stocktake__r.Freeze_Date_Time__c;
             adjustmentInventoryMovementList.add(adjustmentInvMovement);
            
       /*     Creating Inventory Record with Stocktake Record Type   */
            
              StocktakeInvMovement.recordtypeID=stocktakeRecordTypeId;
            StocktakeInvMovement.Movement__c=Integer.valueof(Sr.Stocktake_Count__c);
            StocktakeInvMovement.As_At__c=Sr.Stocktake__r.Freeze_Date_Time__c.addSeconds(1);
             stocktakeInventoryMovementList.add(adjustmentInvMovement);
            
            /* Updating StockTake Result flag */
                sr.flag__c=false;
                updateStocktakeResultList.add(sr);
               
                }
        database.insert(adjustmentInventoryMovementList);
        database.insert(stocktakeInventoryMovementList);
        database.Update(updateStocktakeResultList);
        
        
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
    
}