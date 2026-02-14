//Hexa runs is system context
public without sharing class ContentDocumentLinkTriggerHandler extends TriggerHandler{
    
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        try{
        map<string,ContentDistribution> distributionsToInsert = new map<string,ContentDistribution>();
        map<id,Document__c> relatedDocMap = new map<id,Document__c>();
        map<Id,ContentVersion> contentDocumentMap =new map<id,ContentVersion>();
        set<ID> existingDistributionIds = new set<ID>();
        
        for (ContentDocumentLink CDL : (List<ContentDocumentLink>)newList) {
            if(CDL.LinkedEntityId.getSObjectType() == Document__c.getSObjectType()){
                relatedDocMap.put(CDL.LinkedEntityId,null);
                contentDocumentMap.put(CDL.ContentDocumentId,null);
            }
            if(CDL.LinkedEntityId.getSObjectType() == Case.getSObjectType() || CDL.LinkedEntityId.getSObjectType() == SalesOrderOtherCharges__c.getSObjectType() || CDL.LinkedEntityId.getSObjectType() == HexaBPM__SR_Doc__c.getSObjectType() ||  CDL.LinkedEntityId.getSObjectType() == BrokerRequest__c.getSObjectType() ){
                contentDocumentMap.put(CDL.ContentDocumentId,null);
            }
        }
        
        relatedDocMap =  new map<id,Document__c>([select id from Document__c where id in :relatedDocMap.keySet() and AvailableForExternalUsers__c=true]);
        for(ContentVersion contentversionRecord :[SELECT Id,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId in :contentDocumentMap.keySet() and isLatest=true]){
            contentDocumentMap.put(contentversionRecord.ContentDocumentId,contentversionRecord);
        }
        for (ContentDocumentLink CDL : (List<ContentDocumentLink>)newList) {
            //make it public
            if(relatedDocMap.containsKey(CDL.LinkedEntityId) || CDL.LinkedEntityId.getSObjectType() == HexaBPM__SR_Doc__c.getSObjectType() || CDL.LinkedEntityId.getSObjectType() == Case.getSObjectType() || CDL.LinkedEntityId.getSObjectType() == BrokerRequest__c.getSObjectType()){
                CDL.Visibility = 'AllUsers';
                CDL.ShareType='I';
            }
            //Create Distribution  
            if( CDL.LinkedEntityId.getSObjectType() == Case.getSObjectType() || CDL.LinkedEntityId.getSObjectType() == SalesOrderOtherCharges__c.getSObjectType() || CDL.LinkedEntityId.getSObjectType() == HexaBPM__SR_Doc__c.getSObjectType() || CDL.LinkedEntityId.getSObjectType() == BrokerRequest__c.getSObjectType() || relatedDocMap.containsKey(CDL.LinkedEntityId)){
                if(contentDocumentMap !=null && contentDocumentMap.containsKey(CDL.ContentDocumentId) && contentDocumentMap.get(CDL.ContentDocumentId) != null){
                    existingDistributionIds.add(contentDocumentMap.get(CDL.ContentDocumentId).Id);
                    existingDistributionIds.add(CDL.LinkedEntityId);
                    distributionsToInsert.put(contentDocumentMap.get(CDL.ContentDocumentId).Id+''+CDL.LinkedEntityId,createContentDistribution(contentDocumentMap.get(CDL.ContentDocumentId).Id, CDL.LinkedEntityId)  );
                }
            }
        }
        //remove already presentCDL
        for(ContentDistribution existingRec : [select id,RelatedRecordId,ContentVersionId from ContentDistribution where ContentVersionId in :existingDistributionIds and RelatedRecordId in :existingDistributionIds]){
            if(distributionsToInsert.containsKey(existingRec.ContentVersionId +''+ existingRec.RelatedRecordId)){ distributionsToInsert.remove(existingRec.ContentVersionId +''+ existingRec.RelatedRecordId); }
        }
        if(!distributionsToInsert.isEmpty() && !Auth.CommunitiesUtil.isGuestUser() ){
            insert distributionsToInsert.values();
        }
        /*
list<ContentDistribution> distributionsToInsert = new List<ContentDistribution>();
List<Schema.SObjectType> sObjtypeLst = new List<Schema.SObjectType>{Schema.HexaBPM__SR_Doc__c.SObjectType};
map<id,Document__c> relatedDocMap = new map<id,Document__c>();
map<Id,ContentVersion> contentDocumentMap =new map<id,ContentVersion>();
for (ContentDocumentLink CDL : (List<ContentDocumentLink>)newList) {
if(CDL.LinkedEntityId.getSObjectType() == Document__c.getSObjectType() ){
relatedDocMap.put(CDL.LinkedEntityId,null);
contentDocumentMap.put(CDL.ContentDocumentId,null);
}
for (Schema.SObjectType sObjType : sObjtypeLst) {
if(sObjType == CDL.LinkedEntityId.getSobjectType()){
CDL.Visibility = 'AllUsers';
break;
}
}
}
relatedDocMap =  new map<id,Document__c>([select id from Document__c where id in :relatedDocMap.keySet() and AvailableForExternalUsers__c=true]);
for(ContentVersion contentversionRecord :[SELECT Id,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId in :contentDocumentMap.keySet() and isLatest=true]){
contentDocumentMap.put(contentversionRecord.ContentDocumentId,contentversionRecord);
}
for (ContentDocumentLink CDL : (List<ContentDocumentLink>)newList) {
if(relatedDocMap.containsKey(CDL.LinkedEntityId)){
CDL.Visibility = 'AllUsers';
CDL.ShareType='I';
distributionsToInsert.add(createContentDistribution(contentDocumentMap.get(CDL.ContentDocumentId).Id, CDL.LinkedEntityId)  );
}
}
if(!distributionsToInsert.isEmpty()){
insert distributionsToInsert;
}
*/
        }catch(Exception ex){}
    }
    
    
    /**-------------------------------------------------------------------
	* Description: used to control the after insert logic 
	* -------------------------------------------------------------------**/
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        
        map<string, string> MapContentDocumentLink_CD_Id = new Map<string, string>();
        Map<string, string> srDocMap = new Map<string, string>();
        set<string> setSRDocIds = new Set<string>();
        set<ID> documentESignIds = new set<ID>();
        set<ID> documentsToUpdateStatusIds = new set<ID>();
        //Added by Tharun
        Set<Id> relatedContactIds = new Set<Id>();
        //For DLP                 
        Set<ID> parentIds = new Set<ID>();
      	Set<Id>QuoteIds = new Set<Id>();
        Set<ID> cotDoc = new Set<ID>(); 
        Map<id,id> mapOfContandLink = new  Map<id,id>();
        Map<Id,Id> mapOfDocumentsToInvoiceContentDocLink = new  Map<Id,Id>();//Added by KP - InvoiceClaimFormDocs
		Map<Id, Id> exceptionRequestIdsMap = new Map<Id, Id>();
        
        for(ContentDocumentLink CDL : (List<ContentDocumentLink>)newList){
            if(CDL.LinkedEntityId != null){                                
                if(cdl.LinkedEntityId.getSObjectType() == Schema.Case.SObjectType ){
                    system.debug(cdl.LinkedEntityId.getSObjectType() );
                    parentIds.add( cdl.LinkedEntityId );
                    cotDoc.add(cdl.ContentDocumentId );
                    mapOfContandLink.put(cdl.LinkedEntityId, cdl.ContentDocumentId);            
                }
                if(Schema.HexaBPM__SR_Doc__c.SObjectType == CDL.LinkedEntityId.getSobjectType()){
                    MapContentDocumentLink_CD_Id.put(CDL.Id, CDL.ContentDocumentId);
                    srDocMap.put(CDL.LinkedEntityId, CDL.ContentDocumentId);
                    setSRDocIds.add(CDL.LinkedEntityId);
                }
                if(Schema.Document__c.SObjectType == CDL.LinkedEntityId.getSobjectType()){
                    documentESignIds.add(CDL.LinkedEntityId);
                    documentsToUpdateStatusIds.add(CDL.LinkedEntityId);
                    mapOfDocumentsToInvoiceContentDocLink.put(CDL.ContentDocumentId, CDL.LinkedEntityId);//Added by KP - InvoiceClaimFormDocs
                }
                //Added by Tharun
                if(Schema.Contact.SObjectType == CDL.LinkedEntityId.getSObjectType()){
                    relatedContactIds.add(CDL.LinkedEntityId);
                }
                if (cdl.LinkedEntityId.getSObjectType() == Quote.SObjectType) {
            		QuoteIds.add(cdl.LinkedEntityId);
        		}
                if (cdl.LinkedEntityId.getSObjectType() == Schema.Exception_Request__c.SObjectType) {
                    exceptionRequestIdsMap.put(CDL.LinkedEntityId, CDL.ContentDocumentId);
        		}
                
            }      
        }
        
        if(parentIds.size() > 0){
            UpdateSAAttachments((List<ContentDocumentLink>)newList,parentIds,cotDoc,mapOfContandLink); 
        }
        
        if (MapContentDocumentLink_CD_Id.size() > 0 && !System.isFuture()) {
            UpdateSRDoc(MapContentDocumentLink_CD_Id);
            updateHandoverDetails(srDocMap);
        }
        
        if(setSRDocIds.size() > 0){
            DocuSignHelper.docusignBulktFilter(setSRDocIds); 
        }
        if(!documentESignIds.isEmpty()){ 
            DocumentTriggerHandler.validateAndProcessEsign(documentESignIds);
        }
        if(!documentsToUpdateStatusIds.isEmpty()){ 
            UpdateDocStatus(documentsToUpdateStatusIds);
        }
        //Added by Tharun
        if(relatedContactIds.size() > 0){
            UpdateCountOfFiles(relatedContactIds);
        }
        
        //Karunakar - BPM-449
        if(mapOfDocumentsToInvoiceContentDocLink != null){
            invoiceClaimDocmentUpdate(mapOfDocumentsToInvoiceContentDocLink);
        }
        if(QuoteIds.size() >0){
            AttachfiletoOppDocuments(QuoteIds,(List<ContentDocumentLink>)newList);
        }
        
        if(!exceptionRequestIdsMap.isEmpty()) {
            //add file link to exception Record
            setupImageOnExceptionRequest(exceptionRequestIdsMap, (List<ContentDocumentLink>)newList);
        }
    }
    
        
    public static void UpdateSAAttachments(List<ContentDocumentLink> cdls,Set<ID> parentIds,Set<ID> cotDoc,Map<id,id> mapOfContandLink) {
        try{ 
            if (parentIds.size() > 0 && cotDoc.size() > 0)
            {
                
                List<WorkOrder> wolist = [Select Id, CaseId, Before_Image__c, After_Image__c From WorkOrder Where CaseId In : parentIds];
                if(wolist.size() > 0)
                {
                    List<ContentVersion> cvslist = [SELECT Title, VersionData,ContentDocumentId,ContentDocument.CreatedBy.ProfileName__c,FileType FROM ContentVersion WHERE IsLatest = TRUE and ContentDocumentId in: cotDoc];
                    List<ContentDistribution> cdlst = new List<ContentDistribution>();
                    For(ContentVersion cvs :  cvslist)
                    {
                        if(cvs.FileType== 'JPG' || cvs.FileType== 'PNG')
                        {
                            ContentDistribution cd = new ContentDistribution();                    
                            cd.contentVersionId = cvs.Id;                            
                            cd.Name = cvs.Title;  
                            cdlst.add(cd);
                        }
                    }                   
                    if(cdlst.size() > 0)
                    {
                        Database.insert(cdlst, false); 
                    }
                    
                    List<ContentDistribution> cdlist =  [Select Id, ContentDocumentId,ContentVersion.Title, ContentDownloadUrl, DistributionPublicUrl,CreatedDate 
                                                         from ContentDistribution 
                                                         where ContentDocumentId in: cotDoc order by CreatedDate Desc Limit 1 ];
                    Map<Id, String> cdmap = New Map<Id, String>();
                    For(ContentDistribution cdn : cdlist)
                    {
                        cdmap.put(cdn.ContentDocumentId, cdn.ContentDownloadUrl);                        
                    }
                    For(WorkOrder wo : wolist)
                    {                        
                        if(wo.Before_Image__c == Null)
                        {
                            wo.Before_Image__c = '<img width="200px" height="200px" src="'+ cdmap.get(mapOfContandLink.get(wo.CaseId))+'"';
                        }
                        else
                        {
                            wo.After_Image__c = '<img width="200px" height="200px" src="'+ cdmap.get(mapOfContandLink.get(wo.CaseId))+'"';
                        }                                                   
                    }
                    
                    if(wolist.size() > 0)
                    {
                        update wolist;
                    }
                    
                    
                }      
            }
            
        }
        catch(Exception e)
        { 
            system.debug('Exception in SA update');  
        }
    }
    
    public static void UpdateCountOfFiles(Set<Id> contactsToUpdateCountIds) 
    {
        List<Contact> conToUpdate = new List<Contact>();
        Id brokerConRecTypeId = Schema.SobjectType.Contact.getRecordTypeInfosByDeveloperName()
                                        .get('BrokerAgent')
                                        .getRecordTypeID();
        for(Contact conRecord : [SELECT Id,(SELECT Id FROM ContentDocumentLinks)
                                 FROM Contact
                                 WHERE Id IN :contactsToUpdateCountIds AND RecordTypeId =:brokerConRecTypeId])
        {
            conRecord.FileUploadedCount__c = conRecord.ContentDocumentLinks.size();
            conToUpdate.add(conRecord);
        }
        update conToUpdate;
    }

    /*public static void UpdateDocStatus(set<ID> documentsToUpdateStatusIds) {
  
        List<Document__c> docToUpdate = new List<Document__c>();
        for (Document__c docRecord : [Select Id, Status__c From Document__c Where Id in: documentsToUpdateStatusIds]) {
            docRecord.Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
            docToUpdate.add(docRecord);
        }
        update docToUpdate;
    }*/
    
    public static void UpdateDocStatus(set<ID> documentsToUpdateStatusIds) {
        
        List<Document__c> docToUpdate = new List<Document__c>();
        Set<Id> salesOrderToUpdateIdSet = new Set<Id>();
        Set<String> skipRecordTypes = new Set<String>{'RDD_Document','RETL_Lease_Document'};
        for (Document__c docRecord : [Select Id, Status__c, ProcessResaleCase__c, DocumentType__c,
                                        Case__c, Case__r.RecordTypeId, RecordType.DeveloperName,
                                        SalesOrder__c, ProjectName__c
                                      From Document__c Where Id in: documentsToUpdateStatusIds]) {
            if (!skipRecordTypes.contains(docRecord.RecordType.DeveloperName)) {
                docRecord.Status__c = Constants.DOCUMENT_STATUS_UPLOADED;
            }
            if(docRecord.RecordType.DeveloperName == ResaleConstants.CASE_DOCUMENT_RECORDTYPE_DNAME 
                && ((docRecord.DocumentType__c == ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE 
                        && UserInfo.getProfileId() != ResaleConstants.RESALE_RELATIONSHIP_MANAGER_PROFILEID) 
                    || docRecord.DocumentType__c == ResaleConstants.CASE_LISTING_AGREEMENT_DOCUMENT_TYPE) 
                && docRecord.Case__c != null && docRecord.Case__r.RecordTypeId == ResaleConstants.Resale_Case_RecordTypeId 
                    ){
                docRecord.ProcessResaleCase__c = true;
            }
            docToUpdate.add(docRecord);
            if(docRecord.ProjectName__c != null && docRecord.ProjectName__c.trim().equalsIgnoreCase(System.Label.DubaiProject.trim())
                && docRecord.DocumentType__c.trim().equalsIgnoreCase(System.Label.SignedIntentionToBook.trim())
                && docRecord.SalesOrder__c != null){
                salesOrderToUpdateIdSet.add(docRecord.SalesOrder__c);
            }
        }
        update docToUpdate;
        if(!salesOrderToUpdateIdSet.isEmpty()){
            updateSOs(salesOrderToUpdateIdSet);
        }
    }
    
    public static void UpdateSRDoc(map<string, string> TriggerNew) {
        
        
        map<string, HexaBPM__SR_Doc__c> MapSRDocsTBU = new Map<string, HexaBPM__SR_Doc__c>();
        map<string, ContentDocumentLink> MapContentDocument = new Map<string, ContentDocumentLink>();
        
        for (ContentDocumentLink objCDL : [SELECT Id, ContentDocument.Title,ContentDocument.FileExtension,
                                           ContentDocumentId,LinkedEntityId 
                                           FROM ContentDocumentLink WHERE Id IN :TriggerNew.keySet()]) {
                                               
                                               HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c(Id = objCDL.LinkedEntityId);
                                               objSRDoc.HexaBPM__Doc_ID__c = objCDL.ContentDocumentId; 
                                               objSRDoc.HexaBPM__Status__c = 'Uploaded';
                                               MapSRDocsTBU.put(objCDL.LinkedEntityId, objSRDoc);
                                               /*if (MapSRDocsTBU.get(objCDL.LinkedEntityId) != null && MapSRDocsTBU.get(objCDL.LinkedEntityId).HexaBPM__Sys_IsGenerated_Doc__c){
objSRDoc.HexaBPM__Status__c = 'Generated';
}else if(!MapSRDocsTBU.get(objCDL.LinkedEntityId).Skip_Doc_Id_Update__c){
objSRDoc.HexaBPM__Status__c = 'Uploaded';
}*/
                                               //MapSRDocsTBU.put(objCDL.LinkedEntityId,objSRDoc);
                                               
                                           }
        for(HexaBPM__SR_Doc__c tempDoc : [select id from HexaBPM__SR_Doc__c where id in :MapSRDocsTBU.keySet() and HexaBPM__Sys_IsGenerated_Doc__c =true]){
            MapSRDocsTBU.get(tempDoc.id).HexaBPM__Status__c = 'Generated';
        }
        
        if (MapSRDocsTBU.size() > 0) {        
            update MapSRDocsTBU.values();
        }
        
    }
    
    public static ContentDistribution createContentDistribution(Id contentVersionId,Id documentId){
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = contentVersionId;
        newDist.Name = 'External Link';
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload=true;
        newDist.RelatedRecordId= documentId;
        return newDist;
    }

    /**
    * @description update the handover details Docusign Upload Date whenever file upload on Signed Handover NOC Letter placeholder
    * @author rmohmmed@aldar.com | 09-14-2023 | 
    * @return void
    **/
    public static void updateHandoverDetails(Map<string, string> srDocMap) {
        List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id, HexaBPM__Service_Request__r.HandoverDetail__c FROM HexaBPM__SR_Doc__c WHERE ID IN :srDocMap.keySet() AND Name =:Constants.DOCUMENT_SIGNED_UNIFIED_HANDOVER_DOCUMENTS];
        List<HandoverDetails__c> handoverDetailsList = new List<HandoverDetails__c>();

        for(HexaBPM__SR_Doc__c srDoc : srDocList) {
            HandoverDetails__c handoverDetails = new HandoverDetails__c();
            handoverDetails.Id = srDoc.HexaBPM__Service_Request__r.HandoverDetail__c;
            handoverDetails.Docusign_Upload_Date__c = System.today();
            handoverDetailsList.add(handoverDetails);
        }
        
        if(!handoverDetailsList.isEmpty()) {
            update handoverDetailsList;
        }
    }
    private static void updateSOs(Set<Id> salesOrderToUpdateIdSet) {
        if(!salesOrderToUpdateIdSet.isEmpty()){
            List<SalesOrder__c> salesOrderToUpdate = new List<SalesOrder__c>();
            Date td = System.today();
            for(SalesOrder__c so: [
                SELECT Id, 
                    IntentionToBookSigned__c, IntentionToBookSignedDate__c 
                FROM SalesORder__c 
                WHERE Id IN: salesOrderToUpdateIdSet
                    AND IntentionToBookSigned__c = false]
            ){
                so.IntentionToBookSigned__c = true;
                so.IntentionToBookSignedDate__c = td;
                salesOrderToUpdate.add( so );
            }
            if( !salesOrderToUpdate.isEmpty() ){
                update salesOrderToUpdate;
            }
        }
    }
    
    //Added by Karunakar - BPM-449
    public static void invoiceClaimDocmentUpdate(Map<Id,Id> mapOfDocumentsToInvoiceContentDocLink) {
        try{
            if (mapOfDocumentsToInvoiceContentDocLink != null)
            {
                Boolean isClaimForm = false;
                for (Document__c docRecord : [Select Id, DocumentType__c
                                            From Document__c Where Id in: mapOfDocumentsToInvoiceContentDocLink.values()]) {
                    if(docRecord.DocumentType__c == 'Invoice Claim Form'){
                        isClaimForm = true;
                        break;
                    }
                }
                if(isClaimForm){
                    List<ContentVersion> cvslist = [SELECT Title, VersionData,ContentDocumentId,
                                                ContentDocument.CreatedBy.ProfileName__c,FileType 
                                                FROM ContentVersion 
                                                WHERE IsLatest = TRUE and ContentDocumentId in: mapOfDocumentsToInvoiceContentDocLink.keySet()];
                    List<ContentDistribution> cdlst = new List<ContentDistribution>();                                
                    for(ContentVersion cvs :  cvslist){
                        if(mapOfDocumentsToInvoiceContentDocLink.containsKey(cvs.ContentDocumentId)){
                            ContentDistribution cd = createContentDistribution(cvs.id, mapOfDocumentsToInvoiceContentDocLink.get(cvs.ContentDocumentId));              
                            cdlst.add(cd);
                        }  
                        if(!cdlst.isEmpty()){
                            Database.insert(cdlst, false); 
                        }
                    }  
                }                                         
            }
        }catch(Exception e)
        { 
            system.debug('Exception in invoiceClaimDocuemntUpdate');  
        }
    }
    public static void AttachfiletoOppDocuments(Set<Id>QuoteIds,List<ContentDocumentLink> cdls){
        Map<Id,Id>QuoteOppMap = new Map<Id,Id>();
        Map<Id,Id>DocOppMap = new Map<Id,Id>();
        List<Quote> QuoteLIst = [SELECT id,OpportunityID FROM Quote WHERE Id=:QuoteIds AND Opportunity.RecordType.Name='Leasing'];
        for(Quote qt:QuoteLIst){
             QuoteOppMap.put(qt.Id, qt.OpportunityId);
        }
        List<Document__c> DocumentList = [SELECT id,Opportunity__c,DocumentType__c FROM Document__c WHERE Opportunity__c  IN (SELECT OpportunityId FROM Quote WHERE Id =:QuoteIds) AND Opportunity__r.RecordType.Name ='Leasing'];
        for(Document__c doc:DocumentList){
            if(doc.DocumentType__c =='Leasing Offer Letter'){
                DocOppMap.put(doc.Opportunity__c,doc.Id);
            }
        }
        // Create new ContentDocumentLinks
        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        for (ContentDocumentLink cdl : (List<ContentDocumentLink>)cdls) {
            Id oppId = QuoteOppMap.get(cdl.LinkedEntityId);
            Id DocId =DocOppMap.get(oppId);
            if (DocId != null) {
                newLinks.add(new ContentDocumentLink(
                    ContentDocumentId = cdl.ContentDocumentId,
                    LinkedEntityId = DocId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
        }
        
        if (!newLinks.isEmpty()) {
            insert newLinks;
        }
    }
    
    public static void setupImageOnExceptionRequest(Map<Id, Id> exceptionRequestIdsMap, List<ContentDocumentLink> cdls) {
        List<ContentVersion> cvsList = [SELECT Title, VersionData, ContentDocumentId, FileType FROM ContentVersion WHERE IsLatest = TRUE and ContentDocumentId IN: exceptionRequestIdsMap.values()];
        Map<Id, Id> contentVersionMap = new Map<Id, Id>();
        List<Exception_Request__c> exceptionRequestList = new List<Exception_Request__c>();
        
        for(ContentVersion cvs :  cvsList) {
           if(cvs.FileType == 'JPG' || cvs.FileType == 'PNG' || cvs.FileType == 'JPGE') {
               contentVersionMap.put(cvs.ContentDocumentId, cvs.Id);
           }
        }
        
        for(Id exceptionRequestId : exceptionRequestIdsMap.keySet()) {
            Id contentDocumentId = exceptionRequestIdsMap.get(exceptionRequestId);
            
            if(contentVersionMap.containsKey(contentDocumentId)) {
                String imageLink = '<img src="/sfc/servlet.shepherd/version/download/' + contentVersionMap.get(contentDocumentId) +'" height="100%" />';
                Exception_Request__c exceptionRequest = new Exception_Request__c (Id=exceptionRequestId);
                exceptionRequest.Image_Preview__c = imageLink;
                exceptionRequestList.add(exceptionRequest);
            }
        }
        
        if(!exceptionRequestList.isEmpty()) {
            update exceptionRequestList;
        }
    }
}