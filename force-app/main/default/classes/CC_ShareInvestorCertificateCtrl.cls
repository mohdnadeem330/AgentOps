/*
Name : CC_ShareInvestorCertificateCtrl
Desc: This class is to create investor certificate from golden Visa.
Author : Rajat
Date : 23-April-2025
*/
global without sharing class CC_ShareInvestorCertificateCtrl implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c ServiceReqObj, HexaBPM__Step__c stp){
        try{
            string result ='Success';
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_ShareInvestorCertificateCtrl: Invalid SR or SR Step';
            }else{
                List<HexaBPM__Service_Request__c> serviceRequest =  [select Id,Is_Golden_Visa_Investor_Certificate__c,HexaBPM__Customer__c,Owner.Email,UnitName__c from HexaBPM__Service_Request__c where Id=:stp.HexaBPM__SR__c];
                
                List<string> bccRecipients =new List<string>();
                if(serviceRequest[0].Owner.Email !=null){bccRecipients.add(serviceRequest[0].Owner.Email);
                } 
                
                if(stp.HexaBPM__Summary__c == 'Share Investor Certificate with Customer' && serviceRequest[0].Is_Golden_Visa_Investor_Certificate__c){                  
                     
                    
                    CopyFilestoSRDoc.copyFilesMethod('Signed Golden Investor Certificate','Investor Certificate',new Set<Id>{stp.HexaBPM__SR__c},'Investor Certificate','Golden Visa');
                }
                else if (stp.HexaBPM__Summary__c == 'Share Investor Certificate with Customer' && !serviceRequest[0].Is_Golden_Visa_Investor_Certificate__c)
                {
                     
                    List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id, HexaBPM__Service_Request__c,HexaBPM__Service_Request__r.HexaBPM__Parent_SR__c, HexaBPM__Service_Request__r.SalesOrder__c,
                                                          (select Id,contentdocumentid from AttachedContentDocuments) 
                                                          FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =:serviceRequest[0].Id AND HexaBPM__Document_Name__c ='Signed Investor Certificate'
                                                          and HexaBPM__Service_Request__r.SRType__c='Investor Certificate'];
                    if(srDocList[0].AttachedContentDocuments.size()>0 )
                    {
                        list<Messaging.EmailFileAttachment> attachmentList = new list<Messaging.EmailFileAttachment>();
                        Contact primaryContact  = [SELECT Id, Email FROM Contact WHERE AccountId =: serviceRequest[0].HexaBPM__Customer__c];
                        string emailTemplateId = Utilities.getEmailtemplateIdByName('Golden_Visa_Invester_Certificate_to_Customer');
                        String orgWideEmailAddress = Utilities.getOrgWideEmailAddressIdByName(Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE);
                        if(primaryContact != null && String.isNotBlank(primaryContact.Email)){
                            List<String> toAddress = new List<String>();
                            toAddress.add(primaryContact.Email);
                            System.debug('toAddress '+toAddress);
                            
                            
                            ContentVersion cversion = [SELECT title, PathOnClient, FileType, versiondata  FROM contentversion WHERE ContentDocumentId =: srDocList[0].AttachedContentDocuments[0].ContentDocumentId];
                            
                            blob WOCFbody = cversion.versiondata;
                            Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                            efa.setFileName(cversion.title+'.'+cversion.FileType);
                            efa.setBody(WOCFbody); 
                            attachmentList.add(efa);
                            
                            list<Messaging.SingleEmailMessage> emailsToSend = new list<Messaging.SingleEmailMessage>();
                            Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
                            //  tempEmailInstance = Utilities.getEmailInstance(primaryContact.Id,emailTemplateId,serviceRequest[0].Id,toAddress,null,null,null,null,null,attachmentList,orgWideEmailAddress);
                            tempEmailInstance = Utilities.getEmailInstance(primaryContact.Id,emailTemplateId,serviceRequest[0].Id,null,null,null,null,null,null,attachmentList,orgWideEmailAddress);
                            if(bccRecipients != null && !bccRecipients.isEmpty() ){
                                tempEmailInstance.setbccAddresses(bccRecipients);tempEmailInstance.setBccSender(true);  
                            }                            
                            tempEmailInstance.setSaveAsActivity(true);
                            
                            emailsToSend.add(tempEmailInstance);     
                            system.debug('@@@emailsToSend'+emailsToSend);
                            list<Messaging.SendEmailResult> emailResult  = Messaging.sendEmail(emailsToSend);
                            System.debug('@@@emailResult'+emailResult);
                            //String subjectLine = emailResult[0].Subject;
                            List<EmailMessage> emailMessages = [SELECT Id, Subject, RelatedToId FROM EmailMessage WHERE RelatedToId = :serviceRequest[0].Id AND EmailTemplate.Name ='Golden Visa Invester Certificate to Customer'  ORDER BY CreatedDate DESC LIMIT 1];
              
                            ContentDocumentLink link = new ContentDocumentLink(ContentDocumentId = srDocList[0].AttachedContentDocuments[0].ContentDocumentId,LinkedEntityId = emailMessages[0].Id,ShareType = 'V',Visibility = 'AllUsers');
                            insert link;                            
                            return result;
                        }                        
                        return result;
                    }
                }
                return null;
            }
        }catch(Exception ex){           
            return ex.getMessage()+'  Line:'+ex.getLineNumber()+' :CC_ShareInvestorCertificateCtrl';
        }
        return null;
    }
    
}