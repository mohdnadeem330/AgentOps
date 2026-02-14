global class SalesManagerCommissionLineBatch implements Database.Batchable<sObject>, Database.Stateful{
	global void execute(SchedulableContext ctx) { 
        database.executebatch(this,200);
    }
    
    String strMonth = '';
    String strYear = '';
    
    global SalesManagerCommissionLineBatch(String strMonth, String strYear) {
        this.strYear = strYear;
        this.strMonth = strMonth;
    }
    global SalesManagerCommissionLineBatch(){
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
        String query = 'SELECT AcceleratorCommissionAmount__c,AcceleratorPercentage__c,TargetAmount__c,TargetMonth__c,KPI1__c,KPI2__c,TargetYear__c,AcceleratorTargetAmount__c,ResourceName__c,KPIPayoutPercentage__c FROM MonthlySalesTarget__c WHERE TargetMonth__c =: strMonth AND TargetYear__c =: strYear';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<MonthlySalesTarget__c> monthlySalesTarget){
        system.debug('monthlySalesTarget>>>>'+monthlySalesTarget);
        Map<Id, MonthlySalesTarget__c> managerBasedMonSalesTarget = new Map<Id, MonthlySalesTarget__c>();
        List<MonthlySalesTarget__c> lstMonthlySalesTarget = new List<MonthlySalesTarget__c>();
        for(MonthlySalesTarget__c objMSaleTarget : monthlySalesTarget){
            managerBasedMonSalesTarget.put(objMSaleTarget.ResourceName__c, objMSaleTarget);
            lstMonthlySalesTarget.add(objMSaleTarget); 
        }
        Map<String, object> results = new Map<String, object>(); 
        CommissionPayoutService.commisionPayoutLines(results, managerBasedMonSalesTarget, lstMonthlySalesTarget,this.strMonth, this.strYear, true, false);
    	system.debug('(List<CommissionPayoutLine__c>)>>>>>'+(List<CommissionPayoutLine__c>)results.get('payoutLines'));
        system.debug('(List<lstCommisionLineItems>)>>>>>'+(List<CommissionLineItem__c>)results.get('lstCommisionLineItems'));
        system.debug('(List<mapExistingCommissionPayOuts>)>>>>>'+(Map<String,list<CommissionPayoutLine__c>>)results.get('mapExistingCommissionPayOuts'));
        
        SalesCommissionController.validateCommissionPaylineItems((List<CommissionPayoutLine__c>)results.get('payoutLines'), 
                                                                 (List<CommissionLineItem__c>)results.get('lstCommisionLineItems'),
                                                                 (Map<Id, SalesOrder__c>)results.get('mapSalesOrders'),
                                                                 (Map<String,list<CommissionPayoutLine__c>>)results.get('mapExistingCommissionPayOuts'),
                                                                 this.strMonth,	this.strYear);
    }
    
    global void finish(Database.BatchableContext bc){} 
}