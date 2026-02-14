/***
Class       : DMCaseDocuments
Author      : Smaartt
Description : This class contains all the methods related to sending documents to customer and saving it
into the documents
TestClass   : DMCaseDocumentsTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              06/05/24           Initial Version 
****************************************************************************************************************/
public without sharing class DMCaseDocuments {
    @InvocableMethod(Label ='Email Noc pdf' description='Generated and email NOC pdf')
    public static void generatePDF(List<Case> caseRec) {
        String caseJson = JSON.serialize(caseRec);
        callVFPage(caseJson);
    }
    
    @future(callout=true)
    public static void callVFPage(String caseJson) {
        System.debug('inside future method');     
        List<Case> caseRec = (List<Case>) JSON.deserialize(caseJson, List<Case>.class);
        OrgWideEmailAddress orgWideEmailAddress = [SELECT Id 
                                                   FROM OrgWideEmailAddress 
                                                   WHERE DisplayName =: Label.DM_orgWideEmailAdress 
                                                   LIMIT 1];
        Id orgWideEmailAddressId = orgWideEmailAddress.Id;  
        Map<String, EmailTemplate> templateMap = getEmailTemplates();
        Set<Id> caseIds = new Set<Id>();
        list<string> tempCaseids = new list<string>();//utility helper method accepts only list of strings
        for (Case caseRecord : caseRec) {
            caseIds.add(caseRecord.Id);
            tempCaseids.add(caseRecord.Id);
        }
        Map<string,string> CaseRecTypeNames = DM_UtilityController.getCaseRecTypeName(tempCaseids);
        Map<Id, Payment_Request__c> paymentRequestMap = new Map<Id, Payment_Request__c>();
        for (Payment_Request__c pr : [SELECT Id, Case__c FROM Payment_Request__c WHERE Case__c IN :caseIds]) {
            paymentRequestMap.put(pr.Case__c, pr);
        }
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Case> casesToUpdate = new List<Case>(); 
        List<Document__c> docsToInsert = new List<Document__c>();
        for (Case caseRecord : caseRec) {
            EmailTemplate emailTemplate;
            string pdfType;
            Messaging.SingleEmailMessage email;
            if (caseRecord.Type == Label.DM_NOCType) {
                emailTemplate = templateMap.get(Label.DM_NOCPdf_EmailTemplate);
                pdfType = 'DM_NOC_Pdf';
            } else if (caseRecord.Type == Label.DM_PTWType) {
                emailTemplate = templateMap.get(Label.DM_PTWPdf_EmailTemplate);
                pdfType = 'DM_PemitToWork_Pdf';
            } else {
                continue; 
            }            
            List<String> ccAddresses = DM_UtilityController.getEmailAddresses(caseRecord);
            email = createEmailMessage(caseRecord, emailTemplate, pdfType, orgWideEmailAddressId, ccAddresses);
            if (email != null) {
                emailsToSend.add(email);
                caseRecord.Status = Label.DM_CompletedStatus;
                caseRecord.Sub_Status__c =  Label.DM_CompletedSubStatus;
                casesToUpdate.add(caseRecord);             
                Payment_Request__c paymentRequest = paymentRequestMap.get(caseRecord.Id);
                Document__c docType = new Document__c();
                docType.RecordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
                docType.Status__c = Label.DM_DocumentUploaded;
                docType.DocumentType__c = caseRecord.Type;
                docType.Case_Recordtype__c= CaseRecTypeNames.get(caseRecord.Id);
                docType.Case__c = caseRecord.Id;
                docType.Account__c = caseRecord.AccountId;
                docType.AvailableForExternalUsers__c = true;
                
                if (paymentRequest != null) {
                    docType.Payment_Request__c = paymentRequest.id;
                }
                docsToInsert.add(docType);
                
            }
        }
        if(!docsToInsert.isEmpty()){
            insert docsToInsert;
            List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
            Map<Id, Id> versionIdMap = new Map<Id, Id>();
            for (Document__c doc : docsToInsert) {
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = doc.DocumentType__c + '.pdf';
                contentVersion.PathOnClient = doc.DocumentType__c + '.pdf';
                
                PageReference pdfPage;
                if (doc.DocumentType__c.equalsIgnoreCase(Label.DM_DocumentTypeNOC)) {
                    pdfPage = new PageReference('/apex/DM_NOC_Pdf?id=' + doc.Case__c);
                } else if (doc.DocumentType__c.equalsIgnoreCase(Label.DM_DocumentTypePTW)) {
                    pdfPage = new PageReference('/apex/DM_PemitToWork_Pdf?id=' + doc.Case__c);
                } else {
                    continue;
                }
                
                Blob pdfContent = (Test.isRunningTest()) ? Blob.valueOf('Test') : pdfPage.getContentAsPDF();
                contentVersion.VersionData = pdfContent;
                contentVersionsToInsert.add(contentVersion);
            }
            if(!contentVersionsToInsert.isEmpty()){
                insert contentVersionsToInsert;
            }
            for (ContentVersion version : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionsToInsert]) {
            	versionIdMap.put(version.Id, version.ContentDocumentId);
            }
            List<ContentDocumentLink> contentLinksToInsert = new List<ContentDocumentLink>();
            
            for (ContentVersion version : contentVersionsToInsert) {
                ContentDocumentLink contentLink = new ContentDocumentLink();
                contentLink.ContentDocumentId = versionIdMap.get(version.Id);
                Document__c linkedDoc = docsToInsert[contentVersionsToInsert.indexOf(version)];
                contentLink.LinkedEntityId = linkedDoc.Id;
                contentLink.ShareType = 'V'; // Visible to all users with access to the record
                contentLink.Visibility = 'AllUsers';
                contentLinksToInsert.add(contentLink);
        	}
            if(!contentLinksToInsert.isEmpty()){
                insert contentLinksToInsert;
            }
            
        }
        
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }
    
    private static Messaging.SingleEmailMessage createEmailMessage(Case caseRecord, EmailTemplate template, string pdfType, Id orgWideEmailAddressId, List<String> ccAddresses) {
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(template.Id, null, caseRecord.Id);
        email.setToAddresses(new String[] { caseRecord.Creator_Email__c });
        email.setOrgWideEmailAddressId(orgWideEmailAddressId);
        email.setSubject(template.Subject);
        email.setTemplateId(template.Id);
        email.setSaveAsActivity(false);  
        
        // Set CC Addresses from the helper method
        if (!ccAddresses.isEmpty()) {
            email.setCcAddresses(ccAddresses);
        }
        List<Messaging.EmailFileAttachment> attachments = createAttachments(caseRecord, pdfType);
        if (!attachments.isEmpty()) {
            email.setFileAttachments(attachments);
        }
        return email;
    }
    
    private static List<Messaging.EmailFileAttachment> createAttachments(Case caseRecord, string pdfType) {
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        
        Messaging.EmailFileAttachment mainAttachment = createAttachment('/apex/' + pdfType + '?id=' + caseRecord.Id, caseRecord.Type + '.pdf');
        if (mainAttachment != null) {
            attachments.add(mainAttachment);
        }
        return attachments;
    }
    
    public static Messaging.EmailFileAttachment createAttachment(String pageRef, String fileName) {
        PageReference pdfRef = new PageReference(pageRef);
        Blob pdfContent = (Test.isRunningTest()) ? Blob.valueOf('Test PDF') : pdfRef.getContentAsPDF();
        if (pdfContent != null) {
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setContentType('application/pdf');
            attachment.setFileName(fileName);
            attachment.setBody(pdfContent);
            attachment.setInline(false);
            return attachment;
        }
        return null;
    }
    
    private static Map<String, EmailTemplate> getEmailTemplates() {
        String ptwPdfTemplate = Label.DM_PTWPdf_EmailTemplate;
        String nocPdfTemplate = Label.DM_NOCPdf_EmailTemplate;
        
        Map<String, EmailTemplate> templateMap = new Map<String, EmailTemplate>();
        List<EmailTemplate> templates = [SELECT Id, Body, HtmlValue, Markup, Subject, DeveloperName
                                         FROM EmailTemplate
                                         WHERE DeveloperName IN (:ptwPdfTemplate, :nocPdfTemplate)];
        for (EmailTemplate temp : templates) {
            templateMap.put(temp.DeveloperName, temp);
        }
        return templateMap;
    }  
   
}