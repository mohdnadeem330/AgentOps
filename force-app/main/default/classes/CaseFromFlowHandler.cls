/**
* @File Name : CaseFromFlowHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 22, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 22, 2025 |   | Initial Version
**/

public without sharing class CaseFromFlowHandler {

    // Wrapper class for input parameters
    public class InputWrapper {
        @InvocableVariable(required=true)
        public Id submitterAccountId;
		@InvocableVariable(required=true)
		public String email;
        @InvocableVariable(required=true)
		public String callFromFlowName;
    }

    // Wrapper class for output (optional, can be expanded if needed)
    public class OutputWrapper {
        @InvocableVariable
        public Case newCase;
    }

    @InvocableMethod(label='Create Case for Account' description='Creates a Case for the given Account from Flow')
    public static List<OutputWrapper> createCaseFromFlow(List<InputWrapper> inputList) {
        List<OutputWrapper> results = new List<OutputWrapper>();
		InputWrapper input = inputList[0];

        if (input.submitterAccountId != null) {
            Account acc = [SELECT Id, PersonEmail FROM Account WHERE Id = :input.submitterAccountId LIMIT 1];

            // Call helper to create the Case record
            Case newCase = createCaseHelper(new List<Account>{ acc }, input.email);
            
            if(input.callFromFlowName == 'UpdateAccountContactDetails') {
                newCase.Priority = 'Emergency';
            }
            
            insert newCase;

            OutputWrapper result = new OutputWrapper();
            result.newCase = [SELECT Id, AccountId, CaseNumber, Subject, Priority, Status, OwnerId FROM Case WHERE Id =:newCase.Id];
            results.add(result);
        }

        return results;
    }

    // Your provided helper method for creating the Case
    private static Case createCaseHelper(List<Account> accountList, String email) {
        Group queue = Utilities.getQueueInformation('MergeCaseQueue');
        String caseOwnerId = queue != null && queue.Id != null ? queue.Id : UserInfo.getUserId();

        Case newCase = new Case();
        newCase.RecordTypeId = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT);
        newCase.CustomerType__c = CustomerAPIConstants.CASE_CUSTOMER_TYPE_OWNER;
        newCase.Origin = CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL;
        newCase.AccountId = accountList[0].Id;
        newCase.SubVertical__c = 'Customer Portal and App - Live Aldar';
        newCase.CaseCategory__c = 'Data - Account Merge';
        newCase.Subject = CustomerAPIConstants.MULTI_ACCOUNT_FOUND_SUBJECT + ' ' + email; //Submit for Merge Request
        newCase.OwnerId = caseOwnerId;
        newCase.Email__c = email;
		newCase.Duplicate_Email_Merge_Requester__c = UserInfo.getUserId();
        newCase.isValidationBypass__c = true;

        Database.DMLOptions options = new Database.DMLOptions();
        options.assignmentRuleHeader.useDefaultRule = false;
        newCase.setOptions(options);

        return newCase;
    }

    /**
    * @description  Checks if there is any other Account record with the same email address 
    *               as the one on the specified Case record, excluding the Account linked to that Case. 
    *               Primarily used to detect duplicate Person Accounts based on email.
    * @param caseId   The Id of the Case record used to retrieve the associated Account and Email.
    * @return Boolean Returns true if another Account with the same email exists
    */
    public static Boolean checkDuplicateRecordByEmail(String caseId) {
        List<Case> caseRecords = [SELECT Id, Email__c, AccountId FROM Case WHERE Id =: caseId AND Email__c != NULL AND AccountId != NULL AND Recordtype_Name__c = 'Requests' AND CaseCategory__c = 'Contact Center' AND SubCategory__c = 'Contact Details Update' LIMIT 1];

        if(!caseRecords.isEmpty()) {
            List<Account> accList = [SELECT Id FROM Account WHERE PersonEmail =:caseRecords[0].Email__c AND Id !=: caseRecords[0].AccountId AND Merging_Status__c != 'Merge Completed'];

            if(accList != NULL && !accList.isEmpty()) {
                return true;
            }
        }

        return false;
    }
}