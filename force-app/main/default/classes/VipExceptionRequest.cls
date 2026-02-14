@RestResource (urlMapping = '/email/vipexception')
global with sharing class VipExceptionRequest {
    
    @HttpPost
    global static void doPost(String recordId, String brokerLeadNumber, String reasonValue, String otherReasonValue) { 
        RestContextHandler handler = new RestContextHandler(false);
        try{
            String leadId = recordId;
            if(leadId != null){
                String message = '';
                if(reasonValue =='Broker Reason Lead'){
                    List<Lead> lea = UtilitiesWithoutSharing.getleadbyLeadNumber(leadId);
                    if(lea[0].Approval_Status__c == 'Sent for Approval'){
                        message = 'APPROVALS_ERROR';
                    }else{
            	 		message = SearchBrokerLeads.sentforApproval(lea[0].Id,otherReasonValue,reasonValue);
                    }
                }else{
                if(reasonValue =='VIP Reason Lead'){
                    List<Lead> lea = UtilitiesWithoutSharing.getleadbyLeadNumber(leadId);
                    if(lea[0].VIPApproval__c == 'Sent for Approval'){
                        message = 'APPROVALS_ERROR';
                    }else{
            	 		message = SearchBrokerLeads.sentforApproval(lea[0].Id,otherReasonValue,reasonValue);
                    }
                }else{
                    Opportunity opp = [SELECT Id,Name,VIPApproval__c FROM Opportunity WHERE Id=:recordId];
                    
                    if(opp.VIPApproval__c =='Sent for Approval'){
                         message= 'APPROVALS_ERROR';
                    }else{
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setComments('Submitting request for approval.');
                    req1.setObjectId(LeadId);
                    
                    req1.setSubmitterId(UserInfo.getUserId()); 
                    
                    req1.setProcessDefinitionNameOrId('VIP_Approval');
                    req1.setSkipEntryCriteria(true);
                    
                    // Submit the approval request for the account
                    Approval.ProcessResult result = Approval.process(req1);
                    Approval.UnlockResult unlockResultList = Approval.unlock(opp, false);
                    if(result.isSuccess()){
                        message = 'SUCCESS';
                    }else{
                        message= 'APPROVALS_ERROR';
                    }
                    }
                }
                }
                if(message == 'SUCCESS'){
                    handler.response.success = true;
                    handler.response.message = 'Submitted for Approvals.' ;
                    handler.finalize();
                }else{
                    handler.response.success = false;
                    handler.response.message = 'Record is already submitted for Approvals or Error in Submitting Approvals';
                    handler.finalize();
                }
                
            }
            
        }catch(Exception ex)
        {            
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }
}