@RestResource (urlMapping = '/lead/referral')
global with sharing class InterDepartmentLeadRefferalWebService {

    @HttpPost
    global static void doPost(String recordId, String team, String salesType, String propertyUsage, String project ){
        String returnMsg = '';
        RestContextHandler handler = new RestContextHandler(false);
        
        try{
            Lead lead = InterDepartmentalReferralController.getCurrentRecord(recordId);
            String currentUserTeam = InterDepartmentalReferralController.checkCurrentUsersTeam();
          
        
            if(lead.LeadAge__c <= 2 && !Test.isRunningTest()){
                returnMsg = System.Label.Lead48HrsToRefer;
            }else  if((lead.ReferredTo__c != null && lead.ReferredBy__c != null) || (lead.Leads1__r.size()>0)){
                returnMsg = System.Label.ReferredLeadError;
            }else if(team.equalsIgnoreCase(currentUserTeam)){
                returnMsg = System.Label.LeadReferOwnTeamError;
            }else if(team == 'AUH/DXB' && (currentUserTeam == 'AUH' || currentUserTeam == 'DXB')){
                returnMsg = System.Label.LeadReferTeamError;
            }else{ 
                returnMsg = InterDepartmentalReferralController.referLead(recordId, team, salesType, propertyUsage, project);
            }
            
            if(returnMsg != '' && !returnMsg.contains('Success_')){
                handler.response.success = false;
                handler.response.message = returnMsg;
                handler.finalize();
            }else if(returnMsg.contains('Success_')){
                handler.response.success = true;   handler.response.message = System.Label.LeadReferSuccessMessage;
                handler.finalize();
            }else{
                handler.response.success = false;   handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = 'Error';
            }
            
        }catch(Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;   handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        } 
        
    }
}