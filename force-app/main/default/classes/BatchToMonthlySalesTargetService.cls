global class BatchToMonthlySalesTargetService implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    
    Map<String, Decimal> salesManagerValueMap = new Map<String, Decimal>();
    Map<String, Decimal> salesManagerInventoryValueMap = new Map<String, Decimal>();
    Map<String, Decimal> salesManagerLaunchValueMap = new Map<String, Decimal>();
    
    Map<String, Decimal> brokerManagerValueMap = new Map<String, Decimal>();
    Map<String, Decimal> brokerManagerInventoryValueMap = new Map<String, Decimal>();
    Map<String, Decimal> brokerManagerLaunchValueMap = new Map<String, Decimal>();

    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BatchToMonthlySalesTargetService(), 200);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        // List<String> statusList = new List<String>{'Pending', 'Approve Pending', 'Sold'};
        List<String> statusList = new List<String>{'Sold'};
        String query = 'SELECT Id, BookingDate__c, SalesApprovedDate__c, NetAmount__c, Status__c, SalesManager__c, BrokerManager__c, BrokerManagerId__c, InventoryLaunch__c FROM SalesOrder__c WHERE Status__c IN :statusList AND SalesApprovedDate__c = THIS_YEAR';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<SalesOrder__c> salesOrderList){
        for (SalesOrder__c salesOrder: salesOrderList) {
            String salesManagerMonthYear = salesOrder.SalesManager__c + '_' + salesOrder.SalesApprovedDate__c.month() + '_' + salesOrder.SalesApprovedDate__c.year();
            
            String brokerManagerMonthYear = salesOrder.BrokerManagerId__c + '_' + salesOrder.SalesApprovedDate__c.month() + '_' + salesOrder.SalesApprovedDate__c.year();
            system.debug('RRR BrokerManagerMonthYear:'+ brokerManagerMonthYear);
            if (salesManagerValueMap.containsKey(salesManagerMonthYear)) {
                salesManagerValueMap.put(salesManagerMonthYear, salesManagerValueMap.get(salesManagerMonthYear) + salesOrder.NetAmount__c);
            } else {
                salesManagerValueMap.put(salesManagerMonthYear, salesOrder.NetAmount__c);
            }
            
            if (brokerManagerValueMap.containsKey(brokerManagerMonthYear)) {
                brokerManagerValueMap.put(brokerManagerMonthYear, brokerManagerValueMap.get(brokerManagerMonthYear) + salesOrder.NetAmount__c);
            } else {
                brokerManagerValueMap.put(brokerManagerMonthYear, salesOrder.NetAmount__c);
            }

            if (salesOrder.InventoryLaunch__c == 'Inventory') {
                if (salesManagerInventoryValueMap.containsKey(salesManagerMonthYear)) {
                    salesManagerInventoryValueMap.put(salesManagerMonthYear, salesManagerInventoryValueMap.get(salesManagerMonthYear) + salesOrder.NetAmount__c);
                } else {
                    salesManagerInventoryValueMap.put(salesManagerMonthYear, salesOrder.NetAmount__c);
                }
            } else if (salesOrder.InventoryLaunch__c == 'Launch') {
                if (salesManagerLaunchValueMap.containsKey(salesManagerMonthYear)) {
                    salesManagerLaunchValueMap.put(salesManagerMonthYear, salesManagerLaunchValueMap.get(salesManagerMonthYear) + salesOrder.NetAmount__c);
                } else {
                    salesManagerLaunchValueMap.put(salesManagerMonthYear, salesOrder.NetAmount__c);
                }
            }
            
            if (salesOrder.InventoryLaunch__c == 'Inventory') {
                if (brokerManagerInventoryValueMap.containsKey(brokerManagerMonthYear)) {
                    brokerManagerInventoryValueMap.put(brokerManagerMonthYear, brokerManagerInventoryValueMap.get(brokerManagerMonthYear) + salesOrder.NetAmount__c);
                } else {
                    brokerManagerInventoryValueMap.put(brokerManagerMonthYear, salesOrder.NetAmount__c);
                }
            } else if (salesOrder.InventoryLaunch__c == 'Launch') {
                if (brokerManagerLaunchValueMap.containsKey(brokerManagerMonthYear)) {
                    brokerManagerLaunchValueMap.put(brokerManagerMonthYear, brokerManagerLaunchValueMap.get(brokerManagerMonthYear) + salesOrder.NetAmount__c);
                } else {
                    brokerManagerLaunchValueMap.put(brokerManagerMonthYear, salesOrder.NetAmount__c);
                }
            }
            System.debug('RRR Broker Manager Value Map Keyset:'+ brokerManagerValueMap.keyset());
            System.debug('RRR Broker Manager Value Map Values:'+ brokerManagerValueMap.values());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        String monthNo = String.valueOf(date.today().month());
        String yearNo = String.valueOf(date.today().year());
        List<MonthlySalesTarget__c> monthlySalesTargetList = [SELECT Id, ResourceName__c, TargetMonth__c, TargetYear__c, AchievedAmount__c, 
                                                                AcceleratorAchievedAmount__c, InventoryAchievedAmount__c, LaunchAchievedAmount__c 
                                                                FROM MonthlySalesTarget__c WHERE TargetYear__c =: yearNo
                                                                ORDER BY TargetMonth__c, AchievedAmount__c DESC];

        for (MonthlySalesTarget__c monthlySalesTarget: monthlySalesTargetList) {
            String salesManagerMonthYear = monthlySalesTarget.ResourceName__c + '_' + monthlySalesTarget.TargetMonth__c + '_' + monthlySalesTarget.TargetYear__c;
            
            //String brokerManagerMonthYear = monthlySalesTarget.ResourceName__c + '_' + monthlySalesTarget.TargetMonth__c + '_' + monthlySalesTarget.TargetYear__c;
            
            if (salesManagerValueMap.containsKey(salesManagerMonthYear)) {
                monthlySalesTarget.AchievedAmount__c = salesManagerValueMap.get(salesManagerMonthYear);
            }
            if (salesManagerInventoryValueMap.containsKey(salesManagerMonthYear)) {
                monthlySalesTarget.InventoryAchievedAmount__c = salesManagerInventoryValueMap.get(salesManagerMonthYear);
            }
            if (salesManagerLaunchValueMap.containsKey(salesManagerMonthYear)) {
                monthlySalesTarget.LaunchAchievedAmount__c = salesManagerLaunchValueMap.get(salesManagerMonthYear);
            }
            
            if (brokerManagerValueMap.containsKey(salesManagerMonthYear)) {
                monthlySalesTarget.AchievedAmount__c = brokerManagerValueMap.get(salesManagerMonthYear);
            }
            if (brokerManagerInventoryValueMap.containsKey(salesManagerMonthYear)) {
                monthlySalesTarget.InventoryAchievedAmount__c = brokerManagerInventoryValueMap.get(salesManagerMonthYear);
            }
            if (brokerManagerLaunchValueMap.containsKey(salesManagerMonthYear)) {
                monthlySalesTarget.LaunchAchievedAmount__c = brokerManagerLaunchValueMap.get(salesManagerMonthYear);
            }
        }
        if (!monthlySalesTargetList.isEmpty()) {
            update monthlySalesTargetList;
        }

        AggregateResult[] achievedSumList = MonthlySalesTargetService.fetchMonthlySalesTargetRank();
        List<Decimal> achievedList = new List<Decimal>();
        Map<Decimal, String> achievedMap = new Map<Decimal, String>();
        for (AggregateResult ar: achievedSumList) {
            Decimal targetAmount = ar.get('target') == null ? 0 : (Decimal)ar.get('target');
            Decimal achievedAmount = ar.get('achieved') == null ? 0 : (Decimal)ar.get('achieved');

            Decimal achievedPercentage = achievedAmount == 0 ? 0 : ((achievedAmount / targetAmount) * 100);
            if (achievedMap.containsKey(achievedPercentage)) {
                String resources = achievedMap.get(achievedPercentage) + ',' + (String)ar.get('ResourceName__c');
                achievedMap.put(achievedPercentage, resources);
            } else {
                achievedMap.put(achievedPercentage, (String)ar.get('ResourceName__c'));
            }
            achievedList.add(achievedPercentage);
        }
        achievedList.sort();
        
        Map<String, Decimal> rankBySM = new Map<String, Decimal>();
        Decimal rank = 0;
        List<Decimal> finalList = new List<Decimal>();
        for(Integer i = achievedList.size()-1; i >= 0; i--){
            finalList.add(achievedList.get(i));
        }
        for (Decimal achievedPercent: finalList) {
            rank ++;
            String resources = achievedMap.get(achievedPercent);
            if (resources.contains(',')) {
                for (String resource : resources.split(',')) {
                    rankBySM.put(resource, rank);
                }
            } else {
                rankBySM.put(resources, rank);
            }
        }

        List<MonthlySalesTarget__c> monthlySalesTargetAgentList = new List<MonthlySalesTarget__c>();
        for (MonthlySalesTarget__c monthlySalesTarget: monthlySalesTargetList) {
            if (monthlySalesTarget.TargetMonth__c == monthNo) {
                MonthlySalesTarget__c monthlySalesTargetAgent = new MonthlySalesTarget__c();
                monthlySalesTargetAgent.Id = monthlySalesTarget.Id;
                if (rankBySM.containsKey(monthlySalesTarget.ResourceName__c)) {
                    monthlySalesTargetAgent.AgentRank__c = rankBySM.get(monthlySalesTarget.ResourceName__c);
                    monthlySalesTargetAgentList.add(monthlySalesTargetAgent);
                }
            }
        }

        if (!monthlySalesTargetAgentList.isEmpty()) {
            update monthlySalesTargetAgentList;
        }

        // List<MonthlySalesTarget__c> monthlySalesTargetAgentList = [SELECT Id, ResourceName__c, TargetMonth__c, TargetYear__c, AchievedAmount__c, 
        //                                                         AcceleratorAchievedAmount__c, InventoryAchievedAmount__c, LaunchAchievedAmount__c 
        //                                                         FROM MonthlySalesTarget__c WHERE TargetYear__c =: yearNo
        //                                                         ORDER BY TargetMonth__c, AchievedAmount__c DESC];

        // Decimal lastAmountValue = 0;
        // String lastMonth = '';
        // Decimal rank = 1;
        // for (MonthlySalesTarget__c monthlySalesTarget: monthlySalesTargetAgentList) {
        //     if(monthlySalesTarget.AchievedAmount__c == null) {
        //         monthlySalesTarget.AgentRank__c = null;
        //         continue;
        //     }
        //     if (lastMonth == '' || monthlySalesTarget.TargetMonth__c != lastMonth) {
        //         rank = 1;
        //         monthlySalesTarget.AgentRank__c = rank;
        //         lastMonth = monthlySalesTarget.TargetMonth__c;
        //         lastAmountValue = monthlySalesTarget.AchievedAmount__c;
        //     } else {
        //         if (monthlySalesTarget.AchievedAmount__c == lastAmountValue) {
        //             monthlySalesTarget.AgentRank__c = rank;
        //         } else {
        //             rank++;
        //             monthlySalesTarget.AgentRank__c = rank;
        //             lastMonth = monthlySalesTarget.TargetMonth__c;
        //             lastAmountValue = monthlySalesTarget.AchievedAmount__c;
        //         }
        //     }
        // }

        // if (!monthlySalesTargetAgentList.isEmpty()) {
        //     update monthlySalesTargetAgentList;
        // }
    }
}