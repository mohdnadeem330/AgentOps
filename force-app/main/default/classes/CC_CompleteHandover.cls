/**********************************************************************************************************************
* Name               : CC_CompleteHandover                                                        
* Description        : This class is used by Handover Process to update required fields on process clouser
* Usage              : Handover + Title Deed Process SR PRocess
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022      Initial Draft       
******************************************************************************************************************/
global without sharing class CC_CompleteHandover implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{
            
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_CompleteHandover: Invalid SR or SR Step';
            }else{
                list<String> pendingDocList = new list<String>();
                HexaBPM__Service_Request__c sRRecord = [SELECT Id,SalesOrder__c,Unit__C,HandoverDetail__r.OutstandingAmount__c,HAndoverDetail__c,HexaBPM__Contact__c,HexaBPM__Customer__c,HexaBPM__Customer__r.PersonEmail,HexaBPM__Customer__r.PersonContactId,HexaBPM__Customer__r.isPersonAccount,HexaBPM__Customer__r.Email__c,SalesOrder__r.RTOConverted__c,Unit__r.UnitType__c  FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                for(HexaBPM__SR_Doc__c pendingDocs : [select id,DocumentMasterCode__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c = : stp.HexaBPM__SR__c and DocumentMasterCode__c in (:Constants.DOC_SIGNED_KEY_FORM , :Constants.DOC_SIGNED_NOC, :Constants.DOC_SIGNED_DECLARATIONOFADHERENCE ) and HexaBPM__Status__c != :Constants.DOCUMENT_STATUS_UPLOADED ]){
                    pendingDocList.add(pendingDocs.DocumentMasterCode__c);
                }
                /*if(!pendingDocList.isEmpty()){ return 'Please upload required '+  string.join(pendingDocList,',')+' document(s)';
}*/
                if(sRRecord.HandoverDetail__r.OutstandingAmount__c !=null && sRRecord.HandoverDetail__r.OutstandingAmount__c > 100){ return 'Please note, the payment needs to be settled before the Handover closure';
                                                                                                                                   }
                
                //Send Email
                string emailTemplateId = '';
                string emailTemplateLeadId = '';
                string relatedCustomerId = '';
                string orgWideEmailAddress = '';
                for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = 'KeyHandover' limit 1]){
                    emailTemplateLeadId=tempRec.Id;
                }
                List<String> ccAddress = new List<String>();
                map<id,set<String>> soToJointOwnerMap = DefaultAndTerminationUtility.getOwnerEmailList(new set<ID>{sRRecord.SalesOrder__c});
                if(soToJointOwnerMap.containsKey(sRRecord.SalesOrder__c) && !soToJointOwnerMap.get(sRRecord.SalesOrder__c).isEmpty()){
                    ccAddress.addAll(soToJointOwnerMap.get(sRRecord.SalesOrder__c));
                }
                for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE limit 1]){
                    orgWideEmailAddress=tempRec.Id;
                }
                List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
                //ATTACHMENT CODEGet placeholder
                
                map<id,id> docToCVId = new  map<id,id>();
                for(HexaBPM__SR_Doc__c tempSRDOC : [select id from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c = :sRRecord.Id and DocumentMasterCode__c in (:Constants.DOC_SIGNED_KEY_RECEIPT,:Constants.DOC_SIGNED_DECLARATIONOFADHERENCE)]){ docToCVId.put(tempSRDOC.id,null);
                                                                                                                                                                                                                                                      }
                //Query Content document link 
                if(!docToCVId.isEmpty()){
                    for(contentDocumentLink CDLink : [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid in :docToCVId.keySet() order by systemmodstamp desc ]){  docToCVId.put(CDLink.LinkedEntityid,CDLink.ContentDocumentid);
                                                                                                                                                                                                   }
                    //Query COntent version
                    for ( ContentVersion cversion : [SELECT title, FileType,versiondata FROM contentversion WHERE ContentDocumentId IN :docToCVId.values()  ]){
                        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                        efa.setFileName(cversion.title+'.'+cversion.FileType);
                        efa.setBody(cversion.versiondata);
                        fileAttachments.ADD(efa);
                    }
                }
                
                
                list<Messaging.SingleEmailMessage> emailToSend = new list<Messaging.SingleEmailMessage>();
                list<String> emailIds=new list<String>();
                if(sRRecord.HexaBPM__Customer__r.isPersonAccount){
                    emailIds.add(sRRecord.HexaBPM__Customer__r.PersonEmail);
                }else if(sRRecord.HexaBPM__Contact__c!=null){
                    List<Contact> conList= [select Id,Email from Contact where Id =:sRRecord.HexaBPM__Contact__c];
                    if(!conList.isEmpty()){
                        emailIds.add(conList.get(0).Email);
                    }
                }else if(sRRecord.HexaBPM__Customer__r.Email__c!=null && emailIds.isEmpty()){
                    emailIds.add(sRRecord.HexaBPM__Customer__r.Email__c);  
                }
                
                emailToSend.add(Utilities.getEmailInstance( (sRRecord.HexaBPM__Customer__r.isPersonAccount ?  sRRecord.HexaBPM__Customer__r.PersonContactId : sRRecord.HexaBPM__Contact__c !=null ?sRRecord.HexaBPM__Contact__c:sRRecord.HexaBPM__Customer__C) ,emailTemplateLeadId,sRRecord.Id,emailIds,null,ccAddress,null,null,null,fileAttachments,orgWideEmailAddress));
                if(!emailToSend.isEmpty()){
                    // Utilities.sendEmail(emailToSend);
                }
                //Send CUstomer Survey
                HandoverUtility.populateSRCloseDate(new set<ID>{sRRecord.Id});
                // Added by tejaswini Jira - SSR-590
                //Create Case For Onbording Handover queue
                Group Onbordingqueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Onboarding_Handover' ORDER BY CreatedDate DESC ];
                if(String.isNotBlank( sRRecord.Unit__c)&& sRRecord.Unit__r.UnitType__c != 'Plot' && (sRRecord.SalesOrder__r.RTOConverted__c == null || sRRecord.SalesOrder__r.RTOConverted__c == false)){
                    Case caseRec = new Case();
                    caseRec.Status = 'New';
                    caseRec.Subject = 'Key handover Feedback';
                    caseRec.Priority = 'Medium';   
                    caserec.OwnerId= Onbordingqueue.Id;
                    caseRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('FeedbackCase').getRecordTypeId();
                    caseRec.CaseComments__c = 'key handover feedback';
                    caseRec.CustomerType__c = 'Owner';
                    caseRec.Origin = 'Phone';
                    // caseRec.SubVertical__c = 'Survey Feedback';
                    caseRec.SubVertical__c = ' Customer Onboarding handover';
                    caseRec.SubCategory__c ='Customer Onboarding handover';
                    caseRec.CaseCategory__c = 'Customer Onboarding'; 
                    caseRec.ServiceRequest__c =sRRecord.Id;
                    caseRec.Vertical__c = 'Customer Management';
                    caseRec.Unit__c = sRRecord.Unit__c;
                    
                    if(sRRecord.SalesOrder__c !=null){
                        caseRec.SalesOrder__c = sRRecord.SalesOrder__c;
                    }
                    if(sRRecord.HexaBPM__Customer__c !=null){
                        caseRec.AccountId = sRRecord.HexaBPM__Customer__c;
                    }
                    insert caseRec; 
                    
                }
                // End 590                
            }
            
        }
        catch(Exception e){ result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_CompleteHandover';
                          }
        return result;
    }
}