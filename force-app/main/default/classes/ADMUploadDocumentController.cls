public with sharing class ADMUploadDocumentController{
    
    //--- method used with upload document API to prepare the request and handle the response
    @AuraEnabled(cacheable=false)
    public static string uploadDocument(String srId){

        HexaBPM__Service_Request__c srRecord = [SELECT Id, ADMApplicationNumber__c, ApplicationId__c, recordTypeId, (select id,Name, SyncStatus__c, HexaBPM__Comments__c from HexaBPM__SR_Docs__r) FROM HexaBPM__Service_Request__c WHERE Id=: srId];
        String recordTypeName = Utilities.getRecordTypeName('HexaBPM__Service_Request__c', srRecord.recordTypeId);

        List<String> srDocumentsNames = recordTypeName == 'Title Deed Registration' ? new List<String>{'Mortgage Agreement'} : SRUtility.getDocumentsToBeUploadedToDARI(srRecord.Id);
        if(srDocumentsNames.size() > 0){
            if(recordTypeName == 'Title Deed Registration'){
                DARIRegistrationUtility.postUploadDocument(srRecord.Id, srRecord.ApplicationId__c, srDocumentsNames);
            } else{
                ADMRegistrationUtility.uploadDocument(srRecord.Id, srRecord.ADMApplicationNumber__c, srDocumentsNames);
            }
                
        } else {
            return Utilities.getSystemMessages(Constants.NO_DOCUMENTS_NEED_TO_REUPLOAD).Message__c;
        }

        return '';
    }

    @AuraEnabled(cacheable=false)
    public static string uploadDocumentCheck(String srId){
        HexaBPM__Service_Request__c srRecord2 = [SELECT Id, ADMApplicationNumber__c, ApplicationId__c, recordTypeId FROM HexaBPM__Service_Request__c WHERE Id=: srId];
        HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c();
        String recordTypeName = Utilities.getRecordTypeName('HexaBPM__Service_Request__c', srRecord2.recordTypeId);

        if(recordTypeName == 'Title Deed Registration') {
            srRecord = [SELECT Id, (select id,Name, SyncStatus__c, HexaBPM__Comments__c from HexaBPM__SR_Docs__r WHERE Name = 'Mortgage Agreement') FROM HexaBPM__Service_Request__c WHERE Id=: srId];
        } else {
            srRecord = [SELECT Id, (select id,Name, SyncStatus__c, HexaBPM__Comments__c from HexaBPM__SR_Docs__r) FROM HexaBPM__Service_Request__c WHERE Id=: srId];
        }

        List<HexaBPM__SR_Doc__c> documentsList = sRRecord.HexaBPM__SR_Docs__r;
        List<String> errorsMessages = new List<String>();

        for (HexaBPM__SR_Doc__c docRecord : documentsList) {
            if(docRecord.SyncStatus__c != Constants.STATUS_SYNCED){
                errorsMessages.add(docRecord.Name +': '+ docRecord.HexaBPM__Comments__c != null ? docRecord.HexaBPM__Comments__c : 'Not Uploaded');
            }
        }
        if(errorsMessages.size() > 0){
            return errorsMessages.toString().substring(1,errorsMessages.toString().length()-1);
        }
        return '';
    }
}