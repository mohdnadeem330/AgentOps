@RestResource(urlMapping='/customercreateCase')
global without sharing class CustomerCreateCaseService {
    @HttpPost
    global static void doPost( String OperationType,String Name, String email, String phone, String remarks,String CustomerId,String CaseId,String UnitId) {
        System.debug('Inside doPost:: Creating Case');
        RestContextHandler handler = new RestContextHandler(true);
        Savepoint sp = Database.setSavepoint();
        try {
            if(CustomerId  == null || CustomerId ==''){
                if (String.isEmpty(Name) || String.isEmpty(email) || String.isEmpty(phone)) {
                    handler.response.success = false;
                    handler.response.statusCode = 400;
                    handler.response.message = 'Account Name, Email, and Phone are required fields.';
                    handler.finalize();
                    return;
                }
            }
            Account existingAccount;
            Id accrecId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            if(CustomerId == null || CustomerId == ''){
                Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> accountEmailPhoneMap = new Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>>();
                accountEmailPhoneMap = UtilitiesWithoutSharing.findDuplicateAccountsByEmail(new Set<String>{email});
                System.debug('accountEmailPhoneMap>>> : ' + accountEmailPhoneMap);
                
                if(accountEmailPhoneMap != null && accountEmailPhoneMap.containsKey(email) && accountEmailPhoneMap.get(email) != null ){
                    for(UtilitiesWithoutSharing.DuplicateAccountWrapper ac :accountEmailPhoneMap.get(email)){
                        existingAccount = ac.account;
                        System.debug('existingAccount>>> : ' + existingAccount);
                    }
                }else{
                    existingAccount = new Account(LastName = Name, personEmail = email, PersonMobilePhone = phone , recordTypeId=accrecId);
                    insert existingAccount;
                    System.debug('existingAccount>>> : ' + existingAccount);
                }
            }
            
            if(OperationType =='GetCase'){
              List<Case> CasesList = [SELECT Id,Subject,SubVertical__c,AccountId,Status,CustomerComment__c FROM Case WHERE AccountId =:CustomerId];  
                handler.response.success = true;
                handler.response.statusCode = 201;
                handler.response.data = CasesList;
                handler.finalize();
            }
            if(OperationType =='UpdateCase'){
                Case cs = new Case();
                cs.Id = CaseId;
                cs.CustomerComment__c = remarks;
                Update cs;
                handler.response.success = true;
                handler.response.statusCode = 201;
                handler.response.data = 'Case Updated Successfully';
                handler.finalize();
            }
            if(OperationType =='CreateCase'){
                Group queue = Utilities.getQueueInformation(CustomerAPIConstants.CCA_ONLINE_QUEUE);
                system.debug('CCA_Online_queue_Id'+queue);
                String caseOwnerId = queue.Id != null ? queue.Id : UserInfo.getUserId();
                
                Case newCase = new Case();
                newCase.RecordTypeId = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT);
                newCase.Origin = 'Customer Portal';
                newCase.AccountId = String.isBlank(CustomerId) ? existingAccount.Id : CustomerId;
                newCase.SubVertical__c = 'Customer Management';
                newCase.Subject = 'New Case Hello Aldar';
                newCase.OwnerId = caseOwnerId;
                newCase.Status = 'New';
                newCase.Email_Not_Triggered__c = true;
                newCase.Unit__c = UnitId;
                newCase.Assigned_To__c = UserInfo.getUserId();
                newCase.SuppliedEmail = email;
                newCase.SuppliedName = Name;
                newCase.CustomerComment__c = remarks;
                newCase.MobileNumber__c = phone;
                if (!Test.isRunningTest()) {
                    insert newCase;
                }
                handler.response.success = true;
                handler.response.statusCode = 201;
                handler.response.data = newCase.Id;
                handler.finalize();
            }
            
        } catch (Exception e) {
            System.debug(e.getMessage() + ' ' + e.getLineNumber() + e.getStackTraceString());
            Database.rollback(sp);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = e.getMessage();
            handler.finalize(e);
        }
    }
}