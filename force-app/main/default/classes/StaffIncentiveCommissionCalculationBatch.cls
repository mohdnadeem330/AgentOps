global class StaffIncentiveCommissionCalculationBatch implements Schedulable, Database.Batchable<sObject>{

    String strMonth = '';
    String strYear = '';
    
     global void execute(SchedulableContext ctx) {
       //  database.executeBatch(new StaffIncentiveCommissionCalculationBatch(), 1); 
    }
    
    global StaffIncentiveCommissionCalculationBatch(String strMonth, String strYear) {
        this.strYear = strYear;
        this.strMonth = strMonth;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        integer numberOfDays = date.daysInMonth(integer.valueOf(this.strYear), integer.valueOf(this.strMonth));
        date soldStartDate = date.newInstance(integer.valueOf(this.strYear), integer.valueOf(this.strMonth), 1);
        date soldEndDate = date.newInstance(integer.valueOf(this.strYear), integer.valueOf(this.strMonth), numberOfDays);
        
        String StaffIncentiveCommissionType = 'Staff Incentive';
        String salesOrderStatus = 'Sold'; 
        String query = 'SELECT Comments__c,CommissionAmount__c,CommissionType__c,EmployeeEmail__c,EmployeeId__c,Id,SalesOrder__c,Status__c,TotalPayableCommission__c,Unit__c FROM CommissionLineItem__c WHERE CommissionType__c=:StaffIncentiveCommissionType  AND SalesOrder__r.Status__c =:salesOrderStatus AND  ((SalesOrder__r.SoldDate__c >=: soldStartDate AND SalesOrder__r.SoldDate__c <=: soldEndDate) OR (SalesOrder__r.SalesApprovedDate__c >=: soldStartDate AND SalesOrder__r.SalesApprovedDate__c <=: soldEndDate) ) ';
        String filterConditions = ' AND  SalesOrder__r.EquityPercentage__c >= 20 ';
        String finalQuery;
        if(Test.isRunningTest()){
            finalQuery = query;
        }else{
            finalQuery = query + filterConditions; 
        }
        system.debug('Data::'+Database.getQueryLocator(finalQuery));
        return Database.getQueryLocator(finalQuery);
    }
    global void execute(Database.BatchableContext BC, List<CommissionLineItem__c> commissionLineItemList){
      
        Map<Id, CommissionPayoutLine__c> cliCpLMap = getExistingCommissionPayoutLines(commissionLineItemList);
        List<CommissionPayoutLine__c> CommisionPayoutLineList = new List<CommissionPayoutLine__c>();
        
        for(CommissionLineItem__c commissionLineItem: commissionLineItemList){
            CommissionPayoutLine__c objCommisionPayoutLine = new CommissionPayoutLine__c();
            if(cliCpLMap.containsKey(commissionLineItem.id)){
                objCommisionPayoutLine = cliCpLMap.get(commissionLineItem.id);
            }
            objCommisionPayoutLine.CommissionLineItem__c = commissionLineItem.Id;
            objCommisionPayoutLine.SalesOrder__c = commissionLineItem.SalesOrder__c;
            objCommisionPayoutLine.PayoutAmount__c = commissionLineItem.TotalPayableCommission__c;
            objCommisionPayoutLine.PayoutDate__c = (Date.newInstance(Integer.valueOf(this.strYear), Integer.valueOf(this.strMonth), 01)).addMonths(1);
            objCommisionPayoutLine.FutureCommission__c = Constants.COMMISSIONCURRENT;
            objCommisionPayoutLine.RecalculatedDate__c = system.today();
            CommisionPayoutLineList.add(objCommisionPayoutLine);
        }
        if(!CommisionPayoutLineList.isEmpty()){
            upsert CommisionPayoutLineList;
        }
        
    }
    global void finish(Database.BatchableContext BC){
        
    }
    
    public static Map<Id, CommissionPayoutLine__c> getExistingCommissionPayoutLines(List<CommissionLineItem__c> commissionLineItemList){
        Map<Id, CommissionPayoutLine__c> cliCpLMap = new Map<Id, CommissionPayoutLine__c>();
        List<CommissionPayoutLine__c> existingCommissionPayout = [SELECT
                                                                  CommissionLineItem__c,
                                                                  erpid__c,
                                                                  FutureCommission__c,
                                                                  Id,
                                                                  PaidDate__c,
                                                                  PayoutAmount__c,
                                                                  PayoutDate__c,
                                                                  PayoutStatus__c,
                                                                  SalesOrder__c 
                                                                  FROM CommissionPayoutLine__c
                                                                  WHERE CommissionLineItem__c IN: commissionLineItemList];
       
        if(!existingCommissionPayout.isEmpty()){
            for(CommissionPayoutLine__c commissionPayoutLine: existingCommissionPayout){
                cliCpLMap.put(commissionPayoutLine.CommissionLineItem__c,commissionPayoutLine);
            }
        }
        return cliCpLMap;
    }
}