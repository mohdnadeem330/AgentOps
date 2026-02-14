global class TasareehPaymentBatch implements Database.Batchable<SObject> {
    String objName;
    
    Public TasareehPaymentBatch(String objName){
        this.objName=objName;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        /*String query;
        String feestatus='INVOICED';
        if(objName=='Permit_Payment__c'){
            query='select id,permit__c,PaymentMatchId__c from Permit_Payment__c where createdDate=TODAY OR LastModifiedDate=TODAY';
        }
         if(objName=='Fees__c'){
            query='select id,permit__c,PaymentMatchId__c,FeeStatus__c,Payment__c from Fees__c where Payment__c=null AND FeeStatus__c= \''+feestatus+'\' AND permit__c!=null';
        }*/
        String query=TasareehIntegration_Util.getPaymentBatchQuery(objName);
         return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        Map<String,Id> paymentIdMap = new Map<String,Id>();
         Map<String,SObject> feeMap = new Map<String,SObject>();
        for (SObject s : scope) {
        if(objName=='Permit_Payment__c'){
            paymentIdMap.put((String)s.get('PaymentMatchId__c'),s.Id);
            
        } else if(objName== 'Fees__c'){
            feeMap.put((String)s.get('PaymentMatchId__c'),s);
        }
        
    }
        List<SObject> lstFeeToUpdate = new List<SObject>();
        if(objName=='Permit_Payment__c'){
              List<Fees__c> fees = TasareehIntegration_Util.getFeesToUpdate(paymentIdMap.keySet());
            for(Fees__c f: fees ){
                if(paymentIdMap.containskey(f.PaymentMatchId__c)) {
                    f.Payment__c=paymentIdMap.get(f.PaymentMatchId__c);
                    lstFeeToUpdate.add(f);
                }
            }
        }  else if(objName=='Fees__c'){
              List<Permit_Payment__c> payments = TasareehIntegration_Util.getPermitPaymentsToUpdate(feeMap.keySet());
            for(Permit_Payment__c p:payments){
                if(FeeMap.containskey(p.PaymentMatchId__c)) {
                    SObject feeRecord=FeeMap.get(p.PaymentMatchId__c);
                    feeRecord.put('Payment__c', p.Id);
                    lstFeeToUpdate.add(feeRecord);
                }
            }
        } 
        update lstFeeToUpdate;
    }
    
    global void finish(Database.BatchableContext BC) {
        if(objName == 'Permit_Payment__c'){
            Database.executeBatch(new TasareehPaymentBatch('Fees__c'),200);
        }
    }
    }