global class ScheduledClassToDDRNotificationToBank implements Schedulable{
    public string sentToBankStatus = 'Sent to Bank';
    public string ackStatus = 'ACK';
    public string RequestType = 'New Registration';
    public string CollectionRequestType = 'Collection';
    public string CancellationRequestType = 'Cancellation';
    public void execute(SchedulableContext sc) {
        try{
            List<DDTransaction__c> ddTransactionList = new  List<DDTransaction__c>();
            if(Test.isRunningTest()){
                ddTransactionList = [SELECT
                                 DDBankingReferenceNumber__c,
                                 DDBank__c,
                                 DDResponseFileName__c,
                                 Name,
                                 Requesttype__c,
                                 RequestFileName__c,
                                 TransactionStatus__c,
                                 DirectDebitRequest__r.PayerIdentification__c,
                                 DirectDebitRequest__r.CustomerBankName__c,
                                 DirectDebitRequest__r.CustomerAccountName__c ,
                                 DirectDebitRequest__r.DirectDebitBank__c,
                                 DirectDebitRequest__r.SentTobankDate__c,
                                 DirectDebitRequest__r.Name
                                 FROM DDTransaction__c 
                                 WHERE (TransactionStatus__c=:sentToBankStatus OR TransactionStatus__c=:ackStatus)
                                 AND ((DirectDebitRequest__r.DirectDebitBank__c ='Abu Dhabi Commercial Bank' )
                                      OR (DirectDebitRequest__r.DirectDebitBank__c ='First Abu Dhabi Bank'))
                                 AND   Requesttype__c =: RequestType];
           }else{
                ddTransactionList = [SELECT DDBankingReferenceNumber__c, DDBank__c, DDResponseFileName__c, Name,  Requesttype__c, RequestFileName__c, TransactionStatus__c, DirectDebitRequest__r.PayerIdentification__c, DirectDebitRequest__r.CustomerBankName__c, DirectDebitRequest__r.CustomerAccountName__c , DirectDebitRequest__r.DirectDebitBank__c, DirectDebitRequest__r.SentTobankDate__c, DirectDebitRequest__r.Name FROM DDTransaction__c 
                                     WHERE (TransactionStatus__c=:sentToBankStatus OR TransactionStatus__c=:ackStatus) AND ( (DirectDebitRequest__r.DirectDebitBank__c ='Abu Dhabi Commercial Bank' AND ((DirectDebitRequest__r.SentToBankDays__c >= 3 AND Requesttype__c =: RequestType) OR (DirectDebitRequest__r.SentToBankDays__c >= 1 AND (Requesttype__c =: CollectionRequestType OR Requesttype__c =: CancellationRequestType))))  OR (DirectDebitRequest__r.DirectDebitBank__c ='First Abu Dhabi Bank' AND ((DirectDebitRequest__r.SentToBankDays__c >= 5 AND Requesttype__c =: RequestType) OR (DirectDebitRequest__r.SentToBankDays__c >= 1 AND (Requesttype__c =: CollectionRequestType OR Requesttype__c =: CancellationRequestType)))))];
            } 
            
            
            system.debug('ddTransactionList::'+ddTransactionList);
            if(!ddTransactionList.isEmpty()){  DDRNotificationToBankPDFHandler.sendcsv(ddTransactionList);
            }
        }catch(Exception ex){ LoggerService.save(LoggerService.addApexLog(ex,'ScheduledClassToDDRNotificationToBank','execute',''));
        } 
    }
}