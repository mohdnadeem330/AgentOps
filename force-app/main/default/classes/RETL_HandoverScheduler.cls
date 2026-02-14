global with sharing class RETL_HandoverScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Delegate everything to the service
        RETL_HandoverService.scheduleHandover();
    }
}