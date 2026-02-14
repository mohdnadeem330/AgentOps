public with sharing class DocumentService {

    public static map<string,list<DocumentPlaceHolder__mdt>> getDocumentMetaDataByCategory(set<String> categoryNames){
        map<string,list<DocumentPlaceHolder__mdt>> valueToReturn = new map<string,list<DocumentPlaceHolder__mdt>>();
        for(string catName : categoryNames){
            valueToReturn.put(catName,new list<DocumentPlaceHolder__mdt>());
        }
        //Modified by CloudzLab
        //Start of Changes
        for(DocumentPlaceHolder__mdt tempRecord : [select id,DeveloperName,Identityverification__c,eSignRequired__c, DeliveryOption__c, DocgenPackageName__c,EligibleForeSign__c,DocumentType__c,Category__c,RecordTypeDeveloperName__c,ProjectName__c,AvailableForExternalUsers__c,GeneratedManually__c, Region__c from DocumentPlaceHolder__mdt where Category__c in : categoryNames AND Is_ECSS__c = false ORDER BY DocumentType__c ASC]){
        //End of Changes
            valueToReturn.get(tempRecord.Category__c).add(tempRecord);
        }
        return valueToReturn;
    }

    /**
    * regenerateAllDocuments
    *
    * This method used to regenerate all the missing placeholder and update the generate flag to true
    * Calling method must do exceptionhandling
    *
    * @param  recordId salesOrder recordId
    * @return void
    */
    public static void regenerateAllDocuments(String recordId){
       
        //get Sales Order
        SalesOrder__c soRecord = [select id,BookingDate__c,ProjectName__c,Opportunity__c,SalesManager__c from SalesOrder__c where id=:recordId limit 1];
        //get Booking and reservation Documents
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_RESERVATION,Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING});
        string documentType = soRecord.BookingDate__c!=null ? Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING : Constants.DOCUMENT_PLACEHOLDER_CATEGORY_RESERVATION;
        
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        //get Document Metadata
        if(!documentMap.isEmpty() && documentMap.containsKey(documentType)){
            set<string> packageNames = new set<string>();
            set<string> deliveryOptionNames = new set<string>();
            for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentType)){
                packageNames.add(tempMetaRec.DocgenPackageName__c);
                deliveryOptionNames.add(tempMetaRec.DeliveryOption__c);
            }
            map<string,Loop__DDP_Integration_Option__c > docgenPackage = new map<string, Loop__DDP_Integration_Option__c >();
            for(Loop__DDP_Integration_Option__c tempRec : [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name in :deliveryOptionNames and Loop__DDP__r.Name in :packageNames ]){
                docgenPackage.put(tempRec.Loop__DDP__r.Name.toLowerCase() + tempRec.Name.toLowerCase() ,tempRec);    
            }
            map<string,Loop__DDP_Integration_Option__c> docgenPackageIdMap = new map<string,Loop__DDP_Integration_Option__c>();
            for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentType)){
                if(tempMetaRec.DocgenPackageName__c!=null && tempMetaRec.DeliveryOption__c!=null && docgenPackage.containsKey(tempMetaRec.DocgenPackageName__c.toLowerCase()  + tempMetaRec.DeliveryOption__c.toLowerCase() )){
                    docgenPackageIdMap.put( tempMetaRec.DeveloperName, docgenPackage.get(tempMetaRec.DocgenPackageName__c.toLowerCase()  + tempMetaRec.DeliveryOption__c.toLowerCase() ));
                }
            }
            //get Existing Documents
            map<string,Document__c> existingDocMap = new map<string,Document__c>();
            for(Document__c tempDoc : [select id,DocumentType__c,SalesOrder__c,DocgenPackageId__c,DeliveryOptionId__c from Document__c where SalesOrder__c = :soRecord.Id]){
                existingDocMap.put(tempDoc.SalesOrder__c+tempDoc.DocumentType__c,tempDoc);
            }

            //Create Documents
            for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentType)){
                //Skip if project setting doesn't match
                if(tempMetaRec.ProjectName__c!=null && !tempMetaRec.ProjectName__c.equalsIgnoreCase(soRecord.ProjectName__c)){
                    continue;
                }
                string recordTypeID=null;
                if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                    if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                        documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                    }
                    recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                }
                //Check if contains Correct Version of Package ID
                //****TODO  */
                if(existingDocMap.containsKey( soRecord.Id + tempMetaRec.DocumentType__c) && docgenPackageIdMap.containsKey(tempMetaRec.DeveloperName)  ){
                    Document__c documentRecord = existingDocMap.get( soRecord.Id + tempMetaRec.DocumentType__c);
                    documentRecord.DocgenPackageId__c =docgenPackageIdMap.get(tempMetaRec.DeveloperName).Loop__DDP__c;
                    documentRecord.DeliveryOptionId__c=docgenPackageIdMap.get(tempMetaRec.DeveloperName).Id;
                    documentRecord.GenerateDocument__c =true;
                    documentListToInsert.add(documentRecord);
                }/*else if(existingDocMap.containsKey( soRecord.Id + tempMetaRec.DocumentType__c) && docgenPackageIdMap.containsKey(tempMetaRec.DeveloperName) ){
                    documentRecord.GenerateDocument__c =true;
                    documentListToInsert.add(documentRecord);
                }*/else if(!existingDocMap.containsKey( soRecord.Id + tempMetaRec.DocumentType__c)){

                    Document__c documentRecord = DocumentService.createDocumentRecord(soRecord.Opportunity__c,'','',tempMetaRec.DocumentType__c,soRecord.Id,'',recordTypeID);
                    if(soRecord.SalesManager__c!=null){documentRecord.OwnerId=soRecord.SalesManager__c;}
                    documentRecord.SendForESign__c=tempMetaRec.eSignRequired__c; 
                    documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                    documentRecord.EligibleForeSign__c=tempMetaRec.EligibleForeSign__c;
                    documentRecord.Identityverification__c=tempMetaRec.Identityverification__c;
                    documentRecord.GenerateDocument__c =docgenPackageIdMap.containsKey(tempMetaRec.DeveloperName) ? true :false;
                    documentRecord.DocgenPackageId__c = docgenPackageIdMap.containsKey(tempMetaRec.DeveloperName) ? docgenPackageIdMap.get(tempMetaRec.DeveloperName).Loop__DDP__c:null;
                    documentRecord.DeliveryOptionId__c= docgenPackageIdMap.containsKey(tempMetaRec.DeveloperName) ? docgenPackageIdMap.get(tempMetaRec.DeveloperName).Id :null;
                    documentListToInsert.add(documentRecord);
                } 

            }
        }
        if(!documentListToInsert.isEmpty()){
            upsert documentListToInsert;
        }
        
    }

    @AuraEnabled(cacheable=false)
    public static Document__c createDocumentRecord( String opportunity, String expressionofInterest, String unit, String documentType, String salesOrder, String account,Id documentRecTypeID){
        //Id customerDocumentId = Schema.SObjectType.Document__c.getRecordTypeInfosByName().get('Customer Document').getRecordTypeId();

        Document__c documentRecord = new Document__c();
        
        documentRecord.RecordtypeId= documentRecTypeID;
        if (String.isNotEmpty(salesOrder)) {
            documentRecord.SalesOrder__c = salesOrder;
        }
        if (String.isNotEmpty(account)) {
            documentRecord.Account__c = account;
        }
        if (String.isNotEmpty(expressionofInterest)) {
            documentRecord.ExpressionofInterest__c = expressionofInterest;
        }
        if (String.isNotEmpty(opportunity)) {
        documentRecord.Opportunity__c = opportunity;
        }
        if (String.isNotEmpty(unit)) {
            documentRecord.Unit__c = unit;
        }
        if (String.isNotEmpty(documentType)) {
            documentRecord.DocumentType__c = documentType;
        }
        return documentRecord;     
    }

    @AuraEnabled(cacheable=false)
    public static void insertDocumentRecords(List<Document__c> documentList){
        insert documentList;
    }

    /*
    * Get Documents by Account Ids
    */  
    public static Map<Id,List<Document__c>> getDocumentbyAccountId(Set<Id> accountIds){
        Map<Id,List<Document__c>> accountDocumentMap = new Map<Id,List<Document__c>>();
        for(Document__c documentRec : [Select Id,Account__c,Name,DocumentType__c,EligibleForeSign__c FROM Document__c WHERE Account__c IN:accountIds]){
            List<Document__c> documentList = new List<Document__c>();
            if(accountDocumentMap!=null && accountDocumentMap.containsKey(documentRec.Account__c)){
                documentList = accountDocumentMap.get(documentRec.Account__c);
            }
            documentList.add(documentRec);
            accountDocumentMap.put(documentRec.Account__c,documentList);
        }
        System.debug('**Documents by Account**'+accountDocumentMap);
        return accountDocumentMap;
    }
    
    /*
    * Get Documents URL
    */ 
    public static Map<Id,DocumentQueryModel> getDocumentDetails(Map<Id,Document__c> documentDetailMap){

        List<Id> contentDocumentIds = new List<Id>();
        Map<Id,ContentVersion> convertedDocumentVersionMap = new Map<Id,ContentVersion>();
        Map<Id,DocumentQueryModel> documentQueryModelMap = new Map<Id,DocumentQueryModel>();

        Map<Id,ContentDocumentLink> documentAttachedMap = ContentDocumentLinkService.getLatestDocumentByParentId(documentDetailMap.keySet());

        for(ContentDocumentLink contentDocumentRec : documentAttachedMap.values()){
            contentDocumentIds.add(contentDocumentRec.ContentDocumentId);
        }

        for(ContentVersion contentVer : ContentVersionService.getFileIds(contentDocumentIds)){
            convertedDocumentVersionMap.put(contentVer.ContentDocumentId,contentVer);
        }

        for(Document__c documentRec : documentDetailMap.values()){
            DocumentQueryModel docModel = new DocumentQueryModel(documentRec);
            if(documentAttachedMap.containsKey(documentRec.Id)){
                ContentDocumentLink contentDocumentRec = documentAttachedMap.get(documentRec.Id);
                if(convertedDocumentVersionMap.containsKey(contentDocumentRec.ContentDocumentId)){
                    ContentVersion contentVer = convertedDocumentVersionMap.get(contentDocumentRec.ContentDocumentId);
                    //docModel.fileData = contentVer.VersionData ;
                    docModel.documentURL = getFileURL(contentVer.Id);
                    docModel.fileExtension = String.valueOf(contentVer.FileExtension) ;
                    docModel.title = contentVer.Title ;
                    docModel.contentVersionId = contentVer.Id;
                    documentQueryModelMap.put(documentRec.Id,docModel);
                }
            }
            documentQueryModelMap.put(documentRec.Id,docModel);
        }

        return documentQueryModelMap ;
    }

    public static DocumentQueryModel uploadFileToParentRecord(Document__c documentRec,String title, Blob fileContent){
        DocumentQueryModel newDocument = new DocumentQueryModel(documentRec);

        ContentVersion contentVersionRec = ContentVersionService.createContentVersion(title,fileContent);
        contentVersionRec.IsMajorVersion = false;
        insert contentVersionRec ;
        newDocument.contentVersionId = contentVersionRec.Id;

        //----- Prepare reponse based on Content Version Created
        newDocument.fileExtension = String.valueOf(contentVersionRec.FileExtension) ; 
        newDocument.title = contentVersionRec.Title ;
        newDocument.documentURL = getFileURL(contentVersionRec.Id);

        ContentDocumentLinkService.createContentDocumentLinks(new List<ContentVersion>{contentVersionRec},documentRec.Id);

        return newDocument ;
    }

    public static String getFileURL(String contentVersionId){
        String fileURL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v54.0/sobjects/ContentVersion/'+contentVersionId+'/VersionData';
        return fileURL ;
    }

        
    /**
    * getProjectPaymentPlanDetailsRecords
    *
    *  This method used to return all Payment Plan documents related to projectIds
    *
    * @param  projectId project id to retrive
    * @return map<String,list<PublicLinkDetails>>
    */
    @AuraEnabled(cacheable=true)
    public static map<String,list<PublicLinkDetails>> getProjectPaymentPlanDetailsRecords(Id projectId, Boolean brokerPortalFlag){
        map<String,list<PublicLinkDetails>> recordToReturn = new map<String,list<PublicLinkDetails>>();

        list<Id> paymentPlansIdList = new list<Id>();

        list<BuildingSectionMapping__c> buildingSectionMappings = [select PaymentPlan__c from BuildingSectionMapping__c where BuildingSectionName__r.project__c =: projectId WITH SECURITY_ENFORCED];

        for(BuildingSectionMapping__c buildingSectionMapping : buildingSectionMappings){
            paymentPlansIdList.add(buildingSectionMapping.PaymentPlan__c);
        }

        list<PaymentPlan__c> paymentPlans = [select id,Name,(select id,DocumentType__c from Documents__r) from PaymentPlan__c where Id In: paymentPlansIdList AND BrokerPortalFlag__c =:brokerPortalFlag WITH SECURITY_ENFORCED];

        if(!paymentPlans.isEmpty()){
            map<id,list<PublicLinkDetails>> docRelatedContentVersions = new map<id,list<PublicLinkDetails>>();

            for(PaymentPlan__c tempPaymentPlan : paymentPlans){
                if(!tempPaymentPlan.Documents__r.isEmpty()){
                    for(Document__c tempDoc : tempPaymentPlan.Documents__r){
                        docRelatedContentVersions.put(tempDoc.Id ,new list<PublicLinkDetails>());
                    }
                }
            }

            for(ContentDistribution dist : [select id,RelatedRecordId,ContentDownloadUrl,DistributionPublicUrl,PdfDownloadUrl,ContentVersion.Title from ContentDistribution where RelatedRecordId in:docRelatedContentVersions.keySet()] ){
                docRelatedContentVersions.get(dist.RelatedRecordId).add(new PublicLinkDetails(dist));
            }

            for(PaymentPlan__c tempPaymentPlan : paymentPlans){
                map<String,list<PublicLinkDetails>> docDetails = new map<String,list<PublicLinkDetails>>();
                if(!tempPaymentPlan.Documents__r.isEmpty()){
                    for(Document__c tempDoc : tempPaymentPlan.Documents__r){
                        if (recordToReturn.containsKey(tempDoc.DocumentType__c) && !recordToReturn.get(tempDoc.DocumentType__c).isEmpty() && !docRelatedContentVersions.get(tempDoc.Id).isEmpty()) {
                            list<PublicLinkDetails> tempList = recordToReturn.get(tempDoc.DocumentType__c);
                            tempList.addAll(docRelatedContentVersions.get(tempDoc.Id));
                            recordToReturn.put(tempDoc.DocumentType__c, tempList);
                        } else if (!docRelatedContentVersions.get(tempDoc.Id).isEmpty()) {
                            recordToReturn.put(tempDoc.DocumentType__c, docRelatedContentVersions.get(tempDoc.Id));
                        }
                    }
                }
            }
        }

        return recordToReturn;
    }

    /**
    * getProjectOfferDetailsRecords
    *
    *  This method used to return all Offer documents related to projectIds
    *
    * @param  projectId project id to retrive
    * @return map<String,list<PublicLinkDetails>>
    */
    @AuraEnabled(cacheable=true)
    public static map<String,list<PublicLinkDetails>> getProjectOfferDetailsRecords(Id projectId, Boolean brokerPortalFlag){
        map<String,list<PublicLinkDetails>> recordToReturn = new map<String,list<PublicLinkDetails>>();

        list<OffersPromotions__c> offers = [select id,Name,Project__c,(select id,DocumentType__c from Documents__r) from OffersPromotions__c where project__c =: projectId AND BrokerPortalFlag__c =:brokerPortalFlag WITH SECURITY_ENFORCED];

        if(!offers.isEmpty()){
            map<id,list<PublicLinkDetails>> docRelatedContentVersions = new map<id,list<PublicLinkDetails>>();

            for(OffersPromotions__c tempOffer : offers){
                if(!tempOffer.Documents__r.isEmpty()){
                    for(Document__c tempDoc : tempOffer.Documents__r){
                        docRelatedContentVersions.put(tempDoc.Id ,new list<PublicLinkDetails>());
                    }
                }
            }

            for(ContentDistribution dist : [select id,RelatedRecordId,ContentDownloadUrl,DistributionPublicUrl,PdfDownloadUrl,ContentVersion.Title from ContentDistribution where RelatedRecordId in:docRelatedContentVersions.keySet()] ){
                docRelatedContentVersions.get(dist.RelatedRecordId).add(new PublicLinkDetails(dist));
            }
            
            for(OffersPromotions__c tempOffer : offers){
                map<String,list<PublicLinkDetails>> docDetails = new map<String,list<PublicLinkDetails>>();
                if(!tempOffer.Documents__r.isEmpty()){
                    for(Document__c tempDoc : tempOffer.Documents__r){
                        if (recordToReturn.containsKey(tempDoc.DocumentType__c) && !recordToReturn.get(tempDoc.DocumentType__c).isEmpty() && !docRelatedContentVersions.get(tempDoc.Id).isEmpty()) {
                            list<PublicLinkDetails> tempList = recordToReturn.get(tempDoc.DocumentType__c);
                            tempList.addAll(docRelatedContentVersions.get(tempDoc.Id));
                            recordToReturn.put(tempDoc.DocumentType__c, tempList);
                        } else if (!docRelatedContentVersions.get(tempDoc.Id).isEmpty()) {
                            recordToReturn.put(tempDoc.DocumentType__c, docRelatedContentVersions.get(tempDoc.Id));
                        }
                    }
                }
            }
        }
        
        return recordToReturn;
    }
    
    public static List<Document__c> getSalesOrderDocuments(Id soId)
    {
        List<Document__c> documentList = [SELECT id, Name, GenerateDocument__c FROM Document__c WHERE SalesOrder__c =: soId];
        
        return documentList;
    }
    
     public static Document__c getDocumentRecordById(Id documentId)
    {
        Document__c documentList = [SELECT id, DocumentType__c, RecordtypeId, EligibleForeSign__c FROM Document__c WHERE Id =: documentId];
        
        return documentList;
    }
    
    public static Map<Id,List<Document__c>> getDocumentbySOCancellationId(Set<Id> soCancellationIdSet){
        Map<Id,List<Document__c>> soCancellationDocumentMap = new Map<Id,List<Document__c>>();
        //,isDownloadable__c
        // Added the ContentDocumentLinks query in existing query to validate required documents uploaded or not: Bashim 
        for(Document__c documentRec : [SELECT Id, Sales_Order_Cancellation__c, Name, DocumentType__c, EligibleForeSign__c, Status__c, (SELECT Id FROM ContentDocumentLinks ) 
                                       FROM Document__c WHERE Sales_Order_Cancellation__c IN: soCancellationIdSet]){
                                           List<Document__c> documentList = new List<Document__c>();
                                           if(soCancellationDocumentMap!=null && soCancellationDocumentMap.containsKey(documentRec.Sales_Order_Cancellation__c)){
                                               documentList = soCancellationDocumentMap.get(documentRec.Sales_Order_Cancellation__c);
                                           }
                                           documentList.add(documentRec);
                                           soCancellationDocumentMap.put(documentRec.Sales_Order_Cancellation__c,documentList);
                                       }
        System.debug('####Documents by SO Cancellation ID: '+soCancellationDocumentMap);
        return soCancellationDocumentMap;
    }

    /**
    * PublicLinkDetails
    *
    * Warpper class to store the link details
    *
    */
    public class PublicLinkDetails{
        @AuraEnabled
        public string uid;
        @AuraEnabled
        public string name;
        @AuraEnabled
        public string link;
        public publicLinkDetails(ContentDistribution cdDetails){
            uid=cdDetails.Id;
            name=cdDetails.ContentVersion.Title;
            link=cdDetails.ContentDownloadUrl;
        }
    }
    

}