/**
* @description       : To create merge case for duplicate accounts
* @author            : Sarah J D
* @group             : 
* @last modified on  : 03-25-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class CreateCaseComponentController {
    
    private static final String CASE_SUBVERTICAL_CUSTOMERPORTAL_LIVEALDAR  = 'Customer Portal and App - Live Aldar';//NOPMD: [Code Style-FieldNamingConventions]
    private static final String CASE_CASECATEGORY_DATA_ACCOUNTMERGE        = 'Data - Account Merge';//NOPMD: [Code Style-FieldNamingConventions]
    private static final String CLOSED					        		   = 'Closed';//NOPMD: [Code Style-FieldNamingConventions]
    private static final String EMPTY_STRING                               = '';
    private static final String SPACE_STRING                               = ' ';
//    private static final String LIKE_OPERATOR                              = '%';
    private static final String CASE_STRING                                = 'Case';
    private static final String NOT_APPLICABLE							   = 'This is applicable only for Person Accounts';
    private static final String ACCOUNT_NO_DUPLICATES					   = 'No duplicates found!';
    private static final String CASE_SUBJECT							   = 'Account merge request submitted by ';
    private static final String CASE_MESSAGE_STRING                        = 'Account merge case already exist in system - ';
    private static final String CASE_MESSAGE_NEW_STRING                    = 'Account merge case have been created successfully - ';
    
    @AuraEnabled
    public static String returnToastMessage(String accountId){
        if(accountId != null && String.isNotBlank(accountId)){
            Account acc	= [SELECT Id, Email__c, PersonEmail, RecordType.Name FROM Account WHERE Id=:accountId];
            
            if(acc.RecordType.Name == Constants.PERSON_ACCOUNT_RT) {
                
                Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> getDuplicates	= UtilitiesWithoutSharing.findDuplicateAccountsByEmail(new Set<String>{acc.PersonEmail});
                
                if(getDuplicates != null && !getDuplicates.isEmpty() && getDuplicates.containsKey(acc.PersonEmail) && getDuplicates.get(acc.PersonEmail).size() == 1) {
                    return CreateCaseComponentController.ACCOUNT_NO_DUPLICATES;
                } else if(getDuplicates != null && !getDuplicates.isEmpty() && getDuplicates.containsKey(acc.PersonEmail) && getDuplicates.get(acc.PersonEmail).size() > 1) {
                    String getToastMessage		= returnCaseToastMessage(acc);
                    return getToastMessage;
                }
            } else {
                return CreateCaseComponentController.NOT_APPLICABLE;
            }
        }
        return null;
    }
    
    @AuraEnabled
    public static String returnCaseToastMessage(Account accountData) {
        if(accountData != null && accountData.PersonEmail != null && String.isNotBlank(accountData.PersonEmail)) {
            Map<Id, Account> accountMap = new Map<Id, Account>();
            Set<Id> accountSets         = new Set<Id>();
//            String emailString          = CreateCaseComponentController.LIKE_OPERATOR + accountData.PersonEmail + CreateCaseComponentController.LIKE_OPERATOR;
            List<Account> accList       = [SELECT Id, PersonEmail, Email__c, (SELECT Id, Status, CaseNumber FROM Cases WHERE Status !=:CreateCaseComponentController.CLOSED
                                                                              AND SubVertical__c =:CreateCaseComponentController.CASE_SUBVERTICAL_CUSTOMERPORTAL_LIVEALDAR AND CaseCategory__c =:CreateCaseComponentController.CASE_CASECATEGORY_DATA_ACCOUNTMERGE),
                                           RecordTypeId, RecordType.Name
                                           FROM Account WHERE PersonEmail =:accountData.PersonEmail AND RecordType.Name =:Constants.PERSON_ACCOUNT_RT];
            
            if(accList != null && !accList.isEmpty()) {
                String returnText = CreateCaseComponentController.EMPTY_STRING;
                for(Account acc: accList) {
                    if(acc.Cases != null && acc.Cases.size() != 0 && acc.Id == accountData.Id){
                        returnText = CreateCaseComponentController.CASE_MESSAGE_STRING + acc.Cases.get(0).CaseNumber;
                        return returnText;
                    } else if(acc.Cases != null && acc.Cases.size() != 0) {
                        returnText = CreateCaseComponentController.CASE_MESSAGE_STRING + acc.Cases.get(0).CaseNumber;
                    }
                }
                if(returnText == null || String.isBlank(returnText)) {
                    Case newCase 				= CustomerProfileWebservice.createCaseHelper(new List<Account>{accountData}, true);
                    newCase.Subject     		= CASE_SUBJECT + UserInfo.getFirstName() + CreateCaseComponentController.SPACE_STRING + UserInfo.getLastName();
                    newCase.CustomerComment__c	= null;
                    newCase.Origin = 'Chat';
                    newCase.OwnerId = UserInfo.getUserId();
                    
                    Database.SaveResult insertResult = Database.insert(newCase, false);
                    System.debug(insertResult);
                    if (insertResult.isSuccess()) {
                        Case insertedCase = [SELECT CaseNumber FROM Case WHERE Id = :insertResult.getId()];
                        return (CreateCaseComponentController.CASE_MESSAGE_NEW_STRING + insertedCase.CaseNumber);
                    } else {
                        return null;
                    }
                } else {
                    return returnText;
                }
            }
        }
        return null;
    }
}