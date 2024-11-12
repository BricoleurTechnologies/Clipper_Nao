public without sharing class CalculateCurrentInventory_Bric {
    
    @InvocableMethod(label='Calculate Current Inventory' description='Returns Total Inventory Count' category='Product')
    public static void getProductInventory(List<ID> ids) {
        
        List<Product2> productList = [SELECT Id,Total_Available__c FROM Product2 WHERE Id IN :ids];
        
        for(Product2 prod : productList){
            List<AggregateResult> groupedResults =[SELECT SUM(Movement__c)movementTotal FROM Inventory_Movement__c WHERE Product__c =: prod.Id];
            String str = '' + groupedResults[0].get('movementTotal');
            prod.Total_Available__c = Decimal.ValueOf(str);
        }
        
        update productList;
    }

}