global class BatchToRMMonthlySalesTargetService implements Schedulable, Database.Batchable<sObject>, Database.Stateful{
   
    Map<String, Decimal> reSalesManagerValueMap = new Map<String, Decimal>();
    global void execute(SchedulableContext ctx) {
        database.executeBatch(new BatchToRMMonthlySalesTargetService(), 200); 
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        String resaleRecordTypeId = ResaleConstants.Resale_Opp_RecordTypeId;
        String query = 'SELECT Id, Amount, OwnerId,Unit__c, TransferredDate__c FROM Opportunity WHERE RecordTypeId =:resaleRecordTypeId  AND Transferred__c = true AND Amount != null';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Opportunity> opportunityList){
        Set<Id> unitsIdSet = new Set<Id>();
        Map<Id, Id> unitCaseOwnerMap = new Map<Id, Id>();
        for(Opportunity opportunity: opportunityList){
            unitsIdSet.add(opportunity.Unit__c);
        }
        List<Case> caseList = [SELECT Id, ownerId, unit__c FROM Case WHERE RecordTypeId =: ResaleConstants.Resale_Case_RecordTypeId AND unit__c in: unitsIdSet];
        for(Case cs: caseList){
            if(!unitCaseOwnerMap.containsKey(cs.unit__c)){
                unitCaseOwnerMap.put(cs.unit__c, cs.ownerId); 
            }
        }
        for(Opportunity opportunity: opportunityList){
            String reSalesManagerMonthYear = opportunity.OwnerId + '_' + opportunity.TransferredDate__c.month() + '_' + opportunity.TransferredDate__c.year();
            String reSalesManagerMonthYearListed;
            if(unitCaseOwnerMap.containsKey(opportunity.unit__c) && opportunity.OwnerId != unitCaseOwnerMap.get(opportunity.unit__c)){
                reSalesManagerMonthYearListed = unitCaseOwnerMap.get(opportunity.unit__c) + '_' + opportunity.TransferredDate__c.month() + '_' + opportunity.TransferredDate__c.year();
            }
            system.debug('reSalesManagerMonthYearListed::'+reSalesManagerMonthYearListed);
            system.debug('opportunity::'+(opportunity.Id+' - '+opportunity.Amount));
            if (reSalesManagerValueMap.containsKey(reSalesManagerMonthYear)) {
                reSalesManagerValueMap.put(reSalesManagerMonthYear, reSalesManagerValueMap.get(reSalesManagerMonthYear) + opportunity.Amount);
            } else {
                reSalesManagerValueMap.put(reSalesManagerMonthYear, opportunity.Amount);
            }
            
            system.debug('reSalesManagerValueMap::'+reSalesManagerValueMap);
            system.debug('reSalesManagerValueMap.containskey(reSalesManagerMonthYearListed)::'+reSalesManagerValueMap.containskey(reSalesManagerMonthYearListed));
            
            if(reSalesManagerMonthYearListed != null && reSalesManagerValueMap.containskey(reSalesManagerMonthYearListed)){
                reSalesManagerValueMap.put(reSalesManagerMonthYearListed, reSalesManagerValueMap.get(reSalesManagerMonthYearListed) + opportunity.Amount);
            } else {
                reSalesManagerValueMap.put(reSalesManagerMonthYearListed, opportunity.Amount);
            }
        }
        
    }
    
    global void finish(Database.BatchableContext BC){
        String monthNo = String.valueOf(date.today().month());
        String yearNo = String.valueOf(date.today().year());
        List<MonthlySalesTarget__c> monthlySalesTargetList = [SELECT Id, ResourceName__c, TargetMonth__c, TargetYear__c, AchievedAmount__c, 
                                                              AcceleratorAchievedAmount__c, InventoryAchievedAmount__c, LaunchAchievedAmount__c,
                                                              AcceleratorPercentage__c, OverachievedAmount__c, TargetAmount__c
                                                              FROM MonthlySalesTarget__c WHERE TargetYear__c =: yearNo AND Team__c = 'ReSales'
                                                              ORDER BY TargetMonth__c, AchievedAmount__c DESC];
        
        for (MonthlySalesTarget__c monthlySalesTarget: monthlySalesTargetList) {
            String salesManagerMonthYear = monthlySalesTarget.ResourceName__c + '_' + monthlySalesTarget.TargetMonth__c + '_' + monthlySalesTarget.TargetYear__c;
           
            if (reSalesManagerValueMap.containsKey(salesManagerMonthYear)) {
                monthlySalesTarget.AchievedAmount__c = reSalesManagerValueMap.get(salesManagerMonthYear);
            }
        }
        if (!monthlySalesTargetList.isEmpty()) {
            update monthlySalesTargetList;
        }
        AggregateResult[] achievedSumList = RMMonthlySalesTargetService.fetchMonthlySalesTargetRank();
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
                    if(monthlySalesTarget.OverachievedAmount__c != 0 && monthlySalesTarget.TargetAmount__c != 0){
                        Decimal acceleratorPercentage = ((monthlySalesTarget.OverachievedAmount__c * 100) / monthlySalesTarget.TargetAmount__c);
                        if(acceleratorPercentage > 125) {
                            monthlySalesTargetAgent.AcceleratorPercentage__c = 2;
                        } else if(acceleratorPercentage > 100 && acceleratorPercentage <125) {
                            monthlySalesTargetAgent.AcceleratorPercentage__c = 1.5;
                        }
                    }
                    monthlySalesTargetAgentList.add(monthlySalesTargetAgent);
                }
            }
        }
        system.debug('monthlySalesTargetAgentList:::'+monthlySalesTargetAgentList);
        if (!monthlySalesTargetAgentList.isEmpty()) {
            update monthlySalesTargetAgentList;
        }
    }
}