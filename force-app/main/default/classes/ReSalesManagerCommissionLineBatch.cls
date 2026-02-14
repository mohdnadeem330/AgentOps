global class ReSalesManagerCommissionLineBatch implements Database.Batchable<sObject>, Database.Stateful{

    global void execute(SchedulableContext ctx) { 
        database.executebatch(this,200); 
    }
    
    String strMonth = '';
    String strYear = '';
    
    global ReSalesManagerCommissionLineBatch(String strMonth, String strYear) {
        this.strYear = strYear;
        this.strMonth = strMonth;
    }
    global ReSalesManagerCommissionLineBatch(){
        this.strYear = String.valueOf(date.today().year());
        this.strMonth = String.valueOf((date.today().month() - 1));
        if(date.today().month() == 1){
            this.strMonth = '12';
            this.strYear = String.valueOf(date.today().year() - 1);
        }
    }
    
     global Database.QueryLocator start(Database.BatchableContext bc) {
        String strMonth = this.strMonth;
        String strYear = this.strYear;
        String userTeam = 'ReSales';
        String query = 'SELECT AcceleratorCommissionAmount__c,AcceleratorPercentage__c,TargetAmount__c,TargetMonth__c,KPI1__c,KPI2__c,TargetYear__c,AcceleratorTargetAmount__c,ResourceName__c,KPIPayoutPercentage__c FROM MonthlySalesTarget__c WHERE TargetMonth__c =: strMonth AND TargetYear__c =: strYear AND Team__c =: userTeam';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<MonthlySalesTarget__c> monthlySalesTarget){
        Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget = new Map<Id, MonthlySalesTarget__c>();
        List<MonthlySalesTarget__c> lstMonthlySalesTarget = new List<MonthlySalesTarget__c>();
       
        for(MonthlySalesTarget__c objMSaleTarget : monthlySalesTarget) {
            managerBasedMonSalesTarget.put(objMSaleTarget.ResourceName__c, objMSaleTarget);
            lstMonthlySalesTarget.add(objMSaleTarget); 
        }
        Map<String, object> results = new Map<String, object>();
        reSalesCommissionPayoutService.commisionPayoutLines(results,  managerBasedMonSalesTarget, lstMonthlySalesTarget,  strMonth, strYear,  true, true);
        reSalesCommissionPayoutService.validateCommissionPaylineItems((List<CommissionPayoutLine__c>)results.get('payoutLines'), 
                                                                      (List<CommissionLineItem__c>)results.get('lstCommisionLineItems'),
                                                                      (Map<Id, SalesOrder__c>)results.get('mapSalesOrders'),
                                                                      (Map<String,CommissionPayoutLine__c>)results.get('mapExistingCommissionPayOuts'),
                                                                      this.strMonth,this.strYear);
    }
    global void finish(Database.BatchableContext bc){} 

}