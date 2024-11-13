global class ScheduleOrderCreation implements Schedulable {
    global void execute(SchedulableContext SC) {
        OrderCreationBatch batch = new OrderCreationBatch();
        Database.executeBatch(batch);
    }
}