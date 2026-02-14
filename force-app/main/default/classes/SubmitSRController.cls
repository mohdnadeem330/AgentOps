/*
* Purpose: Submit the Service Request; it will also check to see if any required documents are pending, 
*               if any validation errors are thrown, and whether the SR has previously been Submitted or not.
*/
public with sharing class SubmitSRController {

    @AuraEnabled
    public static Map<String, Object> submitServiceRequest(String srId){
        Map<String, Object> returnMap = new Map<String, Object>();

        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{srId})[0];
        returnMap.put('objMap', serviceRequest);
        
        returnMap.put('success', false);
        returnMap.put('error', false);
        returnMap.put('isStatusChange', false);
        returnMap.put('status', serviceRequest.HexaBPM__External_Status_Name__c);
        try {
            if (serviceRequest.HexaBPM__Required_Docs_not_Uploaded__c) {
                returnMap.put('error', true);
            } else if (serviceRequest.HexaBPM__External_Status_Name__c == Constants.SUBMITTED) {
                returnMap.put('error', true);
            } else {
                HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SUBMITTED LIMIT 1];
                serviceRequest.HexaBPM__External_SR_Status__c = objSRStatus.Id;
                serviceRequest.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
                serviceRequest.HexaBPM__Submitted_DateTime__c = datetime.now();
                serviceRequest.HexaBPM__Submitted_Date__c = date.today();
                system.debug('serviceRequest>>>' + serviceRequest);
                update serviceRequest;

                HexaBPM__Service_Request__c updatedSR = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{srId})[0];
                returnMap.put('isStatusChange', true);
                returnMap.put('success', true);
                returnMap.put('status', updatedSR.HexaBPM__External_Status_Name__c);
                returnMap.put('objMap', updatedSR);
                
                System.debug('#$#$ on SUBMIT');
                if (ServiceRequestTriggerHelper.isCancellationSRNonClosed(serviceRequest)) {
                    System.debug('#$#$ on doCancellationCall');
                    ServiceRequestTriggerHandlerNew.doCancellationCall(true, new List<Id>{serviceRequest.Id});
                }
            }
        } catch (Exception ex) {
            /*
            * If a validation rule is violated, throw error and retrieve the actual error message.
            */
            returnMap.put('error', true);returnMap.put('message', ex.getMessage());
            if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {returnMap.put('actualMessage', ex.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION,', ': []'));
            } else {returnMap.put('actualMessage', ex.getMessage());}returnMap.put('errorMessage', ex);system.debug('returnMap>>>' + returnMap);}        return returnMap;
    }
}