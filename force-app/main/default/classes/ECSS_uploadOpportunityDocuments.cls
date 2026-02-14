global without sharing  class ECSS_uploadOpportunityDocuments {
    
    global list<DocumentsObj> caseDocumentsList {get;set;}
    global class DocumentsObj {
        global String Id {get;set;}
        global String Name {get;set;}
        global Date dateCreated {get;set;}
        global Date ExpiryDate {get;set;}
        global String ContentDownloadUrl {get;set;}
        global String PropertyName {get;set;}
        global String Contract {get;set;}
    }
     public class ValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public Datetime expiryTime;
    }
    

    @AuraEnabled(cacheable=false)
    public static ValidationResult checkAndMarkUsed(Id recordId, String Encrypted) {
       ValidationResult result = new ValidationResult();
        result.isValid = false;
        result.expiryTime = null;
        
        Opportunity opp = [
            SELECT Id,
            ECSS_Link_Expired__c
            FROM Opportunity
            WHERE Id = :recordId
            LIMIT 1
        ];
        system.debug ('OPPP:'+opp);

        if (opp != null) {
            
            // still valid if not expired
          
            if (!opp.ECSS_Link_Expired__c || Encrypted != 'yes') {
                result.isValid = true;
            }
           /* if(!opp.ECSS_Link_Used__c)
            {
                opp.ECSS_Link_Used__c =true;
                update opp;
            }*/
            
            //result.expiryTime = System.now().addHours(Integer.valueOf(System.Label.ECSS_Link_Expiry_Hours));
        }
        return result;
    }
   /* @AuraEnabled
    public static void markExpired(Id recordId) {
        if (recordId == null) return;

       Opportunity opp = [
            SELECT Id, ECSS_Link_Expired__c
            FROM Opportunity
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (!opp.ECSS_Link_Expired__c) {
            opp.ECSS_Link_Expired__c = true;
            update opp;
        }
    }*/

    
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getRelatedVersionOpportunityDocuments( String oppID, String QueryStringinp){
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        System.debug(QueryStringinp);
        system.debug('Opp'+oppID);
        List<Document__c > OppDocs =  Database.query(QueryStringinp);
        
        
        if (oppDocs.isEmpty()) return result;
        
        Set<Id> docIdSet = new Set<Id>();
        for (Document__c doc : OppDocs) {
            docIdSet.add(doc.Id);
        }
        
        // Query all sContentDocumentLinks for these Document__c records
        List<ContentDocumentLink> files = [SELECT ContentDocumentId, LinkedEntityId, 
                                           ContentDocument.Title, ContentDocument.CreatedDate,ContentDocument.LatestPublishedVersion.Id 
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId IN :docIdSet 
                                           ORDER BY ContentDocument.CreatedDate];
        
        // Create a map of Document__c ID to list of files
        Map<Id, List<Map<String, String>>> docFilesMap = new Map<Id, List<Map<String, String>>>();
        for (ContentDocumentLink link : files) {
            if (!docFilesMap.containsKey(link.LinkedEntityId)) {
                docFilesMap.put(link.LinkedEntityId, new List<Map<String, String>>());
            }
            docFilesMap.get(link.LinkedEntityId).add(new Map<String, String>{
                    'Title' => link.ContentDocument.Title,
                    'Version'=> link.ContentDocument.LatestPublishedVersion.Id,
                    'contentdocID' => link.ContentDocumentId
                    });
        }
        
        // Build the final result structure
        Boolean expiredStatus = false;
        for (Document__c doc : oppDocs) {
            List<Map<String, String>> filesList = docFilesMap.containsKey(doc.Id) 
                ? docFilesMap.get(doc.Id) 
                : new List<Map<String, String>>();
			if(doc.Status__c == 'Expired')
               expiredStatus = true;
            else
               expiredStatus = false;
            
            result.add(new Map<String, Object>{
                'Id' => doc.Id,
                    'Status' => doc.Status__c,
                    'SubType' => doc.ECSS_SubType__c,
                    'Type' => doc.DocumentType__c,
                    'PreviewUrl' => doc.ECSS_PublicLink__c,
                    'Files' => filesList,
                    'Mandatory' => doc.ECSS_Required__c,
                    'ExpiryRequired' => doc.ECSS_Expiry_Date_Required__c,
                    'ExpiryDate'=>doc.ECSS_Expiry_Date__c,
                    'Expired'=> expiredStatus
                    });
        }
        system.debug('RES'+result);
        return result;
        
    }
    
    @AuraEnabled
    public static String updateStatus(String documentId,Date expiryDate, String Encrypted) {
        String previewUrl = '';
        Set<Id> docIdSet = new Set<Id>();
        system.debug('EXP'+expiryDate);
        try{
         //   if(!test.isRunningTest())
         //   {   
                
                List<ContentDocumentlink> docLinkList = [SELECT id,ContentDocumentId,ContentDocument.CreatedDate  from ContentDocumentlink where LinkedEntityId =: documentId  order by ContentDocument.CreatedDate desc offset 1]; 
                for (ContentDocumentlink cdl : docLinkList) {
                    docIdSet.add(cdl.ContentDocumentId);
                }
                List<ContentDocument> docList = [SELECT id from ContentDocument where id in :docIdSet];
                
                // Combine into one delete list
                List<SObject> recordsToDelete = new List<SObject>();
                recordsToDelete.addAll(docLinkList);
                recordsToDelete.addAll(docList);
                delete recordsToDelete; 
                
                ContentDocumentLink linkRecord = [SELECT id,ContentDocumentId from ContentDocumentLink where LinkedEntityId = :documentId limit 1];
                ContentVersion version = [SELECT Id,Title,VersionData,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =:linkRecord.ContentDocumentId];
                
                  Attachment attachment = new Attachment();
//Blob xmlBlob = blob.valueOf(base64Data);
attachment.Body = version.VersionData;
attachment.Name = version.Title;
attachment.ParentId = documentId;
attachment.ContentType = 'application/xml';
insert attachment;  


                
                // Create a public link
               ContentDistribution cd = new ContentDistribution();
                cd.Name = version.Title;
                cd.ContentVersionId = version.Id;
                cd.PreferencesAllowViewInBrowser = true;
                cd.PreferencesAllowOriginalDownload = true;
                cd.PreferencesLinkLatestVersion = true;
               	insert cd;
             //   if(!test.isRunningTest())
             //   { 
                    Document__c  updatedDoc = [SELECT Id, Status__c, AttachmentID__c,ECSS_PublicLink__c,Opportunity__r.ECSS_RecordType_DevName__c FROM Document__c  WHERE Id =:documentId];
                    //ContentDistribution cdQuery = [SELECT Id,DistributionPublicUrl from ContentDistribution WHERE Id =: cd.Id];
                if (Encrypted == 'yes' || updatedDoc.Opportunity__r.ECSS_RecordType_DevName__c=='ECSS_Leasing' || updatedDoc.Opportunity__r.ECSS_RecordType_DevName__c=='ECSS_Parent')
                    updatedDoc.Status__c = 'Submitted';
                else
                    updatedDoc.Status__c = 'Verified';
                if(expiryDate!=null)
                    updatedDoc.ECSS_Expiry_Date__c = expiryDate;
                    //updatedDoc.ECSS_PublicLink__c = cdQuery.DistributionPublicUrl;
                    //updatedDoc.ECSS_PublicLink__c='/sfc/servlet.shepherd/document/download/'+linkRecord.ContentDocumentId;
                    updatedDoc.ECSS_PublicLink__c = '/lightning/r/ContentDocument/'+linkRecord.ContentDocumentId+'/view';
                    System.debug('PublicLink:'+updatedDoc.ECSS_PublicLink__c);
                    updatedDoc.AttachmentID__c = attachment.Id;
                    updatedDoc.MimeType__c=attachment.ContentType;

                   // System.debug('CD Update:'+cdQuery.DistributionPublicUrl);
                    previewUrl = updatedDoc.ECSS_PublicLink__c;
                    update updatedDoc;
           //     }      
        //    }
            
        }
        catch(exception ex){
            System.debug('exception'+ ex);
            previewUrl= ex.getMessage();
        }
        return previewUrl;
    }
    
    
    @AuraEnabled
    public static String getOpportunityDocuments( String oppID, String QueryStringinp){
        //List<Document__c > OppDocs = [SELECT ECSS_SubType__c, Status__c, DocumentType__c FROM Document__c  WHERE Opportunity__c =: oppID AND (Status__c = 'pending' OR Status__c ='Invalid Document')];
        //  System.debug('NG: Casedocs:' + OppDocs);
        List<Document__c > OppDocs =  Database.query(QueryStringinp);
        return json.serialize(OppDocs);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Id> getRelatedFilesByRecordId(String recordId) {
        // Get record file IDs        
        List<ContentDocumentLink> files = [SELECT ContentDocumentId, ContentDocument.CreatedDate FROM ContentDocumentLink WHERE LinkedEntityId = :recordId order by ContentDocument.CreatedDate DESC LIMIT 1];
        List<ID> fileIDs = new List<ID>();
        for (ContentDocumentLink docLink : files) {
            fileIDs.add(docLink.ContentDocumentId);
        }
        
        return fileIDs;
    }
    
    
    @AuraEnabled
    public static Boolean insertOpportunityDocuments(List<Object> filesToInsert, String docId ){
        system.debug('NG: docId ' + docId + ' filesToInsert--> ' + filesToInsert);
        // system.ddebug(' >>> Content: ' + EncodingUtil.base64Decode((String)filesToInsert[0].get('versionData')));
        List<Id> lstCntVerIds = new list<Id>();
        List<ContentVersion> lstVersionsToInsert = new List<ContentVersion>();
        for (Object file : filesToInsert) {
            Map<String, Object> fileDataa = (Map<String, Object>)file;
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion objCntVersion = new ContentVersion();
            objCntVersion.PathOnClient = fileData.Title;
            objCntVersion.Title = fileData.Title;
            objCntVersion.Description = fileData.Title;
            objCntVersion.IsMajorVersion = False;
            objCntVersion.VersionData = EncodingUtil.base64Decode((String)fileDataa.get('versionData'));//fileData.VersionData;
            // objCntVersion.parentId =
            lstVersionsToInsert.add(objCntVersion);
        }
        system.debug('lstVersionsToInsert ' + lstVersionsToInsert);
        list<Database.saveResult> res = new list<Database.saveResult>();
        If(lstVersionsToInsert.size()>0){
            res = Database.insert(lstVersionsToInsert);
        }
        for (Database.SaveResult saveResult : res) {
            If(saveResult.isSuccess()) {
                lstCntVerIds.add(saveResult.getId());
            }
        }
        system.debug('lstCntVerIds ' + lstCntVerIds);
        //get the ContentDocumentId
        list<ContentVersion> conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:lstCntVerIds];
        If(lstCntVerIds.size()>0){
            list<ContentDocumentLink> cdllst = new list<ContentDocumentLink>();
            for (ContentVersion cv : conDocId) {
                //Insert ContentDocumentLink
                System.debug('Content Documnet Link');
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = cv.ContentDocumentId;	//Add ContentDocumentId
                cdl.LinkedEntityId = docId;					//salesforce record Id
                cdl.ShareType = 'V';				//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cdl.Visibility = 'AllUsers';		//AllUsers, InternalUsers, SharedUsers
                cdllst.add(cdl);
            }
            If(cdllst.size()>0){
                system.debug('cdllst '+ cdllst);
                insert cdllst;
            }
        }
        List<ContentDistribution> cdlsToInsert = new List<ContentDistribution >();
        for (Id cntVerId : lstCntVerIds) {
            ContentDistribution cdl = new ContentDistribution();
            cdl.ContentVersionId = cntVerId;
            cdl.Name = 'Uploaded File';
            cdl.PreferencesAllowOriginalDownload = true;
            cdl.PreferencesAllowViewInBrowser = true;
            cdl.PreferencesLinkLatestVersion = true;
            cdl.PreferencesNotifyOnVisit = false;
            cdl.PreferencesPasswordRequired = false;
            cdlsToInsert.add(cdl);
        }
        List<ID> lstCntDistIds = new List<ID>();
        Database.saveResult[] srFiles = Database.insert(cdlsToInsert);
        for (Database.SaveResult saveResult : srFiles) {
            if(saveResult.isSuccess()) {
                lstCntDistIds.add(saveResult.getId());
            }
        }
        return true;
    }
    @AuraEnabled
    public static boolean saveFile(String parentId, String fileName, String base64Data) {
        system.debug('ParentID: '+parentId);
        boolean saveResult = false;
        try{
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            //NG: Insert Attachment
            Attachment attachment = new Attachment();
            //Blob xmlBlob = blob.valueOf(base64Data);
            attachment.Body = EncodingUtil.base64Decode(base64Data);
            attachment.Name = fileName;
            attachment.ParentId = parentId;
            attachment.ContentType = 'application/xml';

            Insert attachment;
            system.debug('attachment ID: '+attachment.Id);


            //Insert ContentVersion
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            contentVersion.PathOnClient = attachment.Name;//File name with extention
            contentVersion.Origin = 'C';//C-Content Origin. H-Chatter Origin.
            //contentVersion.OwnerId = UserInfo.getUserId();//Owner of the file
            contentVersion.Title = attachment.Name;//Name of the file
            contentVersion.VersionData = attachment.Body;//File content
            Insert contentVersion;
            //After saved the Content Verison, get the ContentDocumentId
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id].ContentDocumentId;
            system.debug('document ID: '+contentDocumentId);
            //Insert ContentDocumentLink
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentDocumentId;//Add ContentDocumentId
            contentDocumentLink.LinkedEntityId = parentId;//Add attachment parentId
            contentDocumentLink.ShareType = 'V';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            contentDocumentLink.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
            Insert contentDocumentLink;
            system.debug('document Link: '+contentDocumentLink.Id);
            
           // if(!test.isRunningTest())
           // {
                Document__c  updatedDoc = [SELECT Id, Status__c, AttachmentID__c FROM Document__c  WHERE Id =: parentId];
             updatedDoc.Status__c = 'Submitted';
             updatedDoc.AttachmentID__c = attachment.Id;
             update updatedDoc;
           // }
            saveResult = true;
        }
        catch(exception ex){
            System.debug('exception'+ ex);
        }
        return saveResult;
    }
    public class FileInfo {
        public String Title;
        public Blob VersionData;
    }
    public ECSS_uploadOpportunityDocuments() {
    }
}