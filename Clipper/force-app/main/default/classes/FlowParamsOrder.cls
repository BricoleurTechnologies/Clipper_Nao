public class FlowParamsOrder {
    @AuraEnabled @InvocableVariable public List<Stocktake_Warehouse_Location__c> StocktakeWarehouseLocationList;
    @AuraEnabled @InvocableVariable public List<Stocktake_Result__c> StockTakeResultList;
}