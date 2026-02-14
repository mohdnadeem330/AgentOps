public with sharing class PaymentInstallmentTriggerHandler extends TriggerHandler{
    //*** After Update Action***//
    public static set<String> soldSR = new set<String>{Constants.STATUS_APPROVAL_PENDING,Constants.SO_STATUS_RTO_PENDING,Constants.SO_STATUS_SOLD,Constants.SO_STATUS_RTO_Approve_PENDING , Constants.SO_STATUS_RTO_SOLD,Constants.PENDING_STATUS}; 
     public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        map<id,PaymentInstallments__c> paymentInstallmentsToProcess = new map<id,PaymentInstallments__c>();
        map<id,PaymentInstallments__c> paymentInstallmentsToProcessOld = new map<id,PaymentInstallments__c>();
        
        Map<Id, PaymentPlan__c> changedPIMap;
        List<String> changedPISet	= new List<String>();
        
        for (PaymentInstallments__c newPaymentRecord: (List< PaymentInstallments__c >) newList) {
            PaymentInstallments__c oldPaymentRecord = (PaymentInstallments__c)oldmap.get(newPaymentRecord.Id);
            if(newPaymentRecord.ApprovalStatus__c != oldPaymentRecord.ApprovalStatus__c && newPaymentRecord.ApprovalStatus__c == COnstants.APPROVED_STATUS){
                paymentInstallmentsToProcess.put(newPaymentRecord.Id,newPaymentRecord);
                paymentInstallmentsToProcessOld.put(newPaymentRecord.Id,oldPaymentRecord);
            }
            
            //Added by Sarah for ASF-2809 - From here
            if(newPaymentRecord.InstallmentDate__c != oldPaymentRecord.InstallmentDate__c || newPaymentRecord.InstallmentNumber__c != oldPaymentRecord.InstallmentNumber__c || newPaymentRecord.InstallmentPercentage__c != oldPaymentRecord.InstallmentPercentage__c){
                changedPISet.add(newPaymentRecord.PaymentPlan__c);
            }
            //Till here
        }
        if(!paymentInstallmentsToProcess.isEmpty()){
            updateAndNotifiyCustomerRecords(paymentInstallmentsToProcess,paymentInstallmentsToProcessOld);
        }
        if(!changedPISet.isEmpty()){
            changedPIMap = new Map<Id, PaymentPlan__c>([SELECT Id, OnlineFlag__c, Name, isActive__c, PaymentPlanDiscount__c, Description__c FROM PaymentPlan__c WHERE Id IN:changedPISet]);
            PaymentPlanTriggerHandler.processPPChangesForDamascus(changedPIMap, changedPISet);
        }
    }
    //*** Before Update Action***//
    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        for(PaymentInstallments__c newRecord  : (list<PaymentInstallments__c >) newList){
            PaymentInstallments__c oldRecord = (PaymentInstallments__c)oldMap.get(newRecord.Id);
            //If installment date is changed
            if(newRecord.InstallmentDate__c != oldRecord.InstallmentDate__c && oldRecord.InstallmentDate__c!=null && newRecord.OriginalInstallmentDate__c ==null){
                newRecord.OriginalInstallmentDate__c = oldRecord.InstallmentDate__c;
            }
        }
    }
    
    public static void updateAndNotifiyCustomerRecords(map<id,PaymentInstallments__c> paymentInstallmentsToProcess, map<id,PaymentInstallments__c> paymentInstallmentsToProcessOld){
        list<InstallmentLines__c> linesToUpdate = new list<InstallmentLines__c>();
        map<id,InstallmentLines__c> notificationMap = new map<id,InstallmentLines__c>();
        //Get all relevent records and send Email
        //Add filter to chnage only related one
        for(InstallmentLines__c line : [select id,PaymentInstallments__c,InstallmentDate__c,SalesOrder__r.Contact__c from InstallmentLines__c where PaymentInstallments__c in :paymentInstallmentsToProcess.keySet() and SalesOrder__r.Status__c in :soldSR]){
            if( paymentInstallmentsToProcessOld.get(line.PaymentInstallments__c).InstallmentDate__c == line.InstallmentDate__c){
                line.InstallmentDate__c = paymentInstallmentsToProcess.get(line.PaymentInstallments__c).InstallmentDate__c;
                line.RevisedDate__c = paymentInstallmentsToProcess.get(line.PaymentInstallments__c).InstallmentDate__c;
                //Integration batch should pick this chnage in next run
                line.SyncStatus__c = Constants.STATUS_FAILED;
                linesToUpdate.add(line);
                //Trigger notification only if the dates are chnaged
                if(paymentInstallmentsToProcess.get(line.PaymentInstallments__c).TriggerCustomerNotification__c ){
                    notificationMap.put(line.Id,line);
                }
            }
            
        } 
        if(!linesToUpdate.isEmpty()){
            update linesToUpdate;
        }
        if(!notificationMap.isEmpty()){
            //sendMilestoneChnageNotifications(notificationMap);
            database.executebatch(new SendMilestoneChangeNotificationsBatch(notificationMap.keySet()),1);
        }
    }
    
}