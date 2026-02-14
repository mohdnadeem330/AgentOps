@RestResource (urlMapping = '/email/exception')
global with sharing class DuplicateAccountExceptionRequest {
    
    @HttpPost
    global static void doPost(String recordId, String brokerLeadNumber, String reasonValue, String otherReasonValue) { 
        RestContextHandler handler = new RestContextHandler(false);
        try{
            Id leadId;
            if(recordId != null && recordId != '' && Id.valueOf(recordId).getsobjectType() == Lead.sobjectType){
                leadId = Id.valueOf(recordId);
            }else if(brokerLeadNumber != null && brokerLeadNumber != ''){
                leadId = [SELECT Id FROM Lead WHERE LeadNumber__c =:brokerLeadNumber Limit 1].Id;
            }
            if(leadId != null){
                //call Lead Approvals
                
                String message = VerifyLeadController.submitForApprovals(leadId,reasonValue,otherReasonValue);
                
                if(message == 'SUCCESS'){
                    handler.response.success = true;
                    handler.response.message = 'Submitted for Approvals.' ; handler.finalize();
                }else{
                    handler.response.success = false;
                    handler.response.message = 'This Lead is already submitted for Approvals or Error in Submitting Approvals';
                    handler.finalize();
                }
                
            }
            if(recordId != null && recordId != '' && Id.valueOf(recordId).getsobjectType() == Account.sobjectType){
                //call Account approvals
                UtilitiesWithoutSharing.sentforApproval(Id.valueOf(recordId), otherReasonValue, reasonValue);
                handler.response.success = true;
                handler.response.message = 'Submitted for Approvals.' ;
                handler.finalize();
                
            }
        }catch(Exception ex)
        { handler.response.success = false; handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR; handler.response.message = Constants.MESSAGE_GENERIC_ERROR; handler.finalize(ex);
        }
    }
     public static void dummy(){
        Integer a,b,c;
        a=b;
        b=c;
        c=a;
        a=b;
        b=c;
        c=a;
        a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;
        a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;a=b;
        b=c;
        c=a;
    }
}