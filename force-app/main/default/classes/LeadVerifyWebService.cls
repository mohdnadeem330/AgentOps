//API class for verify Lead for Duplicate Accounts in iPad.
//
@RestResource (urlMapping = '/verify/lead')
global with sharing class LeadVerifyWebService {
    
    @HttpPost
    global static void doPost(String leadId) { 
        RestContextHandler handler = new RestContextHandler(false);
        DuplicateAccountResponseWrapper responseWrapper = new DuplicateAccountResponseWrapper();
        Lead lead = [SELECT Id,Email,SkipDuplicateApprovalStatus__c FROM Lead WHERE Id =: leadId Limit 1];
        String leadEmail = (lead.Email).toLowercase();
        try{
            Map<String,List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> DupeAccountMap = UtilitiesWithoutSharing.findDuplicateAccountsByEmail(new Set<String>{leadEmail});
            List<DuplicateAccountResponseWrapper.DuplicateAcc> duplicateList = new List<DuplicateAccountResponseWrapper.DuplicateAcc>();
            if(DupeAccountMap != null && DupeAccountMap.get(leadEmail) != null && DupeAccountMap.get(leadEmail).size() > 0){
                for(UtilitiesWithoutSharing.DuplicateAccountWrapper wrapper : DupeAccountMap.get(leadEmail)){
                    DuplicateAccountResponseWrapper.DuplicateAcc wr = new  DuplicateAccountResponseWrapper.DuplicateAcc();
                    wr.Name  = wrapper.Account.Name;
                    wr.AccountNumber  = wrapper.Account.AccountNumber__c;
                    wr.SalesOrderCount  = wrapper.salesOrderCount;
                    wr.CustomerType  = wrapper.Account.CustomerType__c;
                    wr.CustomerSubType  = wrapper.Account.CustomerSubType__c;
                    wr.PassportNumber = wrapper.Account.PassportNumber__pc;
                    wr.KYCValidity = wrapper.Account.KYC_Validity_Status__c;
                    wr.ResidentStatus = wrapper.Account.ResidentStatus__pc;
                    wr.EmiratesId  = wrapper.Account.NationalIdNumber__pc;
                    wr.AccountId = wrapper.Account.Id;
                    duplicateList.add(wr);
                }
                Boolean exceptionApprovalStatus = lead.SkipDuplicateApprovalStatus__c == 'Sent for Approval' || 
                    							  lead.SkipDuplicateApprovalStatus__c == 'Approved' ? true : false;
                                                          
                DuplicateAccountResponseWrapper.DupAcc duplicateAccountData = new  DuplicateAccountResponseWrapper.DupAcc(false,false,true,false,null,exceptionApprovalStatus,true,'');
                //duplicateAccountData.isEmailValid = false;
                //duplicateAccountData.isPhoneValid = false;
                //duplicateAccountData.hasDuplicates = true;
                duplicateAccountData.DuplicateAccounts = duplicateList;
                //duplicateAccountData.exceptionApprovalStatus = lead.SkipDuplicateApprovalStatus__c == 'Sent for Approval' || 
                    										   //lead.SkipDuplicateApprovalStatus__c == 'Approved' ? true : false;
                handler.response.data = duplicateAccountData;
                handler.response.success = true;
                handler.finalize();
            }else{
                handler.response.success = true;
                handler.response.message = 'No Duplicate Accounts Found';
                handler.finalize();
            }
            
        }catch (Exception exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }
}