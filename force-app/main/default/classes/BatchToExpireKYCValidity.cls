global class BatchToExpireKYCValidity implements Database.Batchable<sObject>{
    global BatchToExpireKYCValidity() { }
    global Database.QueryLocator start(Database.BatchableContext BC){
        String ValidStatus = 'Valid';
        Date todayDate = System.today();
        String query = 'SELECT Id, KYC_Validity_Status__c, KYC_Expired_Date__c, PassportExpiryDate__pc FROM Account WHERE (KYC_Expired_Date__c =: todayDate AND KYC_Validity_Status__c =: ValidStatus) OR PassportExpiryDate__pc =: todayDate';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Account> lstAccounts){
        for (Account acc : lstAccounts) {
            if(acc.KYC_Expired_Date__c == System.today() && acc.KYC_Validity_Status__c == 'Valid') {
                acc.KYC_Validity_Status__c = Constants.EXPIRED;
            } 
            
            if(acc.PassportExpiryDate__pc == System.today()) {
                acc.KYC_Validity_Status__c = Constants.NOT_VALID;
                acc.KYC_Expired_Date__c = null;
                acc.KYC_ValidityDate__c = null;                   
                acc.KYC_StatusUpdatedBy__c = UserInfo.getUserId();
                acc.KYC_ExpiryComments__c = 'Passport expired.';
            }
        }
        if (lstAccounts.size() > 0) {
            update lstAccounts;
        }	
    }
    global void finish(Database.BatchableContext BC){}
}