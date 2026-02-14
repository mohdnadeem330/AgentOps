public without sharing class VerifyLeadController {
    
    @AuraEnabled(cacheable=true)
    public static List<UtilitiesWithoutSharing.DuplicateAccountWrapper> getAccounts(String leadRecordId){
        if (String.isEmpty(leadRecordId)) {
            return null;
        }
        // SSC-697, Duplicate Account check based on Email or Mobile Number changes: Bashim
        Lead leadRecord = [SELECT Email, MobilePhone FROM Lead WHERE Id=:leadRecordId LIMIT 1];
        List<UtilitiesWithoutSharing.DuplicateAccountWrapper> dupeAccountMapEmailAndMobile = new List<UtilitiesWithoutSharing.DuplicateAccountWrapper>();
        if (leadRecord != null && leadRecord.Email != null && leadRecord.MobilePhone != null) {
            // SSC-697, Duplicate Account based on Mobile Number changes: Bashim
            // Created a new method with email or mobile number as input to check the existing accounts
            dupeAccountMapEmailAndMobile = UseExistingAccount.findDuplicateAccountsByEmailAndMobileNumber(new Set<String> {leadRecord.Email},new Set<String>{leadRecord.MobilePhone});
            return dupeAccountMapEmailAndMobile;
        } else {
            return null;
        }
    }
    @AuraEnabled
    public static String submitForApprovals(String leadId, String reasonValue, String otherReason){
        Lead lead = new Lead(Id=leadId, EmailApprovalsReason__c = reasonValue, EmailApprovalsOtherReason__c = otherReason);
        update lead;
        
        User user = [SELECT Id,ManagerId, isActive FROM User WHERE Id =: UserInfo.getUserId() Limit 1];
        String profileName=[Select Id,Name from Profile where Id=:UserInfo.getProfileId()].Name;
        
        if(profileName == 'Sales Manager' ||profileName == 'Sales Admin'){
            LeadShare  shareLead = new LeadShare();
            shareLead.LeadId = lead.Id;
            shareLead.UserOrGroupId = user.ManagerId;
            shareLead.LeadAccessLevel = 'edit';
            shareLead.RowCause = Schema.LeadShare.RowCause.Manual;
            insert shareLead;
        }
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(lead.Id);
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Email_Exceptional_Approvals_Lead2');
        req1.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req1);
        
        if(user.ManagerId == null){
            return 'MANGER_NOT_FOUND';
        }else if(!user.IsActive){
            return 'MANGER_NOT_ACTIVE';
        }else if(result.isSuccess()){
            return 'SUCCESS';
        }else{
            return 'APPROVALS_ERROR';
        }
    }
    
    @AuraEnabled
    public static void updateExistingAccountOnLead(String leadRecordId, String selectedAccountId){
        Lead updateLead = new Lead(Id = leadRecordId, ExistingAccount__c = selectedAccountId, VerifiedBy__c = UserInfo.getUserId(), VerifiedDateTime__c = System.now());
        update updateLead;
    }
}