public with sharing class SendEmailasAttachment {
    
    @InvocableMethod(label ='Send Formal Demand Letter') 
    public static void  SendFormalDemand(List<String> srId) {
        sendAttachment(srId,'DT_Customer_Notification_Nintex','Formal Demand Letter' );
    }
    public static void sendAttachment(List<String> srId, String DeveloperName, String DocumentMasterCode){
        System.debug('sendAttachment'+srId);
        HexaBPM__Service_Request__c sRRecord = [SELECT Id,Owner.Email,InstallmentLine__r.UnitName__c,SalesOrder__c,HexaBPM__Contact__c,HexaBPM__Customer__c,SalesOrder__r.Contact__r.Email,HexaBPM__Customer__r.PersonEmail,HexaBPM__Customer__r.PersonContactId,HexaBPM__Customer__r.isPersonAccount,HexaBPM__Customer__r.Email__c, SalesOrder__r.Account__r.PersonEmail,InstallmentLine__c,Unit__r.Name FROM HexaBPM__Service_Request__c WHERE id IN: srId  limit 1];
        HexaBPM__SR_Doc__c srDocOBJ = [SELECT Id FROM  HexaBPM__SR_Doc__c WHERE Name ='Formal Demand Letter' AND HexaBPM__Service_Request__c =: sRRecord.Id LIMIT 1];
        string emailTemplateId = '';
        string emailTemplateLeadId = '';
        string relatedCustomerId = '';
        string orgWideEmailAddress = '';
        List<String> ccAddress = new List<String>();
        list<String> emailIds=new list<String>();
        if(sRRecord.Owner.Email <> null){
            ccAddress.add(sRRecord.Owner.Email);
        }
        for(Emailtemplate tempRec:  [select id,subject, DeveloperName from emailtemplate where DeveloperName = :DeveloperName limit 1]){
            emailTemplateLeadId=tempRec.Id;
        }
        map<id,Handoverdetails__c> hoDetailMap = new map<id,Handoverdetails__c>();
        for(Handoverdetails__c hoRec : [SELECT id,LastInstallment__c,KAR__c,KAR__r.Email FROM Handoverdetails__c WHERE KAR__c!=null and LastInstallment__c =: sRRecord.InstallmentLine__c]){
            hoDetailMap.put(hoRec.LastInstallment__c,hoRec);
        }
        if(hoDetailMap.containskey(sRRecord.Id))
        {
            emailIds.add(hoDetailMap.get(sRRecord.Id).KAR__r.Email );
        }
        
        
        map<id,set<String>> soToJointOwnerMap = DefaultAndTerminationUtility.getOwnerEmailList(new set<ID>{sRRecord.SalesOrder__c});
        if(soToJointOwnerMap.containsKey(sRRecord.SalesOrder__c) && !soToJointOwnerMap.get(sRRecord.SalesOrder__c).isEmpty()){
            emailIds.addAll(soToJointOwnerMap.get(sRRecord.SalesOrder__c));
        }
        
        
        //add emailIds for Contact, Handover KAR Email and Joint Owner
        emailIds.add(sRRecord.SalesOrder__r.Contact__c !=null ? sRRecord.SalesOrder__r.Contact__r.Email : sRRecord.SalesOrder__r.Account__r.PersonEmail) ;
        
        for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :System.Label.CFR_OrgWideAddress limit 1]){
            orgWideEmailAddress=tempRec.Id;
        }
        
        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        //ATTACHMENT CODEGet placeholder
        
        map<id,id> docToCVId = new  map<id,id>();
        for(HexaBPM__SR_Doc__c tempSRDOC : [select id from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c = :sRRecord.Id and DocumentMasterCode__c = :DocumentMasterCode]){ 
            docToCVId.put(tempSRDOC.id, null);
        }
        //Query Content document link 
        if(!docToCVId.isEmpty()){
            for(contentDocumentLink CDLink : [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid in :docToCVId.keySet() order by systemmodstamp desc LIMIT 1 ]){  
                docToCVId.put(CDLink.LinkedEntityid,CDLink.ContentDocumentid);
            }
            //Query COntent version
            for ( ContentVersion cversion : [SELECT title, FileType,versiondata FROM contentversion WHERE ContentDocumentId IN :docToCVId.values()  ]){
                Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                efa.setFileName(cversion.title+'.'+cversion.FileType);
                efa.setBody(cversion.versiondata);
                fileAttachments.ADD(efa);
            }
        }
        
        // list<String> emailIds=new list<String>();
        // emailIds.add('mraj@aldar.com');
        // if(sRRecord.HexaBPM__Customer__r.isPersonAccount){
        //     emailIds.add(sRRecord.HexaBPM__Customer__r.PersonEmail);
        // }else if(sRRecord.HexaBPM__Contact__c!=null){
        //     List<Contact> conList= [select Id,Email from Contact where Id =:sRRecord.HexaBPM__Contact__c];
        //     if(!conList.isEmpty()){
        //         emailIds.add(conList.get(0).Email);
        //     }
        // }else if(sRRecord.HexaBPM__Customer__r.Email__c!=null && emailIds.isEmpty()){
        //     emailIds.add(sRRecord.HexaBPM__Customer__r.Email__c);  
        // }
        list<Messaging.SingleEmailMessage> emailToSend = new list<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage tempEmailInstance =Utilities.getEmailInstance( (sRRecord.HexaBPM__Customer__r.isPersonAccount ?  sRRecord.HexaBPM__Customer__r.PersonContactId : sRRecord.HexaBPM__Contact__c !=null ?sRRecord.HexaBPM__Contact__c: sRRecord.SalesOrder__r.Contact__c) ,emailTemplateLeadId,srDocOBJ.Id,emailIds,null,ccAddress,null,null,null,fileAttachments,orgWideEmailAddress);
        tempEmailInstance.setSaveAsActivity(true);
        emailToSend.add(tempEmailInstance);
        if(!emailToSend.isEmpty()){ 
            if(!Test.isRunningTest()){
                Utilities.sendEmail(emailToSend);  
            }
            
        }
        
    }
}