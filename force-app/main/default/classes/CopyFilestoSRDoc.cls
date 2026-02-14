/*
Name : CopyFilestoSRDoc
Desc: This class is to create investor certificate from golden Visa.
Author : Rajat
Date : 23-April-2025
*/

public class CopyFilestoSRDoc { 
    public static void copyFilesMethod(String parentDocName, String parentsrType,Set<Id> srIds,String childDocName, String childsrType){
        
        Map<Id, HexaBPM__SR_Doc__c> srMapWithSrDoc = new Map<Id, HexaBPM__SR_Doc__c>();
        
        List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id, HexaBPM__Service_Request__c,HexaBPM__Service_Request__r.HexaBPM__Parent_SR__c, HexaBPM__Service_Request__r.SalesOrder__c,
                                              (select Id,contentdocumentid from AttachedContentDocuments) 
                                              FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c IN: srIds AND HexaBPM__Document_Name__c =:parentDocName
                                              and HexaBPM__Service_Request__r.SRType__c=:parentsrType];
        
        for(HexaBPM__SR_Doc__c srDoc : srDocList) {
            srMapWithSrDoc.put(srDoc.HexaBPM__Service_Request__r.HexaBPM__Parent_SR__c, srDoc);
        }
        
        
        
        List<HexaBPM__SR_Doc__c> docuemntList = [select Id,HexaBPM__Service_Request__r.SalesOrder__c from HexaBPM__SR_Doc__c  WHERE HexaBPM__Service_Request__c IN : srMapWithSrDoc.keySet()
                                                 AND HexaBPM__Document_Name__c =:childDocName and HexaBPM__Service_Request__r.SRType__c=:childsrType];
        
        
        List<ContentDocumentLink> contentDocumentLinkList = new List<contentDocumentLink>();
        for(HexaBPM__SR_Doc__c doc : docuemntList) {      
            //add file which is uploaded Create ContentDocumentLink
            if(srMapWithSrDoc.get(doc.HexaBPM__Service_Request__c).AttachedContentDocuments.size()>0)
            {               
                Id srDocId = srMapWithSrDoc.get(doc.HexaBPM__Service_Request__c).ID;               
                ContentDocumentLink cde = new ContentDocumentLink();
                cde.ContentDocumentId =srMapWithSrDoc.get(doc.HexaBPM__Service_Request__c).AttachedContentDocuments.get(0).contentdocumentid;
                cde.LinkedEntityId = doc.Id;  cde.ShareType = 'I';  cde.Visibility = 'AllUsers';
                contentDocumentLinkList.add(cde);                
            }
        }
        
        
        if(!contentDocumentLinkList.isEmpty()) {
            
            insert contentDocumentLinkList;
        }
        
        if(!srDocList.Isempty() && srDocList[0].AttachedContentDocuments.size()>0 )
        {
            
            List<HexaBPM__Service_Request__c> serviceRequest = [Select Id,HexaBPM__Customer__c,Owner.Email From HexaBPM__Service_Request__c where Id IN: srIds ];
            
            List<string> bccRecipients =new List<string>();
            if(serviceRequest[0].Owner.Email !=null){
                bccRecipients.add(serviceRequest[0].Owner.Email);
            }
            
            string emailTemplateId = Utilities.getEmailtemplateIdByName('Golden_Visa_Invester_Certificate_to_Customer');
            String orgWideEmailAddress = Utilities.getOrgWideEmailAddressIdByName(Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE);
            
            list<Messaging.EmailFileAttachment> attachmentList = new list<Messaging.EmailFileAttachment>();
            
            Contact primaryContact  = [SELECT Id, Email FROM Contact WHERE AccountId =: serviceRequest[0].HexaBPM__Customer__c];
            
            if(primaryContact != null && String.isNotBlank(primaryContact.Email)){ 
                List<String> toAddress = new List<String>();
                toAddress.add(primaryContact.Email);                
                
                ContentVersion cversion = [SELECT title, PathOnClient, FileType, versiondata  FROM contentversion WHERE ContentDocumentId =: srDocList[0].AttachedContentDocuments[0].ContentDocumentId];
                
                blob WOCFbody = cversion.versiondata;
                Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                efa.setFileName(cversion.title+'.'+cversion.FileType);
                efa.setBody(WOCFbody); 
                attachmentList.add(efa);               
                
                
                list<Messaging.SingleEmailMessage> emailsToSend = new list<Messaging.SingleEmailMessage>();
                Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
                tempEmailInstance = Utilities.getEmailInstance(primaryContact.Id,emailTemplateId,serviceRequest[0].Id,null,null,null,null,null,null,attachmentList,orgWideEmailAddress);
                if(bccRecipients != null && !bccRecipients.isEmpty() ){
                    tempEmailInstance.setbccAddresses(bccRecipients);
                    tempEmailInstance.setBccSender(true); 
                }
                tempEmailInstance.setSaveAsActivity(true);
                
                emailsToSend.add(tempEmailInstance);
                try{
                    list<Messaging.SendEmailResult> emailResult  = Messaging.sendEmail(emailsToSend);
                    List<EmailMessage> emailMessages = [SELECT Id, Subject, RelatedToId FROM EmailMessage WHERE RelatedToId = :serviceRequest[0].Id AND EmailTemplate.Name ='Golden Visa Invester Certificate to Customer' ORDER BY CreatedDate DESC LIMIT 1];
                    ContentDocumentLink link = new ContentDocumentLink(
                        ContentDocumentId = srDocList[0].AttachedContentDocuments[0].ContentDocumentId,
                        LinkedEntityId = emailMessages[0].Id,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    );
                    insert link;
                    
                }
                catch(exception ex)
                {
                    system.debug('@@@Error'+ex+'  Line:'+ ex.getLineNumber());
                    
                }                 
            }
            
        }
        
    }
    
}