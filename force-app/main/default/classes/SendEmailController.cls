public class SendEmailController {
    @AuraEnabled
    public static void sendReceiptstoCustomers(String recordId, boolean sendAcknowledgementReceipt, boolean sendAdviceReceipt){
        
        Account primaryRecipients = [select id,isPersonAccount,ResidentStatus__pc,LastModifiedById, FirstName,LastName, PersonEmail,(select id,FirstName,LastName, Email from Contacts where PrimaryContact__c =true) from account where Id in (Select Account__c from Salesorder__c where id=:recordId)];
        List<SalesOrder__c> salesOrderList = [Select Id, Unit__c, Unit__r.Name, Account__r.PersonEmail FROM SalesOrder__c where Id=:recordId ];
        Map<id,Messaging.EmailFileAttachment> unitToAttachmentDetails = new Map<id,Messaging.EmailFileAttachment>();
        String orgWideEmailAddress = '';
        Id fromAddress; //ASF-3364
        String recipientEmail = primaryRecipients.isPersonAccount ? (primaryRecipients.PersonEmail ) : (primaryRecipients.Contacts[0].Email ); // Recipient email
        
        List<String> EmailIds = new List<String> {recipientEmail};
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();   
        
        if(sendAcknowledgementReceipt){
            PageReference pdf = Page.ReceiptAcknowledgementDocument;
            pdf.getParameters().put('id',recordId);
            pdf.setRedirect(true);
            Blob b ;
            if(Test.isRunningTest()) { 
                b = blob.valueOf('Unit.Test');
            } else {
                b = pdf.getContent();
            }
            efa.setBody(b);
        }
        
        if(sendAdviceReceipt){
            PageReference pdf = Page.ReceiptAdviceDocument;
            pdf.getParameters().put('id',recordId);
            pdf.setRedirect(true);
            Blob b ;
            if(Test.isRunningTest()) { 
                b = blob.valueOf('Unit.Test');
            } else {
                b = pdf.getContent();
            }
            efa.setBody(b);  
        }
        
        String fileName = 'Receipt-'+salesOrderList[0].Unit__r.Name+'.pdf';
        efa.setFileName(fileName);
        
       /* for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL limit 1]){
            orgWideEmailAddress=tempRec.Id;
        }*/
        
        //ASF-3364 started
        for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName = 'Aldar Properties' limit 1]){
            orgWideEmailAddress=tempRec.Id;
            fromAddress = tempRec.Id;
        }//ASF-3364 ended
        
        List<EmailTemplate> emailTemplates  = [SELECT DeveloperName,Id FROM EmailTemplate WHERE DeveloperName = 'AldarCustomerReceipt' Limit 1];
        
        Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
        //tempEmailInstance.setTemplateId(emailTemplates[0].Id);
        tempEmailInstance.setToAddresses(EmailIds);
        tempEmailInstance.setOrgWideEmailAddressId(fromAddress); //ASF-3364
       // tempEmailInstance.setReplyTo('agencysupport@aldar.com'); //ASF-3364
        tempEmailInstance.setSubject('Customer Receipt Copy - '+salesOrderList[0].Unit__r.Name);
        
        String emailBodyStr = 'Dear Valuable Customer,</br></br>';
        emailBodyStr += 'Thank you for your investment with Aldar.</br></br>';
        emailBodyStr += 'We hereby acknowledge your payment and receipt has been attached for your reference.</br></br>';
        emailBodyStr += 'Kindly note that issuance of the receipt is subject to payment identification.</br></br>';
        emailBodyStr += 'For support: If you are a UAE based customer and need further assistance, you can reach us at 800-ALDAR (25327). If you are an international customer, you can reach us at +971 2 6725327 or write us at customercare@aldar.com</br></br>';
        emailBodyStr += 'Regards,</br>';
        emailBodyStr += 'Aldar Customer Management';
        tempEmailInstance.setHtmlBody(emailBodyStr);

        
        //tempEmailInstance.setTargetObjectId(primaryRecipients.LastModifiedById);
        tempEmailInstance.setSaveAsActivity(false);
        tempEmailInstance.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {tempEmailInstance});
        
        
    }
    
}