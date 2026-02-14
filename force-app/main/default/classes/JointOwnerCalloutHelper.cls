public class JointOwnerCalloutHelper {
    public static Map<String, String> PrepareDataForCallout(List<Id> joIds, Boolean isCalledFromQueueable, Map<String, String> customerMap){
        List<JointOwner__c> joList = JointOwnerService.queryAllFieldsWithExtraFields(joIds);
        
        Map<String, Object> finalMap = new Map<String, Object>();
        List<Object> jodList = new List<Object>();
        List<JointOwner__c> deleteJOList = new List<JointOwner__c>();

        List<Id> accIds = new List<Id>();
        List<Id> jointOwnerIds = new List<Id>();
        for (JointOwner__c jo: joList) {
            if (String.isBlank(jo.Account__r.ERPID__c) && !jo.IsDeleted__c && String.isNotBlank(jo.SalesOrder__r.ERPID__c)) {
                accIds.Add(jo.Account__c);
                jointOwnerIds.add(jo.Id);
            }
        }

        if (!accIds.isEmpty() && System.isFuture() == false && !isCalledFromQueueable) {
            CustomerCalloutHelper.PrepareDataForCallout(accIds, jointOwnerIds, 'JointOwner__c');
        }

        List<Id> recordIds = new List<Id>();
        for (JointOwner__c jo: joList) {
            if (String.isBlank(jo.Account__r.ERPID__c) && !jo.IsDeleted__c && !customerMap.containsKey(jo.Account__c)) {
                continue;
            } else if (String.isBlank(jo.SalesOrder__r.ERPID__c) && !jo.IsDeleted__c) {
                continue;
            }
            Map<String, Object> jodMap = new Map<String, Object>();

            String recordMode;
            //added jo.DeleteJointOwner__c by dharanesh
            if (jo.IsDeleted__c || jo.DeleteJointOwner__c) {
                if (String.isNotBlank(jo.ERPID__c)) {
                    recordMode = Constants.MULESOFT_DELETE_MODE;
                } else {
                    deleteJOList.add(jo);
                    continue;
                }
            } else if (String.isBlank(jo.ERPID__c)) {
                recordMode = Constants.MULESOFT_CREATE_MODE;
            } else {
                recordMode = Constants.MULESOFT_UPDATE_MODE;
            }
            recordIds.add(jo.Id);
            
            jodMap.put('mode', recordMode);
            jodMap.put('createdByUser', String.isBlank(jo.ERPID__c) ? jo.CreatedBy.Email : jo.Owner.Email);
            jodMap.put('sfId', jo.Id);
            jodMap.put('jointOwnerId', jo.ERPID__c);
            jodMap.put('custAccountId', '');
            jodMap.put('partyId', jo.Account__r.ERPID__c != null ? jo.Account__r.ERPID__c : customerMap.get(jo.Account__c));
            jodMap.put('salesOrderId', jo.SalesOrder__r.ERPID__c);
            jodMap.put('sharePercentage', String.valueOf(jo.SharePercentage__c));
            jodMap.put('relationshipCode', jo.RelationshipType__c);

            jodList.add(jodMap);
        }
        finalMap.put('jointOwnerDetails', jodList);

        String requestBody = JSON.serialize(finalMap);
        requestBody = requestBody.replaceAll(':null', ':""');
        System.debug('requestBody>>> ' + requestBody);
        
        if (!jodList.isEmpty() && joList.size() != deleteJOList.size() && System.isFuture() == false && !isCalledFromQueueable) {
            if (System.IsBatch() == true) { 
                CalloutToMuleSoft.calloutService(requestBody, true, Constants.JOINTOWNER_INTEGRATION, recordIds);
            } else {
                CalloutToMuleSoft.calloutFutureService(requestBody, true, Constants.JOINTOWNER_INTEGRATION, recordIds);
            }
        }
        if (!deleteJOList.isEmpty()) {
            delete deleteJOList;
        }

        Map<String, String> returnMap = new Map<String, String>();
        if (isCalledFromQueueable) {
            returnMap.put('processName', Constants.JOINTOWNER_INTEGRATION);
            returnMap.put('requestBody', requestBody);
            return returnMap;
        } else {
            return returnMap;
        }
    }
}