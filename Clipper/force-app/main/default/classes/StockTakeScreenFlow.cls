public class StockTakeScreenFlow {
    public class StockTakeScreenFlowQueueable implements Queueable{
        private List<FlowParamsOrder> customerParams;
        public List<FlowParamsOrder> getcustomerParams()
        {
            return this.customerParams;
        }
        
        public void setCustomerParams(List<FlowParamsOrder> customerParamsObj)
        {
            this.customerParams=customerParamsObj;
        }
        /*  private StockTakeScreenFlowQueueable(List<FlowParamsOrder> flowParamObj) {
customerParams = flowParamObj;
}*/
        
        public void execute(QueueableContext context) {
            system.debug('customerParams'+customerParams);
            
            list<Stocktake_Warehouse_Location__c> stocktakeWarehouseLocationListClassLevel = new List<Stocktake_Warehouse_Location__c>();
            list<Stocktake_Result__c> stockTakeResultListClassLevel = new List<Stocktake_Result__c>();
            
            if(this.customerParams[0].StocktakeWarehouseLocationList!=null && this.customerParams[0].StocktakeWarehouseLocationList.size()>0){
                for(Stocktake_Warehouse_Location__c OBJ:this.customerParams[0].StocktakeWarehouseLocationList){
                    Stocktake_Warehouse_Location__c stockTakeWareHouseOBJ = new Stocktake_Warehouse_Location__c();
                    stockTakeWareHouseOBJ.Warehouse_Location__c=OBJ.Warehouse_Location__c;
                    stocktakeWarehouseLocationListClassLevel.add(stockTakeWareHouseOBJ);
                }
            }
                if(stocktakeWarehouseLocationListClassLevel.size()>0){
                    database.insert(stocktakeWarehouseLocationListClassLevel);
                }
                if(this.customerParams[0].StockTakeResultList!=null && this.customerParams[0].StockTakeResultList.size()>0){
                    for(Stocktake_Result__c obj:this.customerParams[0].StockTakeResultList){
                        Stocktake_Result__c stockTakeResultOBJ = new Stocktake_Result__c();
                        stockTakeResultOBJ.Location_Product_ID__c =  obj.Location_Product_ID__c;
                        stockTakeResultOBJ.Start_Date__c=obj.Start_Date__c;
                            stockTakeResultOBJ.Original_Count__c=obj.Original_Count__c;
                            stockTakeResultOBJ.End_Date__c=obj.End_Date__c;
                        
                        stockTakeResultListClassLevel.Add(stockTakeResultOBJ);
                    }
                }
                    if(stockTakeResultListClassLevel.size()>0){
                        database.insert(stockTakeResultListClassLevel);
                        
                    }
                
                
            
            
        }
    }
    @InvocableMethod(label = 'Stock Take Queueable Class' description = 'Create Stock Take WareHouse Loaction Records & Stock Take Results Records Async')
    public static void CreateAsyncRecords(List<FlowParamsOrder> customerParams1)
    {
        system.debug('customerParams1'+customerParams1);
        StockTakeScreenFlow.StockTakeScreenFlowQueueable stockTakeScreenFlowQueueableObj = new StockTakeScreenFlow.StockTakeScreenFlowQueueable();
        stockTakeScreenFlowQueueableObj.setCustomerParams(customerParams1);
        System.enqueueJob(stockTakeScreenFlowQueueableObj);
    }
    
}