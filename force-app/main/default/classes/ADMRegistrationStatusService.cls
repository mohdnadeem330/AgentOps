@RestResource(urlMapping='/ADM/registration/statusUpdate')
global with sharing class ADMRegistrationStatusService {
    @HttpPost
    global static String updateStatus(String applicationId,String status) {
        //call ADMRegistrationUtility.closeADMApproval
        system.debug('----------'+applicationId);
        system.debug('----------'+status);

        return ADMRegistrationUtility.closeADMApproval(applicationId, status);
    }
}