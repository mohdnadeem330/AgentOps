public class KYCValidityExpirySchedular implements System.Schedulable {
    public KYCValidityExpirySchedular() {}
    public void execute(SchedulableContext sc) {
        List<Account> lstAccountToBeUpdated = new List<Account>();
        List<Account> lstAccount = [SELECT Id, KYC_Validity_Status__c, KYC_Expired_Date__c, KYC_ValidityDate__c, KYC_StatusUpdatedBy__c, KYC_ExpiryComments__c, PassportExpiryDate__pc FROM Account WHERE PassportExpiryDate__pc = TODAY];
        for (Account acc : lstAccount) {
            acc.KYC_Validity_Status__c = Constants.NOT_VALID;
            acc.KYC_Expired_Date__c = null;
            acc.KYC_ValidityDate__c = null;                   
            acc.KYC_StatusUpdatedBy__c = UserInfo.getUserId();
            acc.KYC_ExpiryComments__c = 'Passport expired.';
            lstAccountToBeUpdated.add(acc);
        }
        KYCValidityController.updateAccounts(lstAccountToBeUpdated);
    }
}