public class ECSS_DocumentTriggerHelper {
    
    public static void DocumentPlatformEvent(List<SObject> newList , Map<Id, SObject> oldMap) {
        
        System.debug('DocumentPlatformEvent Entered');
        
        
        List<ECSS_Document_Event__e> events = new List<ECSS_Document_Event__e>();
        
        
        for (SObject obj : newList ){
            
            System.debug('The Document Loop Entered');
            
            Document__c Doc = (Document__c) obj;
            Document__c oldDoc = (Document__c)oldMap.get(Doc.Id);
            
            
            
            ContentVersion cv = [ SELECT Id,ContentDocumentId,FileExtension,ContentSize,Checksum FROM ContentVersion  WHERE FirstPublishLocationId = :Doc.Id  AND IsLatest = true LIMIT 1];
            
            System.debug('Doc.Id: ' + Doc.Id);
            System.debug('Doc.Status__c: ' + Doc.Status__c);
            System.debug('oldDoc: ' + oldDoc);
            System.debug('oldDoc.Status__c: ' + (oldDoc != null ? oldDoc.Status__c : 'null'));
            
            if (oldDoc != null && Doc.Status__c != oldDoc.Status__c &&  Doc.Status__c == 'Submitted') {
                
                System.debug('The Document IF Entered');
                
                
                ECSS_Document_Event__e  eventRecord = new ECSS_Document_Event__e(
                    ECSS_DocumentId__c = Doc.Id,
                    ECSS_AttachmentId__c  = Doc.AttachmentID__c,
                    ECSS_CorrelationId__c =Doc.Correlation_ID__c,
                    ECCS_DocumentName__c =Doc.Name,
                    ECSS_DownloadUrl__c = Doc.ECSS_AttachementURL__c,
                    ECSS_MimeType__c =Doc.MimeType__c,
                    ECSS_ContentVersionId__c =cv.Id,
                    ECSS_Checksum__c =cv.Checksum,
                    ECSS_ContentSize__c =cv.ContentSize,
                    ECSS_FileExtension__c =cv.FileExtension,
                    ECSS_ContentDocumentID__c =cv.ContentDocumentId,
                     ECSS_AssedId__c =Doc.ECSS_Unit__c
                );
                System.debug('event record:'+ eventRecord);
                events.add(eventRecord);
            }
        }
        
        
        if (!events.isEmpty()) {
            Database.SaveResult[] results = EventBus.publish(events);
            
            for (Database.SaveResult sr : results) {
                System.debug('EventBus.publish result => Success: ' + sr.isSuccess() + 
                             ', Event Id: ' + sr.getId() + 
                             ', Errors: ' + sr.getErrors());
            }
            
            
        }
        
    }
    
}