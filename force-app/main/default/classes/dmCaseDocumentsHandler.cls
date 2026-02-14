/*
Class       : dmCaseDocumentsHandler
Author      : Smaartt
Description : This class is accessed from LWC to get Customer/Aldar documents and show in Salesforce
TestClass   : dmCaseDocumentsHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              05/06/2024           Initial Version
****************************************************************************************************************/
public without sharing class dmCaseDocumentsHandler {
   
    @AuraEnabled // changes done by Parag 16/05/25 (15-35)
    public static void updateDocument(Document__c doc) {
        if (doc == null || doc.Id == null) {
            throw new AuraHandledException('Invalid document provided.');
        }
       
        // Fetch existing document
        Document__c existingDoc = [
            SELECT Id, AvailableForExternalUsers__c
            FROM Document__c
            WHERE Id = :doc.Id
            LIMIT 1
        ];
       
        // Allow any SF internal user to update "Visible to Customer"
        existingDoc.AvailableForExternalUsers__c = doc.AvailableForExternalUsers__c;
        System.debug('existingDoc.AvailableForExternalUsers__c--->'+existingDoc.AvailableForExternalUsers__c);
        try {
            update existingDoc;
        } catch (DmlException e) {
            throw new AuraHandledException('Failed to update visibility. Error: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static void createDocument(Document__c doc,string recTypeDevName,string signedDocType){
        Map<string,string> CaseRecTypeNames = DM_UtilityController.getCaseRecTypeName(new list<string>{doc.Case__c});
        doc.recordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId();
        doc.Case_Recordtype__c = CaseRecTypeNames.get(doc.Case__c);
        insert doc;
        if(!String.isEmpty(signedDocType)){
            System.debug('signedDocType'+ signedDocType);
            Document__c newDoc = new Document__c();
            newDoc.DocumentType__c = signedDocType;
            newDoc.recordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId();
            newDoc.Case__c = doc.Case__c;
            newDoc.Case_Recordtype__c = CaseRecTypeNames.get(doc.Case__c);
            insert newDoc;
        }
    }
    
    @AuraEnabled
    public static List<documentWrapper> getAldarDocuments(String caseId) {
        List<documentWrapper> docWrapList = new List<documentWrapper>();
      //  map<Id,Document__c> docIdvsDoc = new map<Id,Document__c>([SELECT Id,DocumentType__c,AvailableForExternalUsers__c,Other_Document_Name__c FROM Document__c WHERE Case__c = :caseId AND RecordType.DeveloperName =: Label.DM_CustomerDocumentRecordType ]);
        Id recordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName()
            .get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
        
        map<Id, Document__c> docIdvsDoc = new map<Id, Document__c>(
            [SELECT Id, DocumentType__c, AvailableForExternalUsers__c,Other_Document_Name__c
             FROM Document__c
             WHERE Case__c = :caseId AND RecordTypeId = :recordTypeId]
        );

        system.debug('docIdvsDoc==='+docIdvsDoc);
        for(Document__c doc : docIdvsDoc.values()){
            documentWrapper docWrap = new documentWrapper();
            docWrap.doc = doc;
            docWrap.versionCount=0;
            docWrap.contentVersion= new contentVersion();            
            docWrapList.add(docWrap);
        }
       
        map<Id,Id> conDocIdvsLinkedId = new map<Id,Id>();    
        if (!docIdvsDoc.isEmpty()) {
            List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :docIdvsDoc.keyset() ORDER BY ContentDocument.CreatedDate ASC];
           
            List<Id> contentDocumentIds = new List<Id>();
            for (ContentDocumentLink link : contentDocumentLinks) {
                contentDocumentIds.add(link.ContentDocumentId);
                conDocIdvsLinkedId.put(link.ContentDocumentId,link.LinkedEntityId);
            }
           
            for (ContentVersion con : [SELECT Id, Title, FileExtension, ContentDocumentId, CreatedDate FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds ORDER BY CreatedDate ASC]) {
                for (documentWrapper wrap : docWrapList) {
                    if (wrap.doc.Id == conDocIdvsLinkedId.get(con.ContentDocumentId)) {
                        wrap.versionCount++;
                        if (wrap.doc.DocumentType__c == Label.DM_DocumentTypeFinalTLA) {
                            if (con.Title.contains('TLA')) {
                                wrap.contentVersion = con;
                            }
                        } else if (wrap.doc.DocumentType__c == Label.DM_DocumentTypeSignedCAS) {
                            if (con.Title.contains('CAS')) {
                                wrap.contentVersion = con;
                            }
                        } else {
                            wrap.contentVersion = con;
                        }
                    }
                }
            }
            System.debug('docWrapList: ' + docWrapList);
            return docWrapList;
        } else {
            return null;
        }
    }
    
    @AuraEnabled
    public static List<documentWrapper> getCustomerDocuments(String caseId) {
        List<documentWrapper> docWrapList = new List<documentWrapper>();
        // map<Id,Document__c> docIdvsDoc = new map<Id,Document__c>([SELECT Id,DocumentType__c,AvailableForExternalUsers__c,Other_Document_Name__c,(SELECT Id,File_Name__c,External_URL__c,Deleted_by_Creator__c FROM External_Files__r WHERE Deleted_by_Creator__c = false) FROM Document__c WHERE Case__c = :caseId AND RecordType.DeveloperName =: Label.DM_CaseDocumentRecordType]);
        Id recordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName()
            .get(Label.DM_CaseDocumentRecordType).getRecordTypeId();
        
        map<Id, Document__c> docIdvsDoc = new map<Id, Document__c>(
            [SELECT Id, DocumentType__c,AvailableForExternalUsers__c,Other_Document_Name__c,(SELECT Id,File_Name__c,External_URL__c,Deleted_by_Creator__c FROM External_Files__r WHERE Deleted_by_Creator__c = false)
             FROM Document__c
             WHERE Case__c = :caseId AND RecordTypeId = :recordTypeId]
        );

        system.debug('documentIdvsdoc ==='+docIdvsDoc);
        for(Document__c doc : docIdvsDoc.values()){
            documentWrapper docWrap = new documentWrapper();
            docWrap.doc = doc;
            docWrap.versionCount=0;
            docWrap.contentVersion= new contentVersion();  
            if (doc.External_Files__r != null) {
                docWrap.externalFiles = new List<External_Files__c>(doc.External_Files__r);
            } else {
                docWrap.externalFiles = new List<External_Files__c>();
            }          
            docWrapList.add(docWrap);
        }
       
        map<Id,Id> conDocIdvsLinkedId = new map<Id,Id>();    
        if (!docIdvsDoc.isEmpty()) {
            List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :docIdvsDoc.keyset()];
           
            List<Id> contentDocumentIds = new List<Id>();
            for (ContentDocumentLink link : contentDocumentLinks) {
                contentDocumentIds.add(link.ContentDocumentId);
                conDocIdvsLinkedId.put(link.ContentDocumentId,link.LinkedEntityId);
            }
           
            for(ContentVersion con :[SELECT Id, Title, FileExtension, ContentDocumentId, CreatedDate FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds]){
                for(documentWrapper wrap : docWrapList){
                    if(wrap.doc.Id == conDocIdvsLinkedId.get(con.ContentDocumentId))
                        wrap.contentVersion = con;
                   
                   
                }
            }
            System.debug('docWrapList: ' + docWrapList);
            return docWrapList;
        } else {
            return null;
        }
    }
    public class documentWrapper{
        @AuraEnabled public Document__c doc {get; set;}
        @AuraEnabled public Integer versionCount {get; set;}
        @AuraEnabled public ContentVersion contentVersion {get; set;}
        @AuraEnabled public List<External_Files__c> externalFiles {get; set;}
    }      
   
    /*  @AuraEnabled
    public static void sendEmail(Id documentId, Id caseId, string docType, Id docId){
        try {
        List<ContentVersion> content = [SELECT Id, Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :documentId LIMIT 1];
        system.debug('contents==='+content);
        EmailTemplate template;

        Case caseRecord = [SELECT Id, Licensee_Email__c,Sub_Status__c FROM Case WHERE Id = :caseId];
        system.debug('caseRecord=='+caseRecord);
        if(docType == Label.DM_DocumentTypeTLA){
        template = [SELECT Id, Subject FROM EmailTemplate WHERE DeveloperName =: Label.DM_TLA_SendingTLAandInvoice LIMIT 1];
        }else if(docType == Label.DM_DocumentTypeSignedTLA){
        template = [SELECT Id, Subject FROM EmailTemplate WHERE DeveloperName =: Label.DM_Case_SignedTLANotificationtoCustomer LIMIT 1];
        } else if(docType == Label.DM_DocumentTypeFinalTLA){
        template = [SELECT Id, Subject FROM EmailTemplate WHERE DeveloperName =: Label.DM_Case_SendingFinalTLAtoCustomer LIMIT 1];
        }

        String fromAddress = System.label.DM_OrgWideEmailAddress;
        // Id orgWideAddressId = [SELECT Id FROM OrgWideEmailAddress WHERE Address=:fromAddress LIMIT 1].Id;
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(template.Id, null, caseRecord.Id);
        email.setToAddresses(new String[] { caseRecord.Licensee_Email__c });
        email.setSubject(template.Subject);
        // email.setOrgWideEmailAddressId(orgWideAddressId);
        if(!content.isEmpty())  {
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(content[0].Title +'.pdf');
        attachment.setBody(content[0].VersionData);
        attachment.setContentType('application/pdf');
        attachment.setInline(false);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

        Document__c documentRecord = [SELECT Id, AvailableForExternalUsers__c FROM Document__c WHERE Id = :docId LIMIT 1];
        if(docType == Label.DM_DocumentTypeTLA){
        caseRecord.Status = Label.DM_PendingWIthCustomer;
        caseRecord.Sub_Status__c = Label.DM_SubStatusDraftTLASharingwithCustomer;
        update caseRecord;
        } else if(docType == Label.DM_DocumentTypeFinalTLA){
        caseRecord.Status = Label.DM_StatusTLAIssued;
        caseRecord.Sub_Status__c = Label.DM_SubStatusTLASentToCustomer;
        update caseRecord;

        List<ContentDocumentLink> links = [SELECT Id,Visibility,ShareType,ContentDocumentId  
        FROM ContentDocumentLink
        WHERE ContentDocumentId = : documentId];
        system.debug('contentDocLinks=='+links);
        if (!links.isEmpty()) {
        for (ContentDocumentLink link : links) {
        link.Visibility = 'AllUsers';
        }
        update links;
        system.debug('contentDocLinksVisibility=='+links);
        }
        }
        documentRecord.AvailableForExternalUsers__c = true;
        update documentRecord;
        }
        } catch (DmlException e) {
        System.debug('DML Exception occurred: ' + e.getMessage());
        }
    }*/
    // ==== CHANGE START: Editable email support (generate + send)
   
    @AuraEnabled
    public static Map<String, String> generateEmailContent(Id documentId, Id caseId, String docType) {
        Map<String, String> result = new Map<String, String>();
       
        EmailTemplate template;
        Case caseRecord = [SELECT Id FROM Case WHERE Id = :caseId];
       
        if (docType == Label.DM_DocumentTypeTLA) {
            template = [SELECT Id FROM EmailTemplate WHERE Name = :Label.DM_TLA_SendingTLAandInvoice LIMIT 1];
        } else if (docType == Label.DM_DocumentTypeSignedTLA) {
            template = [SELECT Id FROM EmailTemplate WHERE Name = :Label.DM_Case_SignedTLANotificationtoCustomer LIMIT 1];
        } else if (docType == Label.DM_DocumentTypeFinalTLA) {
            template = [SELECT Id FROM EmailTemplate WHERE Name = :Label.DM_Case_SendingFinalTLAtoCustomer LIMIT 1];
        }
       
        Messaging.SingleEmailMessage draft = Messaging.renderStoredEmailTemplate(template.Id, null, caseRecord.Id);
        result.put('subject', draft.getSubject());
        result.put('body', draft.getHtmlBody());
       
        return result;
    }
   
    @AuraEnabled
    public static void sendEmail(Id documentId, Id caseId, String docType, Id docId, String subject,
                                 String body, String cc, String bcc, String to
                                ) {
                                    try {
                                        List<ContentVersion> content = [
                                            SELECT Id, Title, VersionData
                                            FROM ContentVersion
                                            WHERE ContentDocumentId = :documentId
                                            LIMIT 1
                                        ];
                                       
                                        Case caseRecord = [SELECT Id, Licensee_Email__c, ContactId, Sub_Status__c FROM Case WHERE Id = :caseId];
                                       
                                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                        email.setSubject(subject);
                                        email.setHtmlBody(body);
                                        email.setWhatId(caseRecord.Id); // Logs to Case
                                       
                                        // Use real Contact (if exists) to ensure activity logging
                                        /* if (caseRecord.ContactId != null) {
email.setTargetObjectId(caseRecord.ContactId);
} /*else {
User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];
email.setTargetObjectId(currentUser.Id); // Fallback to User
}*/
                                       
                                        email.setSaveAsActivity(true); //  Show in Activity
                                       
                                        //    email.setToAddresses(new String[] { caseRecord.Licensee_Email__c });
                                        if (String.isNotBlank(to)) {
                                            List<String> toList = new List<String>();
                                            for (String emailAddr : to.split(',')) {
                                                String clean = emailAddr.trim();
                                                if (String.isNotBlank(clean)) {
                                                    toList.add(clean);
                                                }
                                            }
                                            email.setToAddresses(toList);
                                        }
                                       
                                        // Set CC addresses
                                            if (String.isNotBlank(cc)) {
                                                List<String> ccList = new List<String>();
                                                for (String emailAddr : cc.split(',')) {
                                                    String clean = emailAddr.trim();
                                                    if (String.isNotBlank(clean)) {
                                                        ccList.add(clean);
                                                    }
                                                }
                                                email.setCcAddresses(ccList);
                                            }
                                       
                                        // Set BCC addresses
                                        if (String.isNotBlank(bcc)) {
                                            List<String> bccList = new List<String>();
                                            for (String emailAddr : bcc.split(',')) {
                                                String clean = emailAddr.trim();
                                                if (String.isNotBlank(clean)) {
                                                    bccList.add(clean);
                                                }
                                            }
                                            email.setBccAddresses(bccList);
                                        }
                                        // Attach file
                                        if (!content.isEmpty()) {
                                            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                                            attachment.setFileName(content[0].Title + '.pdf');
                                            attachment.setBody(content[0].VersionData);
                                            attachment.setContentType('application/pdf');
                                            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                                        }
                                       
                                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                                       
                                        // Document visibility
                                        Document__c docToUpdate = [SELECT Id FROM Document__c WHERE Id = :docId LIMIT 1];
                                        docToUpdate.AvailableForExternalUsers__c = true;
                                        update docToUpdate;
                                       
                                        // Update Case
                                        if (docType == Label.DM_DocumentTypeTLA) {
                                            caseRecord.Status = Label.DM_PendingWIthCustomer;
                                            caseRecord.Sub_Status__c = Label.DM_SubStatusDraftTLASharingwithCustomer;
                                        } else if (docType == Label.DM_DocumentTypeFinalTLA) {
                                            caseRecord.Status = Label.DM_StatusTLAIssued;
                                            caseRecord.Sub_Status__c = Label.DM_SubStatusTLASentToCustomer;
                                        }
                                       
                                        update caseRecord;
                                       
                                    } catch (Exception e) {
                                        System.debug('SendEmail Error: ' + e.getMessage());
                                    }
                                }
   
    @AuraEnabled
    public static String getLicenseeEmail(String caseId) {
        Case c = [SELECT Licensee_Email__c FROM Case WHERE Id = :caseId LIMIT 1];
        return c.Licensee_Email__c;
    }
   
   
   
   
    // ==== CHANGE END
   
   
    @AuraEnabled
    public static void updateDocumentVisibility(String documentId,String docType,String caseId){
        try {
            ContentDocumentLink link = [SELECT Id,Visibility,ShareType,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :documentId];
            if (link != null) {
                link.Visibility = 'AllUsers';
                update link;
                if(docType == label.DM_DocumentTypeSignedTLA || docType== 'CAS' ){
                    string doctypeVal ;
                    if(docType == label.DM_DocumentTypeSignedTLA)
                        doctypeVal = label.dmTLAdocusignKey;
                    if(docType == 'CAS' )
                        doctypeVal = label.dmCASdocusignKey;
                    ContentVersion cv = [Select Id from ContentVersion where ContentDocumentId =:link.ContentDocumentId AND isLatest=true limit 1];
                    cv.Description =doctypeVal;
                    cv.Title=doctypeVal;
                    update cv;  
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.ContentDocumentId = link.ContentDocumentId;
                    cd.LinkedEntityId = caseId;
                    cd.ShareType = 'V';
                    cd.Visibility = 'AllUsers';
                    insert cd;
                }
               
            }else {
                System.debug('No ContentDocumentLink found for the documentId.');
            }
        } catch (DmlException e) {
            System.debug('An error occurred: ' + e.getMessage());
        }
    }
}