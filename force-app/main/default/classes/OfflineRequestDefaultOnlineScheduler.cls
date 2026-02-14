global class OfflineRequestDefaultOnlineScheduler implements Schedulable{

    global void execute(SchedulableContext sc) {
        OfflineRequestDefaultOnlineOfflineBatch batch = new OfflineRequestDefaultOnlineOfflineBatch(true, false);
        database.executeBatch(batch);
    }
}