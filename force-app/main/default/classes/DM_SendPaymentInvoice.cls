/**
Class       : DM_SendPaymentInvoice
Author      : Smaartt
Description : this class will be upon user action,so we are considering first record from the list
TestClass   : DM_SendPaymentInvoiceTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              07/08/24           Initial Version 
****************************************************************************************************************/
public class DM_SendPaymentInvoice {
    @InvocableMethod(Label='DMsInvoice pdf' description='Generated and email invoice pdf')    
    public static void sendInvoicepdf(List<Payment_Request__c> paymentRecords) {  
      Payment_Request__c pr = paymentRecords[0];//this is user action it will get always one record 
      /*Record Informatin is not available in vf page immediately so we are processing using future method*/
      sendInvoicepdfHelper(pr.Id,pr.Transaction_No__c); 
        
    }    
    
    
    @future(callout=true)
    public static void sendInvoicepdfHelper(Id recId,String TransactionNo){
        
        PageReference pdf = new PageReference('/apex/DM_Invoice_pdf?id=' +recId + '&transactionNo=' + TransactionNo);
        Blob pdfContent = (Test.isRunningTest()) ? Blob.valueOf('Test PDF') : pdf.getContentAsPDF();
        pdf.setRedirect(true);
        Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
        pdfContent = (Test.isRunningTest()) ? Blob.valueOf('Test') : pdf.getContent();
        att.setFileName(Label.DM_InvoiceFileName+'.pdf');  // ();
        att.setContentType('application/pdf');
        att.setBody(pdfContent);
        att.setInline(false);
        Payment_Request__c pr = [select Id, case__r.casenumber,Case__r.Creator_Email__c,Payment_Type__c,Case__r.Type,Transaction_No__c,Case__c from Payment_Request__c where Id=:recId];
        EmailTemplate templates = [SELECT Id, Body, HtmlValue, Markup, Subject, DeveloperName
                                   FROM EmailTemplate
                                   WHERE DeveloperName =:Label.DM_InvoiceEmailTemplate];
        Id orgWideEmailAddressId = [SELECT Id, Address FROM OrgWideEmailAddress
                                    WHERE DisplayName =: Label.DM_orgWideEmailAdress LIMIT 1].Id;
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templates.Id, null, pr.Case__r.ID);
        email.setToAddresses(new String[] { pr.Case__r.Creator_Email__c });
        email.setOrgWideEmailAddressId(orgWideEmailAddressId);
        email.setSubject(templates.Subject);
        email.setTemplateId(templates.Id);
        email.setSaveAsActivity(false);       
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{att});
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        if (email != null) {
            Map<string,string> CaseRecTypeNames = DM_UtilityController.getCaseRecTypeName(new list<string>{pr.Case__r.ID});
            Document__c invoiceDoc = new Document__c();
            Id recordTypeId = Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(Label.DM_CustomerDocumentRecordType).getRecordTypeId();
            invoiceDoc.RecordTypeId = recordTypeId;
            invoiceDoc.Status__c = Label.DM_DocumentUploaded;
            invoiceDoc.Case__c = pr.Case__r.ID;
            invoiceDoc.Payment_Request__c = pr.ID;
            invoiceDoc.Case_Recordtype__c=CaseRecTypeNames.get(pr.Case__r.ID);
            invoiceDoc.DocumentType__c = Label.DM_DocumentTypeInvoice;
            insert invoiceDoc;
            System.debug('Inserted invoiceDoc: ' + invoiceDoc);
            
            ContentVersion invoiceversion = new ContentVersion();
            invoiceversion.Title =  Label.DM_InvoiceFileName+' '+pr.case__r.casenumber+'.pdf';
            invoiceversion.PathOnClient =  Label.DM_InvoiceFileName+'.pdf';
            invoiceversion.VersionData = pdfContent; 
            insert invoiceversion;
            System.debug('Inserted invoiceversion: ' + invoiceversion);
            
            Id contentDocinvoiceId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :invoiceversion.Id].ContentDocumentId;
            
            ContentDocumentLink invoicecdl = new ContentDocumentLink();
            invoicecdl.ContentDocumentId = contentDocinvoiceId;
            invoicecdl.LinkedEntityId = invoiceDoc.Id; // You can link this to any record
            invoicecdl.ShareType = 'V'; // Inferred permission
            invoicecdl.Visibility = 'AllUsers'; // Visible to all users
            insert invoicecdl;
            
        }
    }
}