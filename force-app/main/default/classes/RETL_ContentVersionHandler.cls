public class RETL_ContentVersionHandler {
    public static void afterInsert(List<ContentVersion> newVersions) {
        if (newVersions == null || newVersions.isEmpty()) return;
        
        try {
            
            // Map ContentVersion Document__c
            Map<Id, Id> contentVersionToDocMap = new Map<Id, Id>();
            Map<Id, Id> contentVersionToContentNoteMap = new Map<Id, Id>();
            
            Set<Id> docIds = new Set<Id>();
            
            for (ContentVersion cv : newVersions) {
                if (cv.FirstPublishLocationId != null) {
                    contentVersionToDocMap.put(cv.Id, cv.FirstPublishLocationId);
                    docIds.add(cv.FirstPublishLocationId); 
                }
                if (cv.RETL_ContentNoteId__c != null) {
                    contentVersionToContentNoteMap.put(cv.Id, cv.RETL_ContentNoteId__c);
                }
            } 
            
				// Query only allowed record types
             Map<Id, Document__c> docRecordMap = new Map<Id, Document__c>(
                [
                    SELECT Id, RecordType.DeveloperName
                    FROM Document__c
                    WHERE Id IN :docIds
                    AND RecordType.DeveloperName IN ('RDD_Document', 'RETL_Lease_Document')
                ]
            );
            
            List<ContentDistribution> distsToInsert = new List<ContentDistribution>();
            
            for (ContentVersion cv : newVersions) { 
                
                Document__c relatedDoc = docRecordMap.get(cv.FirstPublishLocationId);
                // If record type not allowed → skip
                if (relatedDoc == null) continue;
                System.debug('Skipping ContentVersion — Document Record Type not allowed.');
                
                System.debug('cv.RETL_Generate_External_URL__c=='+cv.RETL_Generate_External_URL__c);
                //if (cv.Id != null) {
                if (cv.RETL_Generate_External_URL__c == true) {
                    distsToInsert.add(new ContentDistribution(
                        Name = (cv.Title != null ? cv.Title : 'Untitled'),
                        ContentVersionId = cv.Id,
                        PreferencesAllowViewInBrowser = true,
                        PreferencesAllowPDFDownload = true,
                        PreferencesAllowOriginalDownload = true
                    ));
                }
            }
            
            if (!distsToInsert.isEmpty()) {
                insert distsToInsert;
                
                List<ContentDistribution> insertedDists = [
                    SELECT Id, Name, DistributionPublicUrl, ContentDownloadUrl, ContentVersionId
                    FROM ContentDistribution
                    WHERE Id IN :distsToInsert
                ];
                
                List<External_Files__c> externalFilesToInsert = new List<External_Files__c>();
                
                for (ContentDistribution dist : insertedDists) { 
                     
                    Document__c relatedDoc = docRecordMap.get(contentVersionToDocMap.get(dist.ContentVersionId));
                   // If record type not allowed → skip
                    if (relatedDoc == null) continue;
                    
                    if (String.isNotBlank(dist.DistributionPublicUrl)) {
                        
                        Id contentNoteId = contentVersionToContentNoteMap.get(dist.ContentVersionId);
                        
                        externalFilesToInsert.add(new External_Files__c(
                            File_Name__c = dist.Name,
                            External_URL__c = dist.ContentDownloadUrl,
                            Document__c = contentVersionToDocMap.get(dist.ContentVersionId),
                            RETL_Case_Comment_SF_ID__c = contentNoteId
                        ));
                    }
                }
                
                if (!externalFilesToInsert.isEmpty()) {
                    insert externalFilesToInsert;
                }
            }
            
        } catch (Exception ex) {
            System.debug('Error in RETL_ContentVersionHandler.afterInsert: ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
            
        }
    }
    /*
    public static void sendPushNotificationFromNotes(List<ContentVersion> cvList) {
        
        if (cvList == null || cvList.isEmpty()) return;
        
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentVersion cv : cvList) {
            if (cv.Id != null &&
                cv.FileType == 'SNOTE' &&
                cv.ContentDocumentId != null) 
            {
                contentDocIds.add(cv.ContentDocumentId);
            }
        }
        System.debug('contentDocIds------>'+contentDocIds);
        if (contentDocIds.isEmpty()) return;
        
        
        Map<Id, Id> contentDocToStageMap = new Map<Id, Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocIds
        ]) {
            System.debug('cdl.LinkedEntityId----->'+cdl.LinkedEntityId);
            if (cdl.LinkedEntityId != null && cdl.LinkedEntityId.getSObjectType() == RETL_Stage__c.SObjectType) {
                contentDocToStageMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }
            System.debug('contentDocToStageMap----->'+contentDocToStageMap);
        }
        
        if (contentDocToStageMap.isEmpty()) return;
        
        
        Map<Id, RETL_Stage__c> stageMap = new Map<Id, RETL_Stage__c>(
            [
                SELECT Id,
                RETL_Stage_Developer_Name__c,
                RETL_Service_RequestId__c,
                RETL_Service_RequestId__r.RETL_Tenant__c,
                RETL_Service_RequestId__r.RETL_Tenant__r.Email,
                RETL_Service_RequestId__r.RETL_Tenant__r.Account.Name
                FROM RETL_Stage__c
                WHERE Id IN :contentDocToStageMap.values()
            ]
        );
        
        if (stageMap.isEmpty()) return;
        
        
        Set<String> allowedStages = new Set<String>{
            'MEP_Design', 
                'Detailed_Architectural_Design', 
                'Conceptual_Design'
                };
                    
                    
                    List<Map<String, Object>> allFlowInputs = new List<Map<String, Object>>();
        
        for (ContentVersion cv : cvList) {
            
            if (cv == null || cv.FileType != 'SNOTE') continue;
            
            Id stageId = contentDocToStageMap.get(cv.ContentDocumentId);
            if (stageId == null) continue;
            
            RETL_Stage__c stage = stageMap.get(stageId);
            if (stage == null) continue;
            
            
            if (String.isBlank(stage.RETL_Stage_Developer_Name__c) ||
                !allowedStages.contains(stage.RETL_Stage_Developer_Name__c)) 
            {
                continue;
            }
            
            
            if (stage.RETL_Service_RequestId__r == null ||
                stage.RETL_Service_RequestId__r.RETL_Tenant__r == null) 
            {
                continue; 
            }
            
            String tenantEmail =
                stage.RETL_Service_RequestId__r
                .RETL_Tenant__r
                .Email;
            
            if (String.isBlank(tenantEmail)) continue;
            
            String tenantAccountName =
                stage.RETL_Service_RequestId__r
                .RETL_Tenant__r
                .Account != null
                ? stage.RETL_Service_RequestId__r.RETL_Tenant__r.Account.Name
                : null;
            
            String tenantUserName = String.isNotBlank(tenantAccountName)
                ? tenantAccountName
                : '';
            
            
            String notifBody  = System.Label.RETL_Push_Notification_Body_for_comment;
            String notifTitle = System.Label.RETL_Push_Notification_title_for_comment;
            
            if (String.isBlank(notifBody) || String.isBlank(notifTitle)) continue;
            
            allFlowInputs.add(new Map<String, Object>{
                'CaseRecordId'      => stage.Id,
                    'NotificationBody'  => notifBody,
                    'NotificationTitle' => notifTitle,
                    'UserEmail'         => tenantEmail,
                    'UserId'            => tenantEmail,
                    'UserName'          => tenantUserName
                    });
        }
        System.debug('allFlowInputs-->'+allFlowInputs);
        if (allFlowInputs.isEmpty()) return;
        
        
        for (Map<String, Object> inputs : allFlowInputs) {
            try {
                Flow.Interview.RETL_ServiceRequestCustomPushNotification flowCall =
                    new Flow.Interview.RETL_ServiceRequestCustomPushNotification(inputs);
                flowCall.start();
            } catch (Exception e) {
                System.debug('Push Notification Flow Failed: ' + e.getMessage());
            }
        }
    }*/
 
}