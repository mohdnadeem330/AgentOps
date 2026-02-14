global class ALD_CustomerPaymentNotificationSubBatch implements Database.Batchable<sObject>,Database.AllowsCallouts {
    public String process = 'Payment Reminder';
    public List<String> ilIds = new List<String>();
    public String queryStr = '';
    
    public ALD_CustomerPaymentNotificationSubBatch(String queryStr){
        this.queryStr=queryStr;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('### queryStr -> '+queryStr);
        if(process == 'Payment Reminder' && queryStr == '') {
            queryStr = 'SELECT Id,SalesOrder__r.Account__r.PersonEmail,CustomerName__c,SalesOrder__c,UnitName__c,SalesOrder__r.SoldDate__c,ProjectName__c,SalesOrder__r.Name,SalesOrder__r.Account__r.MobileCountryCode__pc ,SalesOrder__r.Account__r.MobilePhone__pc , SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.ResidentStatus__c,SalesOrder__r.Contact__r.Email,SalesOrder__r.Opportunity__r.Contact__c,InstallmentDate__c,SalesOrder__r.Account__r.CustomerType__c from InstallmentLines__c where PaymentInstallments__r.isHandoverPayment__c =false and (SalesOrder__r.RecordType.Name!=\'RTO\' and SalesOrder__r.OpportunitySaleType__c!=\'RTO\') and SalesOrder__r.Status__c in (\'Approve Pending\', \'Sold\')  and  InstallmentDate__c = NEXT_N_DAYS:46 and OutstandingAmount__c > '+ System.Label.CommissionAmountBuffer+' and Id IN:ilIds';
        } else if(process == 'Mile stone change letter') {
            
        }
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<InstallmentLines__c> scope) {
        for(InstallmentLines__c tempRec : scope){
            ALD_IL_PaymentReminder.sendReminder(tempRec.Id, process, null);
            System.debug('### tempRec.Id -> '+tempRec.Id);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
    
}