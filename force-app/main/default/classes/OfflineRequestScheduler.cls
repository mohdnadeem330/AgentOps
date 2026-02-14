global class OfflineRequestScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        OfflineRequestBatch batch = new OfflineRequestBatch();
        database.executeBatch(batch, 50);
    }
}