/**********************************************************************************************************************
* Name               : CC_RTORenewal                                                        
* Description        : This class is used by CC_RTORenewal process
* Usage              : Handover 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022      Initial Draft       
******************************************************************************************************************/
global without sharing class CC_RTORenewal implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_RTORenewal: Invalid SR or SR Step';
            }else{
                HexaBPM__Service_Request__c sRRecord = [SELECT Id,HexaBPM__Customer__r.isPersonAccount,HexaBPM__Customer__r.PersonContactId,HexaBPM__Contact__c,InstallmentLine__c, ChargeType__c, ChargeCollected__c, SettleViaEmployer__c,SalesOrder__c , SalesOrder__r.Opportunity__C ,SalesOrder__r.Account__C,HexaBPM__Customer__r.PersonEmail  FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                HexaBPM__Step__c stepRecord = [select id,HexaBPM__Step_Status__c,Step_Template_Code__c from HexaBPM__Step__c where id = :stp.Id limit 1];
                
                
                string emailTemplateId = '';
                string emailTemplateLeadId = '';
                string relatedCustomerId = '';
                string orgWideEmailAddress = '';
                boolean triggerEmail = False;
                List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
                List<String> ccAddress = new List<String>();
                for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE limit 1]){
                    orgWideEmailAddress=tempRec.Id;
                }
                
                if(stepRecord.Step_Template_Code__c == Constants.STEPNAME_VERIFY_DETAILS){
                    //check the details are updated
                    if(sRRecord.SettleViaEmployer__c == null || sRRecord.ChargeCollected__c == null || sRRecord.InstallmentLine__c == null){
                        result = 'Please populate Settle Via Employer, Charge to be Collected, upcoming RTO instalment fields';
                    }else if(sRRecord.SettleViaEmployer__c =='Yes'){list<HexaBPM__SR_Doc__c> srDocs = [select id, DocumentMasterCode__c,HexaBPM__Status__c from HexaBPM__SR_Doc__c where HexaBPM__Status__c = 'Pending Upload' and HexaBPM__Service_Request__c = :sRRecord.Id and DocumentMasterCode__c = 'Housing Allowance Letter'];
                        if(!srDocs.isEmpty()){result = 'Please upload Housing Allowance Letter';}
                    }
                }else if(stepRecord.Step_Template_Code__c == Constants.STEPNAME_UPLOAD_SIGNED_CONTRACT){
                    if(sRRecord.ChargeCollected__c !=0){
                        if(sRRecord.ChargeType__c ==null){
                            result = 'Please Charge Type field';
                        }else{
                            SalesOrderOtherCharges__c soOtherCHarges = new SalesOrderOtherCharges__c(Amount__c = sRRecord.ChargeCollected__c.setScale(2),TypeOfCharge__c = sRRecord.ChargeType__c, Opportunity__c=sRRecord.SalesOrder__r.Opportunity__c , Account__c=sRRecord.SalesOrder__r.Account__c ,SalesOrder__c =sRRecord.SalesOrder__c);
                            insert soOtherCHarges;
                        }
                    }
                    for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = 'TawtheeqRegistrationInternal' limit 1]){
                        emailTemplateLeadId=tempRec.Id;
                    }
                    for(string tempEmail : System.label.RenewalTawtheeqTeam.split(',')){
                        ccAddress.add(tempEmail);
                    }
                    triggerEmail = true;
                }else if(stepRecord.Step_Template_Code__c == Constants.STEPNAME_TAWTHEEQ_REGISTRATION){
                    //activate new tenancy year
                    update new InstallmentLines__c (id = sRRecord.InstallmentLine__c, RTORenewed__c = true);
                    for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = 'RTORenewalCompletion' limit 1]){emailTemplateLeadId=tempRec.Id;
                    }
                    triggerEmail = true;
                }
                
                //Send Email
                if(triggerEmail){
                    map<id,id> docToCVId = new  map<id,id>();
                    for(HexaBPM__SR_Doc__c tempSRDOC : [select id from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c = :sRRecord.Id and DocumentMasterCode__c in (:Constants.DOCNAME_TAWTHEEQ_LETTER ,:Constants.DOCNAME_SIGNED_LEASING_LETTER ,:Constants.DOCNAME_SIGNED_TENANCY_AGREEMENT )]){ docToCVId.put(tempSRDOC.id,null);
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
                    emailToSend.add(Utilities.getEmailInstance( (sRRecord.HexaBPM__Customer__r.isPersonAccount ?  sRRecord.HexaBPM__Customer__r.PersonContactId : sRRecord.HexaBPM__Contact__c ) ,emailTemplateLeadId,sRRecord.Id,new list<String>{sRRecord.HexaBPM__Customer__r.PersonEmail},null,ccAddress,null,null,null,fileAttachments,orgWideEmailAddress));
                    if(!emailToSend.isEmpty()){
                        Utilities.sendEmail(emailToSend);
                    }
                }
                
            } 
        } catch(Exception e){ result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_RTORenewal';
        }
        return result;
    }
}