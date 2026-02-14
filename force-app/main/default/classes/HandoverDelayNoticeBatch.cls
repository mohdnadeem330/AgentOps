global class HandoverDelayNoticeBatch implements Database.Batchable<sObject>,Database.AllowsCallouts {
    
     public String queryStr = '';
     Public List<String> hoIds;
     Public String emailTempId='';
    
     public HandoverDelayNoticeBatch(String queryStr,List<String> hoIdsInput, String emailTempId){
        this.queryStr=queryStr;
        this.hoIds=hoIdsInput;
        this.emailTempId=emailTempId;
        
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(queryStr==''){
            queryStr='SELECT Id,CreatedDate,UnitName__c,HandoverPhaseDate__c,KAR__r.Email,(SELECT Id,SalesOrder__c,HandoverDetail__r.OutstandingAmount__c,HAndoverDetail__c,HexaBPM__Contact__c,HexaBPM__Customer__c,HexaBPM__Customer__r.PersonEmail,HexaBPM__Customer__r.PersonContactId,HexaBPM__Customer__r.isPersonAccount,HexaBPM__Customer__r.Email__c,HandoverDetail__r.HandoverPhaseDate__c, HandoverDetail__r.UnitName__c,HandoverDetail__r.CustomerName__c from ServiceRequests__r  where SRType__c=\'Handover\') from HandoverDetails__c where ID IN :hoIds';       
        }        
        return Database.getQueryLocator(queryStr);  
    }
    
    global void execute(Database.BatchableContext bc, List<HandoverDetails__c> scope) {
         
        //SELECT Id,CreatedDate,(select ID from ServiceRequests__r) from HandoverDetails__c order by CreatedDate DESC limit 1
        
                list<String> pendingDocList = new list<String>();
                HexaBPM__Service_Request__c sRRecord =scope.get(0).ServiceRequests__r.get(0) ;
                
                //Send Email
                string emailTemplateId = '';
                string emailTemplateLeadId = '';
                string relatedCustomerId = '';
                string orgWideEmailAddress = '';
                for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = 'Handover_Delay_Notice' limit 1]){
                    emailTemplateLeadId=tempRec.Id;
                }
        
                if( this.emailTempId!=''){
                    emailTemplateLeadId= this.emailTempId;
                }
                List<String> ccAddress = new List<String>();
                if(scope.get(0).KAR__r.Email!=null){
                    ccAddress.add(scope.get(0).KAR__r.Email); 
                }
                 ccAddress.add('dcsupport@aldar.com'); 
               
                map<id,set<String>> soToJointOwnerMap = DefaultAndTerminationUtility.getOwnerEmailList(new set<ID>{sRRecord.SalesOrder__c});
                if(soToJointOwnerMap.containsKey(sRRecord.SalesOrder__c) && !soToJointOwnerMap.get(sRRecord.SalesOrder__c).isEmpty()){
                   ccAddress.addAll(soToJointOwnerMap.get(sRRecord.SalesOrder__c));
                }
                for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE limit 1]){
                    orgWideEmailAddress=tempRec.Id;
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
                Messaging.SingleEmailMessage tempEmailInstance =Utilities.getEmailInstance( (sRRecord.HexaBPM__Customer__r.isPersonAccount ?  sRRecord.HexaBPM__Customer__r.PersonContactId : sRRecord.HexaBPM__Contact__c !=null ?sRRecord.HexaBPM__Contact__c:sRRecord.HexaBPM__Customer__C) ,emailTemplateLeadId,scope.get(0).Id,emailIds,null,ccAddress,null,null,null,null,orgWideEmailAddress);
                 tempEmailInstance.setSaveAsActivity(true);
                emailToSend.add(tempEmailInstance);
                if(!emailToSend.isEmpty()){ 
                    if(!Test.isRunningTest()){
                         Utilities.sendEmail(emailToSend);  
                    }
                   
                }
       
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
}