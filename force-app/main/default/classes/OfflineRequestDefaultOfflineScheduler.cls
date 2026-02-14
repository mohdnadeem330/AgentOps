global class OfflineRequestDefaultOfflineScheduler implements Schedulable{

     global void execute(SchedulableContext sc) {
        OfflineRequestDefaultOnlineOfflineBatch batch = new OfflineRequestDefaultOnlineOfflineBatch(false, true);
        database.executeBatch(batch);
    }
}