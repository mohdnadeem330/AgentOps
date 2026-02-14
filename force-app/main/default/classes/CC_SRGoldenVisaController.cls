/*
* Purpose: Sending email with Golden Visa DOcument
* SR Type: Golden Visa
*/
global without sharing class CC_SRGoldenVisaController implements HexaBPM.iCustomCodeExecutable{
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        string emailTemplateId = Utilities.getEmailtemplateIdByName('Golden_Visa_Prior_to_closing_the_SR_upon_receiving_the_GV_Emirates_ID');
        String orgWideEmailAddress = Utilities.getOrgWideEmailAddressIdByName(Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE);
        
        list<Messaging.EmailFileAttachment> attachmentList = new list<Messaging.EmailFileAttachment>();
        
        Contact primaryContact  = [SELECT Id, Email FROM Contact WHERE AccountId =: serviceRequest.HexaBPM__Customer__c];
        
        if(primaryContact.Email != null && String.isNotBlank(primaryContact.Email)){
            List<String> toAddress = new List<String>();
            toAddress.add(primaryContact.Email);
            System.debug('toAddress '+toAddress);
            
            List<id> ContentDocumentids = new List<id>();
            
            HexaBPM__SR_Doc__c goldenVisa = [SELECT Id FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c=: serviceRequest.Id AND Name = 'Golden Visa Copy'];
            
            List<ContentDocumentLink> CDLink = [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid=: goldenVisa.Id];
            if(CDLink.Size() > 0){            
                ContentVersion cversion = [SELECT title, PathOnClient, FileType, versiondata  FROM contentversion WHERE ContentDocumentId =: CDLink[0].ContentDocumentid];
                
                blob WOCFbody = cversion.versiondata;
                Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                efa.setFileName(cversion.title+'.'+cversion.FileType);
                efa.setBody(WOCFbody); 
                attachmentList.add(efa);
                
                list<Messaging.SingleEmailMessage> emailsToSend = new list<Messaging.SingleEmailMessage>();
                Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
                tempEmailInstance = Utilities.getEmailInstance(primaryContact.Id,emailTemplateId,serviceRequest.Id,toAddress,null,null,null,null,null,attachmentList,orgWideEmailAddress);
                tempEmailInstance.setSaveAsActivity(true);
                emailsToSend.add(tempEmailInstance);
                list<Messaging.SendEmailResult> emailResult  = Utilities.sendEmail(emailsToSend);
                
            }else
            return Utilities.getSystemMessages(Constants.REQUIRED_DOCUMENT_NEED_TO_UPLOAD).Message__c;
        }
        else
            return Utilities.getSystemMessages(Constants.CUSTOMER_EMAIL_NOT_AVAILABLE).Message__c;
        
        return Constants.SUCCESS_RETURN_MESSAGE;
        
    }
}