public class HomeFinanceCaseSubmissionInvocable {
    @InvocableMethod(label='Render as PDF and Create Document for Home Finanace Case')
    public static void uploadHomeFinancelTaxInvoiceLetter(List<Id> ids){
        uploadHomeFinancelTaxInvoiceFuture(ids);
    }

    @future(callout=true)
    private static void uploadHomeFinancelTaxInvoiceFuture(List<Id> ids){
        List<Attachment> listPdfAttachments = new List<Attachment>();

        for(Id caseId : ids){
            PageReference pdfPage; 
            pdfPage = new PageReference('/apex/FinanceCaseInvoiceVF');
            pdfPage.getParameters().put('caseId', caseId);
            pdfPage.setRedirect(true);

            Blob pdfBlob = !Test.isRunningTest() ? pdfPage.getContent() : Blob.valueOf('Sample Docus');
            listPdfAttachments.add(new Attachment(
                ParentId = caseId, 
                Name = 'Home Finance Invoice.pdf', 
                body = pdfBlob)
            );
        }
        if(!listPdfAttachments.isEmpty()){
            insert listPdfAttachments;
            Map<Id,Attachment> attachmentMap = new Map<Id,Attachment>();

            for(Attachment eachAtt : listPdfAttachments){
                attachmentMap.put(eachAtt.Id, eachAtt);
            }

            List<String> toRecipents = System.Label.FinanceAfterCaseSubmissionEmail.split(',');
            String emailTemplateDeveloperName = 'FinanceAfterCaseSubmissionEmailTemplate';
            
            // Calling Queueable to sending emails
            if(!attachmentMap.isEmpty() && toRecipents != null && !toRecipents.isEmpty()){
                Integer delayInMinutes = 1;
                System.enqueueJob(new FinanceUtilityToSentEmail(attachmentMap, emailTemplateDeveloperName, toRecipents, null), delayInMinutes);
            }
        }
    }

    public class FinanceUtilityToSentEmail implements Queueable{
        String templateName; 
        List<String> toRecipients; 
        List<String> ccRecipients; 
        Map<Id,Attachment> attachmentMap;

        public FinanceUtilityToSentEmail(Map<Id,Attachment> attachmentMap, String templateName, List<String> toRecipients, List<String> ccRecipients){
            this.templateName = templateName;
            this.attachmentMap = new Map<Id,Attachment>(attachmentMap);
            this.toRecipients = new List<String>(toRecipients);
            this.ccRecipients = new List<String>(ccRecipients);
        }
        
        public void execute(QueueableContext qc){
            List<Messaging.SingleEmailMessage> listEmails = new List<Messaging.SingleEmailMessage>();
            EmailTemplate emailTemplate  = [SELECT Id,Subject,HtmlValue,DeveloperName FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1];
            OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Aldar Home Finance'];
            
            if(emailTemplate != null && owea != null){
                for(Attachment eachAttachment : [SELECT Id, Name, Body, ParentId FROM Attachment WHERE Id IN: attachmentMap.keySet()]){
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(eachAttachment.Name);
                    efa.setBody(eachAttachment.body);
                    efa.setInline(false);
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setFileAttachments( new Messaging.EmailFileAttachment[]{ efa });
                    mail.setToAddresses(toRecipients);
                    mail.setOrgWideEmailAddressId(owea.Id);
                    mail.setTemplateId(emailTemplate.Id);
                    mail.setTargetObjectId([SELECT Id FROM Contact LIMIT 1].Id); // dummuy contact to set What Id
                    mail.setWhatId(eachAttachment.ParentId);
                    mail.setTreatTargetObjectAsRecipient(false);
                     
                    if(ccRecipients != null && !ccRecipients.isEmpty()){
                        mail.setCcAddresses(ccRecipients);
                    }                
                    mail.setSaveAsActivity(false);
                    listEmails.add(mail);
                }
                if(!listEmails.isEmpty()){
                    Messaging.sendEmail(listEmails);
                }
            }
        } 
    }
}