global class BatchToProjectTargetService implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    
    Map<String, Decimal> projectValueMap = new Map<String, Decimal>();

    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BatchToProjectTargetService(), 200);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        List<String> statusList = new List<String>{'Pending', 'Approve Pending', 'Sold'};
        String query = 'SELECT Id, Unit__c, Unit__r.Project__c, BookingDate__c, NetAmount__c, Status__c FROM SalesOrder__c WHERE Status__c IN :statusList AND BookingDate__c = THIS_YEAR';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<SalesOrder__c> salesOrderList){
        for (SalesOrder__c salesOrder: salesOrderList) {
            // projectIds.add(salesOrder.Unit__r.Project__c);
            // monthNos.add(String.valueOf(salesOrder.BookingDate__c.month()));
            // yearNos.add(String.valueOf(salesOrder.BookingDate__c.year()));
            String projectMonthYear = salesOrder.Unit__r.Project__c + '_' + salesOrder.BookingDate__c.month() + '_' + salesOrder.BookingDate__c.year();
            if (projectValueMap.containsKey(projectMonthYear)) {
                projectValueMap.put(projectMonthYear, projectValueMap.get(projectMonthYear) + salesOrder.NetAmount__c);
            } else {
                projectValueMap.put(projectMonthYear, salesOrder.NetAmount__c);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        String yearNo = String.valueOf(date.today().year());
        List<ProjectTargets__c> projectTargetList = [SELECT Id, Project__c, BudgetMonth__c, BudgetYear__c, AchievedUnits__c, AchievedAmount__c 
                                                        FROM ProjectTargets__c WHERE BudgetYear__c =: yearNo];

        for (ProjectTargets__c projectTarget: projectTargetList) {
            String projectMonthYear = projectTarget.Project__c + '_' + projectTarget.BudgetMonth__c + '_' + projectTarget.BudgetYear__c;
            if (projectValueMap.containsKey(projectMonthYear)) {
                projectTarget.AchievedAmount__c = projectValueMap.get(projectMonthYear);
            }
        }

        if (!projectTargetList.isEmpty()) {
            update projectTargetList;
        }
    }
}