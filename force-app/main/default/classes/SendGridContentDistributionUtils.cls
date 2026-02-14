/**********************************************************************************************************************
* Name               : SendGridContentDistributionUtils                                                        
* Description        : Utilities Class for the PDF Content Distribution
* Created By         : Harsh@Aldar                                                    
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           hrohilla@aldar.com     15/09/2023      Initial Draft   
* 1.1           hrohilla@aldar.com     14/03/2024      Added SR Document Public URL Generator      
******************************************************************************************************************/
public with sharing class SendGridContentDistributionUtils {
    /**
     * Create, Attach and Distribute the PDF BLOB provided, with the required parameters
     */
    public static String getPublicDistributionURLForPDF(Blob pdfBlob, String filetitle, String filePathOnClient, String contentLoc, String shareType, String documentId){
        String distributionPublicUrl;
        try {
            // Save PDF to Files
            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = contentLoc;
            cv.PathOnClient = filePathOnClient;
            cv.Title = filetitle;
            cv.VersionData = pdfBlob;
            insert cv;

            // Create a ContentDocument Link Record
            // First get the content document Id from ContentVersion
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id LIMIT 1].ContentDocumentId;

            //Create ContentDocumentLink
            ContentDocumentLink linkToRecord = new ContentDocumentLink();
            linkToRecord.ContentDocumentId = contentDocumentId;
            linkToRecord.LinkedEntityId = documentId; // RecordID of the patent
            linkToRecord.ShareType = shareType; // Inferred permission
            insert linkToRecord;

            ContentDistribution cd = new ContentDistribution();
            cd.Name = cv.Title;
            cd.ContentVersionId = cv.Id;
            insert cd;

            // Query ContentDistribution to get DistributionPublicUrl
            List<ContentDistribution> contentDistributions = [SELECT Id, DistributionPublicUrl
                                                                FROM ContentDistribution
                                                                WHERE ContentVersionId = :cv.Id
                                                                LIMIT 1];

            
            if (!contentDistributions.isEmpty()) {
                distributionPublicUrl = contentDistributions[0].DistributionPublicUrl;
                System.debug('#### DistributionPublicUrl: ' + distributionPublicUrl);
                
                // Now you can use distributionPublicUrl as needed.
            } else {
                System.debug('#### DistributionPublicUrl not found.');
            }
        } catch (Exception e) {
            //LOG
            System.debug('#### COULDNT CREATE PUBLIC DISTRIBUTION URL '+e.getMessage());
        }
        
        return distributionPublicUrl;
    }

    // Method to get the public URL for a specific SR and unit name
    public static String getSRDocPublicURL(Id srRecordId, String unitName, String srDocName) {
        try {
            // Retrieve the most recent SR Doc record related to the specified Service Request
            List<HexaBPM__SR_Doc__c> srDocRecordList = [SELECT Id 
                                                        FROM HexaBPM__SR_Doc__c 
                                                        WHERE HexaBPM__Service_Request__c = :srRecordId 
                                                        AND Name =: srDocName
                                                        ORDER BY CreatedDate DESC 
                                                        LIMIT 1];

            if (!srDocRecordList.isEmpty()) {
                HexaBPM__SR_Doc__c srDocRecord = srDocRecordList[0];
                List<ContentDocumentLink> contentDocLinkList;

                // Retrieve ContentDocumentLinks associated with the SR Doc record and containing the unit name
                if(srDocName.toLowerCase() == 'erp soa'){
                    contentDocLinkList = [SELECT ContentDocumentId, LinkedEntityId, ShareType 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId = :srDocRecord.Id 
                                            AND LinkedEntity.Type = 'HexaBPM__SR_Doc__c'
                                            AND ContentDocument.Title LIKE : '%' + unitName + '%'
                                            ORDER BY SystemModStamp DESC
                                            LIMIT 1];
                }else if(srDocName.toLowerCase() == 'customer snagging' 
                        || srDocName.toLowerCase() == 'customer desnagging'
                        || srDocName.toLowerCase() == 'home orientation letter'){
                    contentDocLinkList = [SELECT ContentDocumentId, LinkedEntityId, ShareType 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId = :srDocRecord.Id 
                                            AND LinkedEntity.Type = 'HexaBPM__SR_Doc__c'
                                            ORDER BY SystemModStamp DESC
                                            LIMIT 1];
                }else{
                    return null;
                }
                

                if (!contentDocLinkList.isEmpty()) {
                    // If a matching ContentDocumentLink is found, retrieve and return the public distribution URL
                    return getPublicDistributionURLForContentDocumentId(contentDocLinkList[0].ContentDocumentId, 'I', srRecordId, srDocName);
                }else {
                    logError('SendGrid: Get '+srDocName+' Public URL', 'SendGridContentDistributionUtils', 'getPublicDistributionURLForContentDocumentId', srRecordId, 'No SR Doc Found Naming '+srDocName+' Found', srDocName);
                }
            }else {
                logError('SendGrid: Get '+srDocName+' Public URL', 'SendGridContentDistributionUtils', 'getPublicDistributionURLForContentDocumentId', srRecordId, 'No SR Doc Found Naming '+srDocName+' Found', srDocName);
            }
        } catch (Exception e) {
            // Log any exceptions that occur during execution
            insert LoggerService.addApexLog(e, 'SendGrid: Get '+srDocName+' Public URL', 'SendGridContentDistributionUtils', 'getPublicDistributionURLForContentDocumentId');
        }

        // Return an empty string if no valid URL is found
        return null;
    }

    // Method to get the public distribution URL for a ContentDocumentId and share type
    private static String getPublicDistributionURLForContentDocumentId(String contentDocumentId, String shareType, Id srRecordId, String srDocName) {
        String distributionPublicUrl = '';

        try {
            if (contentDocumentId != null) {
                // Query ContentVersion to get the ContentDistributionId
                List<ContentVersion> contentVersions = [SELECT Id 
                                                        FROM ContentVersion 
                                                        WHERE ContentDocumentId = :contentDocumentId 
                                                        AND IsLatest = true 
                                                        AND IsDeleted = false 
                                                        LIMIT 1];

                if (!contentVersions.isEmpty()) {
                    ContentVersion contentVersion = contentVersions[0];

                    ContentDistribution cd = new ContentDistribution();
                    cd.ContentVersionId = contentVersion.Id;
                    cd.Name = srDocName;
                    cd.PreferencesAllowViewInBrowser = true;
                    cd.PreferencesLinkLatestVersion = true;
                     
                    insert cd;

                    // Query ContentDistribution to get DistributionPublicUrl
                    List<ContentDistribution> contentDistributions = [SELECT Id, DistributionPublicUrl
                                                                        FROM ContentDistribution
                                                                        WHERE ContentVersionId = :contentVersion.Id
                                                                        LIMIT 1];
                    System.debug('####cd: '+contentDistributions);
                    // Store the public distribution URL and log it
                    distributionPublicUrl = contentDistributions[0].DistributionPublicUrl;
                    
                } else {
                    logError('SendGrid: Get '+srDocName+' Public URL', 'SendGridContentDistributionUtils', 'getPublicDistributionURLForContentDocumentId', srRecordId, 'No ContentVersion found for the specified ContentDocumentId.', srDocName);
                }
            } else {
                logError('SendGrid: Get '+srDocName+' Public URL', 'SendGridContentDistributionUtils', 'getPublicDistributionURLForContentDocumentId', srRecordId, 'No ContentDocumentLink found for the specified Id.', srDocName);
            }
        } catch (Exception e) {
            // Log any exceptions that occur during execution
            insert LoggerService.addApexLog(e, 'SendGrid: Get '+srDocName+' Public URL', 'SendGridContentDistributionUtils', 'getPublicDistributionURLForContentDocumentId');
        }

        return distributionPublicUrl;
    }

    // Helper method to log error messages along with exception details
    private static void logError(String processName, String className, String methodName, Id recordId, String message, String srDocName) {
        Logger__c thisLog = LoggerService.addApexServiceCalls(processName, className, methodName, message, null, recordId);
        thisLog.ExceptionTypeName__c = 'SendGrid: Get '+srDocName+' for Handover';
        thisLog.LogType__c = 'Exception';
        insert thisLog;
    }
    
}