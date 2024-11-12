public class CalculateInStockLocProduct_Bric {

   
    @InvocableMethod(label='Calculate In Stock' description='Returns In Stock total for Location and Product' category='Location Product')
    public static void getInStockLocationProduct(List<ID> locationProductIds) {
             
        Set<Id> prodIds = new Set<Id>();
        Set<Id> locIds = new Set<Id>();        
        Map<String,Location_Product__c> locationProductMap = new Map<String,Location_Product__c>();
        Map<String,Decimal> locationProductInStockMap = new Map<String,Decimal>();     
        
        List<Location_Product__c> locProductList = [SELECT Id, Location__c, Product__c FROM 
                                                   Location_Product__c WHERE Id IN: locationProductIds];
        
        for(Location_Product__c locProd : locProductList){
            String key = locProd.Location__c + '-' + locProd.Product__c;
            locationProductMap.put(key,locProd);

            prodIds.add(locProd.Product__c);
            locIds.add(locProd.Location__c);
        }
        
        //Calculate In Stock field 
        //(total number (amount) in stock from inventory movements)
        
        List<Inventory_Movement__c> inventoryMovementList =[SELECT Movement__c,Product__c,Location__c
                                                            FROM Inventory_Movement__c 
                                                            WHERE Product__c != null AND Location__c != null
                                                            AND Product__c IN: prodIDs AND Location__c IN: locIDs];
        
        for(Inventory_Movement__c invMovement : inventoryMovementList){
            String key = invMovement.Location__c + '-' + invMovement.Product__c;
            if(locationProductInStockMap.get(key) != null){
                
                locationProductInStockMap.put(key,locationProductInStockMap.get(key) + invMovement.Movement__c);
            }else{                
                
                locationProductInStockMap.put(key,invMovement.Movement__c);
            }
        }
        
        system.debug('locationProductInStockMap ' + locationProductInStockMap.keySet());
        
        List<Location_Product__c> locProdToUpdateList = new  List<Location_Product__c>();
        for(String locProdKey : locationProductMap.keySet()){
            Location_Product__c locProd = new Location_Product__c();
            locProd.Id = locationProductMap.get(locProdKey)?.Id;
            locProd.In_Stock__c = locationProductInStockMap.get(locProdKey);
            locProdToUpdateList.add(locProd);
            
        }
        
        system.debug('locProdToUpdateList ' + locProdToUpdateList);
		Database.update(locProdToUpdateList);  
    }
    
}