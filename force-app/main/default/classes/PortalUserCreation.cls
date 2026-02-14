/**********************************************************************************************************************
* Name               : PortalUserCreation                                                       
* Description        : Batch to create user and set Passowrd
* Usage              : 1 time batch to be executed after data migration   ****Run with 100 Records  ****Disable the Welcome Email                                                 
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     10 Feb 2022      Initial Draft       
******************************************************************************************************************/
//Example:
//database.executeBatch(new PortalUserCreation(' and Id=\'0032600001KmDG8\'','Temp@123','@aldar.uat.com','paras.bhatt@pwc.com'));
global class PortalUserCreation implements Database.Batchable<sObject>,Database.Stateful{
    string whereClause;
    string passwordString;
    string userNameFormat;
    string overrideEmail;
    global PortalUserCreation(string inputWhereClause, string tempPass, string formatVal,String emailString){
        whereClause = inputWhereClause;
        passwordString = tempPass;
        userNameFormat=formatVal;
        overrideEmail=emailString;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime currentDT = system.now();//.addHours(-2);
        String query='select id,FirstName,LastName,BrokerType__c,email from Contact where BrokerType__c!= null '+ whereClause;
        system.debug(query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Contact> scope){
        map<String,Profile> profileMap = new map<string,Profile>();
        for(profile pf : [select id,Name from Profile where name = :Constants.AGENCY_ADMIN_PROFILE or name = :Constants.AGENCY_USER_PROFILE]){
            profileMap.put(pf.Name,pf);
        }
        map<id,COntact> conMap = new map<ID,Contact>(scope);
        set<iD> conIdtoSkip = new set<ID>();
        for(User te : [select id,COntactId from user where contactId in :conMap.keySet() ]){
            conIdtoSkip.add(te.COntactId);
        }
        list<User> usersToInsert = new list<USer>();
        Integer i=0;
        for(Contact con : scope){
            if(conIdtoSkip.contains(con.id)){
                continue;
            }
            i++;
            Profile profileToFetch;
            if(con.BrokerType__c == 'Agent'){profileToFetch = profileMap.get(Constants.AGENCY_USER_PROFILE);  }
            if(con.BrokerType__c == 'Agency Admin'){profileToFetch = profileMap.get(Constants.AGENCY_ADMIN_PROFILE); }

           
            if(profileToFetch!=null){
                User tempU = new user();
                
                tempU.ProfileID = profileToFetch.id;
                tempU.EmailEncodingKey = 'UTF-8';
                tempU.LanguageLocaleKey = 'en_US';
                tempU.TimeZoneSidKey = 'Asia/Dubai';
                tempU.LocaleSidKey = 'en_AE';
                tempU.FirstName = con.FirstName;
                tempU.LastName = con.lastName;
                tempU.Username = con.FirstName.replaceAll( '\\s+', '')+'.'+con.lastName.replaceAll( '\\s+', '')+i +userNameFormat;//+'@uat.brokerportal.com';   
                tempU.CommunityNickname = con.lastName+'_'+i;
                tempU.Alias = con.lastName.left(8);
                tempU.Email = (overrideEmail !=null && overrideEmail !='')?overrideEmail:con.email;
                tempU.IsActive = true;
                tempU.ContactId = con.Id;
                system.debug(tempU.Username);
                
                usersToInsert.add(tempU);
            }
        }

        if(!usersToInsert.isEmpty()){
            insert usersToInsert;
            for(User tempU : usersToInsert){
                
                    System.setPassword(tempU.Id, passwordString);
                
            }
        }
       
    }    
    global void finish(Database.BatchableContext bc){}    
}