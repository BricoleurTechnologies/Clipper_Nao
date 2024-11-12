public class BatchInvocableClassStockTake {
    @InvocableMethod(label = 'Create Inventory Movement Record' description = 'create two Inventory Movement Records with different recordtype ')
     public static void SendItemToXeroFlow()
    {
        BatchInventoryMovement obj= new BatchInventoryMovement();
        database.executebatch(obj,200);
        
    }
}