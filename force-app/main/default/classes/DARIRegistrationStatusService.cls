@RestResource(urlMapping='/DARI/statusService/statusUpdate')
global class DARIRegistrationStatusService {
    
    @HttpPost
    global static String updateStatus(Integer applicationId, String status, String statusType) {
        system.debug('----------'+applicationId);
        system.debug('----------'+status);
        String returnStatus = '';
        
        if(statusType == 'Approval') {
            returnStatus = DARIRegistrationUtility.closeADMApproval(applicationId, status);
        } else if(statusType == 'Payment'){
            returnStatus = DARIRegistrationUtility.updatePaymentStatus(applicationId, status);
        }
		
        return returnStatus;
    }
}