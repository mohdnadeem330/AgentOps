/*** 
Class       : DmCaseInvoiceDoc
Author      : Smaartt
Description : This class contains methods related to vf pages,creation and sending Receipt to the customer
TestClass   : DMCasePdfHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              23/02/24           Initial Version 
****************************************************************************************************************/
public without sharing class DmCaseInvoiceDoc {
    public static void generatePDF(List<Id> paymentRequestIds) {
        String jsonString = JSON.serialize(paymentRequestIds);
        generatePDFAsync(jsonString);
    }

    @future(callout=true)
    public static void generatePDFAsync(String jsonString) {
        // Deserialize the JSON string back to a List of Ids
        List<Id> paymentRequestIds = (List<Id>) JSON.deserialize(jsonString, List<Id>.class);
        if (paymentRequestIds.isEmpty()) {
            return;
        }

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        List<Document__c> documentRecords = new List<Document__c>();
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();

        // Fetch payment requests
        List<Payment_Request__c> paymentRequests = [
            SELECT Id,case__r.casenumber, Case__r.Creator_Email__c,Case__c, Payment_Type__c, Case__r.Licensee_Email__c, Case__r.Type, Transaction_No__c 
            FROM Payment_Request__c 
            WHERE Id IN :paymentRequestIds];
        Id orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = :Label.DM_orgWideEmailAdress LIMIT 1].Id;
        String emailTemplateName = (paymentRequests[0].Payment_Type__c == Label.DM_WireTransfer) 
                                    ? Label.Case_DM_WireTransferInvoicePdf_EmailTemplate 
                                    : Label.DM_InvoicePdf_EmailTemplate;

        EmailTemplate templates = [SELECT Id, Subject, DeveloperName FROM EmailTemplate WHERE DeveloperName = :emailTemplateName LIMIT 1];
        list<string> CaseIds = new list<string>();
        for(Payment_Request__c pr : paymentRequests){
            CaseIds.add(pr.Case__c);
        }
        Map<string,string> CaseRecTypeNames = DM_UtilityController.getCaseRecTypeName(CaseIds);
        for (Payment_Request__c pr : paymentRequests) {
            // Create PDF
            PageReference pdf = new PageReference('/apex/DM_Receipt_pdf?id=' + pr.Id + '&transactionNo=' + pr.Transaction_No__c);
            Blob pdfContent = (Test.isRunningTest()) ? Blob.valueOf('Test PDF') : pdf.getContentAsPDF();
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templates.Id, null, pr.Id);
            String toAddress = (pr.Case__r.Type == 'Temporary License Agreement') ? pr.Case__r.Licensee_Email__c : pr.Case__r.Creator_Email__c;
            email.setToAddresses(new String[]{toAddress});
            email.setOrgWideEmailAddressId(orgWideEmailAddressId);
            email.setSubject(templates.Subject);
            email.setSaveAsActivity(false);
            
            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.setFileName(Label.DM_ReceiptFileName);
            att.setContentType('application/pdf');
            att.setBody(pdfContent);
            att.setInline(false);
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{att});
            emailMessages.add(email);
            
            Document__c invoiceDoc = new Document__c();
            Id recordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
            invoiceDoc.RecordTypeId = recordTypeId;
            invoiceDoc.Status__c = Label.DM_DocumentUploaded;
            invoiceDoc.Case__c = pr.Case__c;
            invoiceDoc.Case_Recordtype__c=CaseRecTypeNames.get(pr.Case__c);
            invoiceDoc.DocumentType__c = Label.DM_DocumentTypeReceipt;
            invoiceDoc.Payment_Request__c = pr.Id;
            documentRecords.add(invoiceDoc);

            ContentVersion invoiceVersion = new ContentVersion();
            invoiceVersion.Title = Label.DM_ReceiptFileName+' '+pr.case__r.casenumber+'.pdf';
            invoiceVersion.PathOnClient = Label.DM_ReceiptFileName+'.pdf';
            invoiceVersion.VersionData = pdfContent;
            contentVersions.add(invoiceVersion);
        }

        if (!emailMessages.isEmpty()) {
            try {
                Messaging.sendEmail(emailMessages);
            } catch (Exception e) {
                System.debug('Email sending failed: ' + e.getMessage());
            }
        }

        if (!documentRecords.isEmpty()) {
            insert documentRecords;
            System.debug('Inserted documentRecords: ' + documentRecords);
        }

        if (!contentVersions.isEmpty()) {
            insert contentVersions;
            System.debug('Inserted contentVersions: ' + contentVersions);
        }

        // Link ContentVersion to Document__c
        for (ContentVersion invoiceVersion : contentVersions) {
            Id contentDocInvoiceId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :invoiceVersion.Id].ContentDocumentId;

            for (Document__c doc : documentRecords) {
                ContentDocumentLink invoiceLink = new ContentDocumentLink();
                invoiceLink.ContentDocumentId = contentDocInvoiceId;
                invoiceLink.LinkedEntityId = doc.Id;
                invoiceLink.ShareType = 'V';
                invoiceLink.Visibility = 'AllUsers';
                documentLinks.add(invoiceLink);
            }
        }

        // Insert all ContentDocumentLink records
        if (!documentLinks.isEmpty()) {
            insert documentLinks;
            System.debug('Inserted documentLinks: ' + documentLinks);
        }
    }
}