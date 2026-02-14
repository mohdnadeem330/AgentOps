global with sharing class ConnectorEntityController {

    public ConnectorEntityController() { } 
   
    @RemoteAction
    global static Task createTask(Task task,String field, String value) {
        
       /* try{ 
			List<Contact> contacts = Database.query('Select id,AccountId,Birthdate,Email,FirstName,LastName,Phone from Contact where ' + field + ' = \'' + value + '\'');
            System.debug('contacts found : ' + contacts);
            if ( contacts.size() == 1 ){
                task.WhoId = contacts.get(0).Id;
            } 
            } catch(Exception e){
            System.debug('Error in createTask ' + e);     
         }*/

        try{           
            Database.SaveResult sr =  Database.insert(task);
                System.debug('save result : ' + sr);   
            	return task;
            } catch(Exception e){
            System.debug('Error in insert ' + e);
        
         }
        return null;
    }
    
    @RemoteAction
    global static Map<String,List<sObject>> findRecords(String value) {
        Map<String,List<sObject>> result = new Map<String,List<sObject>>();
        try{        
            List<List<sObject>> records =[find : value IN ALL FIELDS RETURNING Lead (Id, Name,phone,email,status), Contact(id,name,phone,email,Account.Name)]; 
            System.debug('contacts found : ' + records);
           	List<sObject> leads = records[0];
            List<sObject> contacts = records[1];
            result.put('contact',contacts);
            result.put('lead',leads);
            return result;
            } catch(Exception e){
            System.debug('Error in finding contact ' + e);     
         }
    return result;
    }
	@RemoteAction
    global static Lead createLead(String field, String value) {
        try{
            Lead l = new Lead();
            if(field == 'Phone'){
                l.Phone = value;
            } else {
                l.EmailAddress__c = value;
            }
            l.AssignToRoundRobin__c = false;
            l.EnquiryCategory__c = 'Broker/Agent';
            l.EnquiryTrigger__c = 'Mayan Show Home';
            l.LastName = 'Test';
            l.Project__c = 'Al Raha Beach';
            insert l;
            return l;
        } catch(Exception e){
            	System.debug('Error in create lead ' + e);     
         	}
    	return null;
    }

	@RemoteAction
    global static Lead findLead(String id) {
        try{ 
			List<Lead> leads = Database.query('Select id,OwnerId from Lead where id = \'' + id + '\'');
            System.debug('leads found : ' + leads);
            if ( leads.size() == 1 ){
                leads.get(0).OwnerId = UserInfo.getUserId();
            }
            update leads.get(0);
            return leads.get(0);
        } catch(Exception e){
            	System.debug('Error in create lead ' + e);     
        }
    	return null;
    }    
   
    @RemoteAction
    global static List<SObject> findContactAndLead(String field, String value) {
        
        try{        
                List<List<SObject>> searchList = [FIND :value IN ALL FIELDS RETURNING Contact(Id,FirstName,LastName, Phone, Email), Lead(Id,FirstName,LastName, Phone, Email)];
                System.debug('List<List<SObject>> ' + searchList); 
                Contact[] searchContacts = (Contact[])searchList[0];
                Lead[] searchLeads = (Lead[])searchList[1];
               
                if(searchContacts.size() > 0){
                   return searchContacts;
                } else if (searchLeads.size() > 0){
                   return searchLeads;
                } else {
                    List<Lead> leads = new List<Lead>();
                    Lead l = new Lead();
                    if(field == 'Phone'){
                        l.Phone = value;
                    } else {
                        l.Email = value;
                    }
                    leads.add(l);
                    insert leads;
                    return leads;
                }
            } catch(Exception e){
            	System.debug('Error in finding contact ' + e);     
         	}
    	return null;
    }
    
    
    @RemoteAction
    global static List<Contact> findContactId(String field, String value) {
        
        try{        
            List<Contact> contacts = Database.query('Select id,name from Contact where ' + field + ' = \'' + value + '\'');
            System.debug('contacts found : ' + contacts);
            return contacts;
            } catch(Exception e){
            System.debug('Error in finding contact ' + e);     
         }
    return null;
    }

    @RemoteAction
    global static Case createCase(Case obj,String field, String value) {
        
        try{        
            List<Contact> contacts = Database.query('Select id,AccountId,Birthdate,Email,FirstName,LastName,Phone from Contact where ' + field + ' = \'' + value + '\'');
            System.debug('contacts found : ' + contacts);
            if ( contacts.size() == 1 ){
                obj.ContactId = contacts.get(0).Id;
            } 
            } catch(Exception e){
            System.debug('Error in finding contact ' + e);     
         }

        try{           
            Database.SaveResult sr =  Database.insert(obj);
                System.debug('save result : ' + sr);   
            	return obj;
            } catch(Exception e){
            System.debug('Error in insert ' + e);
        
         }
        return null;
    }

    @RemoteAction
    global static SObject createSObject(SObject obj) {
        try{           
            Database.SaveResult sr =  Database.insert(obj);
                System.debug('save result : ' + sr);   
            	return obj;
            } catch(Exception e){
            System.debug('Error in insert ' + e);
        
         }
        return null;
    }

    @RemoteAction
    global static String updateTask(String taskId,String contactId) {
        
        try{        
            List<Task> ts = [SELECT Id,softphone_it__IWS_Interaction_ID__c FROM Task WHERE Id = :taskId limit 1];
            System.debug('case found : ' + ts);
            if ( ts == null || ts.size() == 0 ){
                return null;
            }
            ts[0].WhoId = contactId;
            update ts[0];  
            return ts[0].softphone_it__IWS_Interaction_ID__c;
        } catch(Exception e){
            System.debug('Error in updateTask ' + e);     
        }

	    return null;
    }

    @RemoteAction
    global static Boolean isPersonalAccount(String accountId) {
        
        try{        
            Account acc = [SELECT Id,IsPersonAccount FROM Account WHERE Id = :accountId];
            System.debug('account found : ' + acc);
            if ( acc == null){
                return false;
            }
            return acc.IsPersonAccount;
        } catch(Exception e){
            System.debug('Error in updateTask ' + e);     
        }

	    return null;
    }

    @RemoteAction
    global static String closeTask(String taskId,String wrapup, String callStatus, String customerResponse, String interactionId) {
        
        try{        
            List<Task> ts = [SELECT Id,softphone_it__IWS_Interaction_ID__c, Call_Status__c, WrapUpCodes__c, CustomerResponse__c FROM Task WHERE Id = :taskId limit 1];
            System.debug('task found : ' + ts);
            if ( ts == null || ts.size() == 0 ){
                return null;
            }
            ts[0].WrapUpCodes__c = wrapup;
            ts[0].Call_Status__c = callStatus;
            ts[0].Calledby__c = UserInfo.getUserId();
            ts[0].Status = 'Completed';
            ts[0].CustomerResponse__c = customerResponse;
            ts[0].softphone_it__IWS_Interaction_ID__c = interactionId;
            update ts[0];  
            return ts[0].softphone_it__IWS_Interaction_ID__c;
        } catch(Exception e){
            System.debug('Error in updateTask ' + e);     
        }

	    return null;
    }
    
    @RemoteAction
    global static Task findTask(String id) {
        try{ 
			List<Task> tasks = Database.query('Select id, WhatId, WhoId from Task where (WhatId = \'' + id + '\' OR WhoId = \'' + id + '\') AND Status = \'Open\' AND Task_Name__c != NULL');
            System.debug('tasks found : ' + tasks);
            if ( tasks.size() == 1 ){
                return tasks.get(0);
            }
        } catch(Exception e){
            	System.debug('Error in create lead ' + e);     
        }
    	return null;
    }  

    @RemoteAction
    global static String updateCase(String caseId,String contactId) {
        
        try{        
            List<Case> cs = [SELECT Id,softphone_it__IWS_Interaction_ID__c FROM Case WHERE Id = :caseId limit 1];
            System.debug('case found : ' + cs);
            if ( cs == null || cs.size() == 0 ){
                return null;
            }
            cs[0].ContactId = contactId;
            update cs[0];  
            return cs[0].softphone_it__IWS_Interaction_ID__c;
        } catch(Exception e){
            System.debug('Error in updateCase ' + e);     
        }

	    return null;
    }


   @RemoteAction
   global static softphone_it__ConnectorEventTimeLog__c createConnectorEventTimeLog(Map<String, Object> obj) {
        
        try{
        	Long callTime = (Long)(Decimal)obj.get('callTime'); 
            if ( callTime == null ){
                callTime = Datetime.now().getTime();
            }
            softphone_it__ConnectorEventTimeLog__c timeLog = new softphone_it__ConnectorEventTimeLog__c();
            timeLog.Name = (String)obj.get('interactionId');
            timeLog.softphone_it__Ringing_Time__c = DateTime.newInstance(callTime);
            //timeLog.Ringing_Time__c = DateTime.now();
            timeLog.softphone_it__Interaction_Id__c = (String)obj.get('interactionId');
            timeLog.softphone_it__Agent_Id__c = (String)obj.get('agentId');
            timeLog.softphone_it__Direction__c = (String)obj.get('callType');
            timeLog.softphone_it__Media_Type__c = (String)obj.get('mediaType');
                        
            Database.SaveResult sr =  Database.insert(timeLog);
            System.debug('save result : ' + sr);   
            return timeLog;
        } catch(Exception e){
            System.debug('Error in createConnectorEventTimeLog ' + e);     
        }
        
        return null;
    }
    
    @RemoteAction
    global static boolean updateConnectorEventTimeLog(Map<String, Object> obj) {
        boolean result = true;
        String interactionId = (String)obj.get('interactionId');
        String field = (String)obj.get('field');
        String state = (String)obj.get('state');
        Long callTime = (Long)(Decimal)obj.get('callTime');
        String disposition = (String)obj.get('disposition');
        DateTime value = DateTime.newInstance(callTime);
        String parentId = (String)obj.get('parentId');
        String caseId = (String)obj.get('caseId');
        String contactId = (String)obj.get('contactId');
        Integer interactionDuration = Integer.valueOf(obj.get('interactionDuration'));
         Integer totalAcdDuration = Integer.valueOf(obj.get('totalAcdDuration'));
         Integer totalIvrDuration = Integer.valueOf(obj.get('totalIvrDuration'));
         Integer dispositionDuration = Integer.valueOf(obj.get('dispositionDuration'));
        System.debug('caseid  : ' + caseId);
        try{ 
            List<softphone_it__ConnectorEventTimeLog__c> timeLogs = [Select id, softphone_it__established_Time__c from softphone_it__ConnectorEventTimeLog__c where softphone_it__Interaction_Id__c = :interactionId  order by softphone_it__ringing_time__c desc limit 1];
            
            System.debug('ConnectorEventTimeLog found : ' + timeLogs);
            
            if ( timelogs == null || timelogs.size() == 0 ){
                return null;
            }
            
            
            softphone_it__ConnectorEventTimeLog__c timelog = timelogs[0];
            timelog.put(field,value);
            if ( caseId != null && caseId != 'a' ){
                timelog.softphone_it__Case__c = caseId; 
            }
            if(contactId != null){
                timelog.softphone_it__Contact__c = contactId; 
            }
            if(parentId != null){
                timelog.softphone_it__Parent_Id__c  = parentId; 
            }
            if(state != null){
                timelog.softphone_it__State__c = state; 
            }
            if(disposition != null){
                timelog.softphone_it__Disposition_Code__c = disposition; 
            }
            if(interactionDuration != null){
                timelog.softphone_it__Interaction_Duration__c = interactionDuration; 
            }
            if(totalAcdDuration != null){
                timelog.softphone_it__Total_Acd_Duration__c = totalAcdDuration; 
            }
            if(totalIvrDuration != null){
                timelog.softphone_it__Total_Ivr_Duration__c = totalIvrDuration; 
            }
            if(dispositionDuration != null){
                timelog.softphone_it__Disposition_Duration__c = dispositionDuration; 
            }
            if(field == 'softphone_it__Released_Time__c' && state == 'answered' && timeLog.softphone_it__Established_Time__c == null){
                timelog.softphone_it__State__c = 'not answered';
            }
        
            update timelog;  
        } catch(Exception e){
            System.debug('Error in updateConnectorEventTimeLog ' + e);
            result = false;
        }
        
        return result;
    }



    @RemoteAction
    global static String ERCOmniUtilsPath {
        get {
           return GetResourceURL('softphoneerc','omniUtils');
        }
    }

    @RemoteAction
    global static String ERCiwsscriptomniPath {
        get {
           return GetResourceURL(null,'iwsscript_omni');
        }
    }

     @RemoteAction
    global static String ERCsyncUtilsPath {
        get {
           return GetResourceURL(null,'syncUtils');
        }
    }


    public static String GetResourceURL(String namespace,String resourceName){

        List<StaticResource> resourceList= namespace != null ? 
        [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :resourceName AND NamespacePrefix = :namespace] : 
        [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :resourceName] ;
            if(resourceList.size() == 1){
                String nm = resourceList[0].NamespacePrefix;
               return '/resource/' + resourceList[0].SystemModStamp.getTime() + '/' + (nm != null && nm != '' ? nm + '__' : '') + resourceName; 
            }
            return ''; 
        
        }
    
		@AuraEnabled(cacheable=true)
		public static sObject getLeadPhoneNumberById(Id id, String objname) {
 			System.debug('getInteractionIdById id :' + id);
            if(objname=='Lead'){
            	List<sObject> ld =Database.query('Select Id, phone, MobilePhone  FROM Lead Where Id = \'' + id + '\'');
 				if ( ld.size() == 0 ) return null;
 					return ld[0];
            } else if(objname=='Account'){
                List<sObject> act =Database.query('Select Id, Phone, MobileNumber__c, PersonMobilePhone FROM Account Where Id = \'' + id + '\'');
 				if ( act.size() == 0 ) return null;
 					return act[0];
            } else if(objname=='Opportunity'){
                List<sObject> opp =Database.query('Select Id, MobileNumberFormula__c, PhoneNumberFormula__c FROM Opportunity Where Id = \'' + id + '\'');
 				if ( opp.size() == 0 ) return null;
 					return opp[0];
            } else if(objname=='HexaBPM__Service_Request__c'){
                List<sObject> sr =Database.query('Select Id, MobileNumberFormula__c, PhoneNumberFormula__c FROM HexaBPM__Service_Request__c Where Id = \'' + id + '\'');
 				if ( sr.size() == 0 ) return null;
 					return sr[0];
            } else if(objname=='Case'){
                List<sObject> cs =Database.query('Select Id, MobileFormula__c, PhoneFormula__c FROM Case Where Id = \'' + id + '\'');
 				if ( cs.size() == 0 ) return null;
 					return cs[0];
            } else if(objname=='Task'){
                List<sObject> tk =Database.query('Select Id, Mobile_Number__c, Phone_Number__c FROM Task Where Id = \'' + id + '\'');
 				if ( tk.size() == 0 ) return null;
 					return tk[0];
            }
            return null;
        }

         @AuraEnabled
        public static List<Click_To_Dial__mdt> getDropdownvalues(){
            List<Click_To_Dial__mdt> clicktodialDropdown = new  List<Click_To_Dial__mdt>();
            List<Click_To_Dial__mdt> clicktodialList = [SELECT masterLabel,Vertical__c,withoutplus__c,withplus__c,with971__c,withZero__c,QueueID__c FROM Click_To_Dial__mdt];
            User us = [SELECT Id,Profile.Name,CallTrunkOptions__c FROM User WHERE Id =:UserInfo.getUserId()];
            for(Click_To_Dial__mdt clk :clicktodialList){
                if(us.CallTrunkOptions__c != null){
                    for(String str : us.CallTrunkOptions__c.split(';')){
                        if(clk.masterLabel == str.trim()){
                            clicktodialDropdown.add(clk);
                        }
                    }
                }else{
                    if(clk.masterLabel =='Aldar'){
                     clicktodialDropdown.add(clk);
                    }
                }
            }
            return clicktodialDropdown;
        }


}