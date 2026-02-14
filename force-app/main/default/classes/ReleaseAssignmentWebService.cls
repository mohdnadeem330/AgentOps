/**
 * ----------------------------------------------------------------------------
 * Class Name     : ReleaseAssignmentWebService
 * Created By     : SYED NOORMOHAMAD
 * Created Date   : 2025-05-08
 * Purpose        : This class handles custom logic for releasing the unit from Ipad, and send error if no unit Assignment records
 * ----------------------------------------------------------------------------
 */
@RestResource (urlMapping = '/releaseAssignments')
global without sharing class ReleaseAssignmentWebService{
    @HTTPPost
    global static void doPost(String userId, List<String> unitIds, String opportunityId){
        RestContextHandler handler = new RestContextHandler(true);
        try {
            List<Unit__c> unitInprogress = [SELECT Id, Name,AssignedToUser__c, (SELECT Id FROM Unit_Assignments__r where RequestedBy__c=:userId) FROM Unit__c WHERE Status__c IN ('Available', 'In-progress')
                                        AND Id IN :unitIds];
        
            Set<String> inProgressUnitNames = new Set<String>();
            
            for (Unit__c ua : unitInprogress) {
                if (ua.Unit_Assignments__r.isEmpty() && ua.AssignedToUser__c == UserInfo.getUserId()) {
                    inProgressUnitNames.add(ua.Name);
                }
                if(ua.AssignedToUser__c != userInfo.getUserId()) {
                    inProgressUnitNames.add(ua.Name);
                }
            }
            
            if (!inProgressUnitNames.isEmpty()) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_UNITS_NOT_AVAILABLE;
                handler.response.message = 'Selected units cannot be released: ' + String.join(inProgressUnitNames, ', ') + '. Please contact sales support.';
                handler.finalize();
                return;
            }

            OpportunityUnitSearchController.releaseUnits(unitIds,opportunityId,'IPAD');
            
            handler.response.success = true;
            handler.response.message = 'Units successfully released.';
            handler.finalize();
            

                      
        } catch (Exception ex) {
            System.debug('msg '+ex.getMessage());
            System.debug('line no '+ex.getLineNumber());
            handler.response.success    = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = Constants.MESSAGE_GENERIC_ERROR +'   '+ex.getMessage();
            handler.finalize(ex);
        }
        
    }
    
}