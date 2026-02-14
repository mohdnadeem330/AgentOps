public without sharing class UtilitiesWithoutSharing {
    
    public static Boolean bypassValidation = true;
    
    //Added by Harsh@Aldar 07/01/2025 Stop Opportunity Trigger after Premium Parking Lead is converted
    public static Boolean bypassOpportunityTrigger = false;
    
    //Unlock Records
    @future
    public static void unlockRecords(set<Id> idsToUnlock){
        system.debug('----'+idsToUnlock);
        Approval.Unlock(new list<ID>(idsToUnlock), false);
    }
    
    
    @future(callout=true)
    public static void sendWhatsAppMessage(Set<Id> accIds, String CustomerName, String ProjectName, String SalesManager, String LeadNumber, String MessageType, String anyAttribute1, String anyAttribute2, String anyAttribute3, String anyAttribute4, String anyAttribute5, String anyAttributeValue1, String anyAttributeValue2, String anyAttributeValue3, String anyAttributeValue4, String anyAttributeValue5, String whatsAppMetadataName) {
       /* Account acc = [SELECT Id, PersonMobilePhone FROM Account WHERE Id IN:accIds];
        Map<String, Object> notificationBodyMap = new Map<String, Object>();
        WatsAppLinkGenesys__mdt whatsappgen = WatsAppLinkGenesys__mdt.getInstance(whatsAppMetadataName);
        Map<String, Object> notificationDataMap = new Map<String, Object>();
        notificationDataMap.put('Flow.CustomerName',CustomerName);
        notificationDataMap.put('Flow.ProjectName',ProjectName);
        notificationDataMap.put('Flow.HSMTemplateId',whatsappgen.HSMTemplateId__c);
        notificationDataMap.put('Flow.MobileNumber',acc.PersonMobilePhone);
        notificationDataMap.put('Flow.SalesManager',SalesManager);
        notificationDataMap.put('Flow.LeadNumber',LeadNumber);
        notificationDataMap.put('Flow.MessageType',MessageType);
        notificationDataMap.put('Flow.AttributeName1',anyAttribute1);
        notificationDataMap.put('Flow.AttributeValue1',anyAttributeValue1);
        notificationDataMap.put('Flow.AttributeName2',anyAttribute2);
        notificationDataMap.put('Flow.AttributeValue2',anyAttributeValue2);
        notificationDataMap.put('Flow.AttributeName3',anyAttribute3);
        notificationDataMap.put('Flow.AttributeValue3',anyAttributeValue3);
        notificationDataMap.put('Flow.AttributeName4',anyAttribute4);
        notificationDataMap.put('Flow.AttributeValue4',anyAttributeValue4);
        notificationDataMap.put('Flow.AttributeName5',anyAttribute5);
        notificationDataMap.put('Flow.AttributeValue5',anyAttributeValue5);
        
        notificationBodyMap.put('flowId', whatsappgen.flowId__c);
        notificationBodyMap.put('name', whatsappgen.name__c); 
        
        notificationBodyMap.put('inputData', notificationDataMap);
        
        String requestBody = JSON.serialize(notificationBodyMap);
        String muleRes = '';
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(CustomerAPIConstants.WHATSAPP_LINK_GENESYS);
        
        Organization org = Utilities.getOrganizationDetails();
        
        String endPointURL = mulesoftAPI.SandboxURL__c ;
        if (!org.IsSandbox) {
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('client_secret', mulesoftAPI.APIKey__c);
        request.setHeader('client_id', mulesoftAPI.APIId__c);
        request.setTimeout(120000);
        request.setEndpoint(endPointURL);
        request.setMethod(mulesoftAPI.Method__c);
        request.setBody(requestBody);
        
        HttpResponse response = http.send(request);
        muleRes = response.getBody();*/
    }
    
    public static void createUpdateLeadWithoutSharing(Lead leadRec){
        if(leadRec.Id != null){
            Update leadRec;
        }else{
            Insert leadRec;
        }
    }
    
    @InvocableMethod
    public static void convertLeadsInvocableMethod(List<Id> leadIds){
        Set<Id> leadIdsSet = new Set<Id>(leadIds);
        convertLeads(leadIdsSet);
    }
    
    public static double getTotalNetAmounForDigitalSPA(Document__c documentRec){
        system.debug('documentRec.SalesOrder__r.Unit__r.Project__c '+documentRec.SalesOrder__r.Unit__r.Project__c);
        List<AggregateResult> groupResultsList = [Select SalesOrder__r.Unit__r.Project__r.Name,SUM(SalesOrder__r.NetAmount__c)netAmount
                                                  FROM Document__c where SalesOrder__r.ProjectName__c =:documentRec.SalesOrder__r.Unit__r.Project__r.Name
                                                  AND SalesOrder__r.Status__c !='Cancelled' 
                                                  AND Identityverification__c = true 
                                                  AND Esignlocation__c != '' 
                                                  GROUP BY SalesOrder__r.Unit__r.Project__r.Name];
        if(groupResultsList.size() > 0){
            double netAmount = groupResultsList[0].get('netAmount') != null ? double.valueOf( groupResultsList[0].get('netAmount') ) : 0.0;
            system.debug('-- netAmount'+netAmount);      
            return netAmount;
        }else{
            return 0;
        }
    }
    
     public static String getConvertedOppBySearchLead(String leadNumber,String AccountId){
        
        String opportunityId;
        Lead brokerLead = new Lead();
        List<Lead> ldlist = getleadbyLeadNumber(leadNumber);
        List<Account> existingVIPCust = new List<Account>();
        List<Lead> existingVIPLead = new List<Lead>();
        //String UserRoleId = [SELECT Id from UserRole Where Name = 'CASA - Sales Manager'].Id;
        //,Allowleadconversion__c
        User us = [SELECT Id,Name,Profile.Name,RoleName__c,ProfileName__c,ByPassBrokerLeadSearch__c FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
        try{
           String errorString = checkPrivileges(us);
           if(errorString != null && errorString !=''){
            throw new Exceptions.InsufficientAccessException() ;
           }
        }catch(Exception e){
            throw new Exceptions.InsufficientAccessException() ;
        }
        try{
            brokerLead = ldlist[0];
        }catch(Exception e){
            throw new Exceptions.IncorrectFilterException() ;
        }
        try{
            if( us.ProfileName__c == 'Sales Manager' && brokerLead.Sodic_Lead_1__c == false && brokerLead.Lead_Type__c =='New Sale'){

            }else if(us.ProfileName__c =='Sales Manager - SODIC' && brokerLead.Sodic_Lead_1__c == true){
                
            }else if(us.ProfileName__c =='Resale Relationship Manager' && (brokerLead.Lead_Type__c == 'Resale' || brokerLead.Lead_Type__c == 'AM Sale')){

            }else{
                throw new Exceptions.InsufficientAccessException() ;
            }
        }catch(Exception e){
            throw new Exceptions.InsufficientAccessException() ;
        }
           try 
            {
                if(brokerLead.BrokerAgency__r.AgencyStatus__c == 'Suspended')
              {
                       throw new Exceptions.BrokerSuspensionException() ;
                    }
            }
        catch(Exception e)
        {
            throw new Exceptions.BrokerSuspensionException() ;
        }

        
        
       /* try{
            if(Userinfo.getUserRoleId() == UserRoleId){
                throw new Exceptions.InsufficientAccessException() ;
            }
        }catch(Exception e){
            throw new Exceptions.InsufficientAccessException() ;
        }*/

        try{
           // brokerLead = [SELECT Id, LeadNumber__c, Email, MobilePhone, OwnerId FROM LEAD where Leadnumber__c =: leadNumber and LeadSource =:Constants.BROKER_PORTAL];
            existingVIPCust = [Select id from Account where (PersonEmail=:brokerLead.Email or PersonMobilePhone=:brokerLead.MobilePhone or Email__c=:brokerLead.Email or MobileNumber__c=:brokerLead.MobilePhone) and CustomerType__c='VIP' and (PersonEmail!=null or Email__c!=null) and (PersonMobilePhone!=null or MobileNumber__c!=null) limit 1];
            existingVIPLead = [Select id from Lead where (CustomerType__c='VIP' and Email!=null and MobilePhone!=null) and (Email=:brokerLead.Email or MobilePhone=:brokerLead.MobilePhone) limit 1];
            if((!existingVIPCust.isEmpty() || !existingVIPLead.isEmpty()) && brokerLead.VIPApproval__c !='Approved'){
                throw new Exceptions.VIPBrokerLeadException() ;
            }
        }catch(Exception e){
            throw new Exceptions.VIPBrokerLeadException() ;
        }
         
        if(brokerLead!=null & brokerLead.Id !=null){
            // ArvindBug Fixed - Try catch moved to up before update the Lead
   
            try{
                if(brokerLead.IsConverted == true){
                    throw new Exceptions.AlreadyConvertedException() ;
                }
            }catch(Exception e){
                throw new Exceptions.AlreadyConvertedException() ;
            }
            brokerLead.ownerId = Userinfo.getuserid();
            brokerLead.VerifiedBy__c = UserInfo.getUserId();
            brokerLead.VerifiedDateTime__c = System.now();
            if(AccountId != null && AccountId != ''){
                UtilitiesWithoutSharing.addacocuntTeamMember(AccountId);
                brokerLead.ExistingAccount__c = AccountId;
            }
            update brokerLead;
            
            
            Set<Id> leadIdsSet = new Set<Id>{brokerLead.Id};
            List<Database.LeadConvertResult> leadConversionResult = convertLeads(leadIdsSet);
            opportunityId = leadConversionResult[0].getOpportunityId();
            
            
            /*Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(brokerLead.Id);
            lc.setOwnerId(Userinfo.getuserid()) ;
            System.debug('user '+Userinfo.getuserid());
            
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);*/
            
            
        }
        return opportunityId;
    }
    
    public static List<Database.LeadConvertResult> convertLeadFromAppointment(Id leadId) {
        List<Lead> lds = [SELECT Id, LeadNumber__c, ConvertedFromAppointment__c, OwnerId,Project__c, IsConverted FROM Lead WHERE Id =: leadId];
        String errorMessage;
        if(lds != null && !lds.isEmpty()){ 
            if(lds[0].IsConverted){
                errorMessage = 'Invalid request: '+lds[0].LeadNumber__c+'Lead already converted.';
            }
        }else{
            errorMessage = 'Invalid request: Lead not found for conversion : '+leadId;
        }
        if(errorMessage != null){
            AuraHandledException aex = new AuraHandledException(errorMessage);
            aex.setMessage(errorMessage);
            throw aex;
        }
        if(Schema.Group.SObjectType == lds[0].OwnerId.getSobjectType()){
            User aldarDevelopementUser = [SELECT Id FROM User WHERE Name = 'Aldar Development'];
            lds[0].OwnerId = aldarDevelopementUser.Id;
        }
        lds[0].ConvertedFromAppointment__c = true;
        update lds[0];
        return convertLeads(new Set<Id>{leadId});
    }
    
    public static list<Database.LeadConvertResult> convertLeads(set<id> leadIds){
        list<Database.LeadConvert> leadTobeConverted = new list<Database.LeadConvert>();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        Map<Id,Lead> leadMap = new Map<Id,Lead>(LeadService.getAllLeadByIds(leadIds));
        Set<String> uniqueKeys = new Set<String>();
        /* Added by Cloudzlab START*/
        String ECSSLabelRecordType = System.Label.ECSS_LeadRecordType_AlDarEstate;
        String ECSSOppRecTypeLabel = Constants.ECSSOppRecType;
        Id ECSSOpprecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(ECSSOppRecTypeLabel).getRecordTypeId();  
        Id ECSSrecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(ECSSLabelRecordType).getRecordTypeId();
        System.debug('ECSSrecordTypeId:' +ECSSrecordTypeId);
        System.debug('ECSSOpprecordTypeId:'+ECSSOpprecordTypeId);
        String ECSSleaseRecTypeLabel = Constants.ECSSLeaseRecType;
        Id ECSSleaserecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(ECSSleaseRecTypeLabel).getRecordTypeId();
        
        String ECSSSecondaryMarketRecTypeLabel = Constants.ECSSSecondaryMarketOppRecTypeName;
        Id ECSSSecondaryMarketRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(ECSSSecondaryMarketRecTypeLabel).getRecordTypeId();
        
        String ECSSOffPlanRecTypeLabel = Constants.ECSSOffPlanOppRecTypeName;
        Id ECSSOffPlanRecordTypeId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get(ECSSOffPlanRecTypeLabel)
            .getRecordTypeId();

        //this is to get the customer vertical existing value
        Set<String> existingAccIds = new Set<String>();
        /* Added by Cloudzlab END*/
       
        
        for(Lead leadRec : leadMap.values()){
            uniqueKeys.add(leadRec.UniqueKey1__c);
        }
        
        Map<String,Account> allAccountRecMap = AccountService.getAllAccounts(uniqueKeys);
        
        for(Lead leadRec : leadMap.values()){
            system.debug('+++leadRec '+leadRec);
            if(allAccountRecMap!=null && allAccountRecMap.containsKey(leadRec.UniqueKey1__c)){
                Account existAccount = allAccountRecMap.get(leadRec.UniqueKey1__c);
                Id accountId = existAccount.Id;
                // Arvind Bypassing account duplicate check for organization type leads
                if(leadRec.RecordTypeId != Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId())
                leadRec.ExistingAccount__c = accountId;
                /* Added by Cloudzlab */
                if(accountId != null){
                    existingAccIds.add(accountId);
                }
            }
        }
        
        /* Added by cloudzlab START */ 
        // to get the accounts current customer vertical
        List<Account> existingAccounts = [SELECT Id,CustomerVertical__c FROM Account WHERE Id in: existingAccIds];
        Map<String,Account> accVerticalMap = new Map <String,Account>(existingAccounts);
        /* Added by cloudzlab END */ 
        
        for(Id tempLeadId : leadIds){
            Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(tempLeadId);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            //---- Adding existing account if avaialable
            if(leadMap !=null && leadMap.containsKey(tempLeadId)){
                Id accountId = leadMap.get(tempLeadId).ExistingAccount__c ;
                if(accountId!=null){
                    lc.setAccountId(accountId);
                }

            }
            //Added by CloudzLab
            //Start of Changes
            if(leadMap.get(tempLeadId).Lead_Type__c	== 'Landlord'){
                lc.setDoNotCreateOpportunity(true);
            }
            //End of Changes
            leadTobeConverted.add(lc);
        }
        
        bypassValidation = false;
        
        system.debug('++leadTobeConverted '+leadTobeConverted);
        List<Database.LeadConvertResult> lcr = Database.convertLead(leadTobeConverted);
        
        List<Contact> conList = new List<Contact>();
        List<Account> accList = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();
        Id oppResaleRecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Resale').getRecordTypeId();
//        Id oppNewsaleRecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('NewSale').getRecordTypeId();
        Id opplogisticsRecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Logistics').getRecordTypeId();
        Id accOrgrecId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('OrganizationAccount').getRecordTypeId();
        //Added by Harsh@Aldar OB-788 17/10/2024 Start
        Id premParkingRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Premium_Parking').getRecordTypeId();
        Set<String> premParkingLeadSubTypes = new Set<String>{'Premium Parking', 'Garage Upgrade', 'Premium Parking and Garage Upgrade'};
        //Added by Harsh@Aldar OB-788 17/10/2024 End

        /*Added By CloudzLab*/
        /*Start Of Changes*/
        ECSS_Lead_Conversion_Record_Type_Map__mdt ecssRecordType = new ECSS_Lead_Conversion_Record_Type_Map__mdt();
        /*End Of Changes*/
        for (Database.LeadConvertResult lc: lcr) {
            Lead leadRec = leadMap.get(lc.getLeadId());

            Contact con = new Contact();
            con.Id = lc.getContactId();
            con.Email = leadRec.Email;
            con.EmailAddress__c = leadRec.Email;
            con.MobilePhone = leadRec.MobilePhone;
            con.MobileNumberEnc__c = leadRec.MobilePhone;
            con.MobilePhone__c = leadRec.MobileNumber1__c;
            conList.add(con);
            
            Account acc = new Account();
            acc.Id = lc.getAccountId();
            acc.ProspectAccount__c = false;
            if (leadRec.RecordType.Name == 'Person') {
                acc.PersonEmail = leadRec.Email;
                acc.PersonMobilePhone = leadRec.MobilePhone;
                acc.EmailAddress__pc = leadRec.Email;
                acc.MobilePhone__pc = leadRec.MobileNumber1__c;
                acc.MobileNumberEnc__pc = leadRec.MobilePhone;
            }else{
                acc.Email__c = leadRec.Email;
                acc.EmailAddress__c = leadRec.Email;
                acc.MobileNumber1__c = leadRec.MobileNumber1__c;
                acc.MobileNumber__c = leadRec.MobilePhone;
                acc.MobileNumberEnc__c = leadRec.MobilePhone; 
                if(leadRec.RecordType.Name == 'Organization'){
                    acc.RecordTypeId =accOrgrecId;
                }
                if((leadRec.RecordType.Name).contains('ECSS')){
                    if(leadRec.Company==null){
                        acc.PersonBirthdate  = leadRec.Date_of_Birth__c;
                    }
                }
            }
            /*else if(leadRec.RecordType.Name == 'Organization'){
                acc.Email__c = leadRec.Email;
                acc.EmailAddress__c = leadRec.Email;
                acc.MobileNumber1__c = leadRec.MobileNumber1__c;
                acc.MobileNumber__c = leadRec.MobilePhone;
                acc.MobileNumberEnc__c = leadRec.MobilePhone;
                acc.RecordTypeId =accOrgrecId;
            }else {
                acc.Email__c = leadRec.Email;
                acc.EmailAddress__c = leadRec.Email;
                acc.MobileNumber1__c = leadRec.MobileNumber1__c;
                acc.MobileNumber__c = leadRec.MobilePhone;
                acc.MobileNumberEnc__c = leadRec.MobilePhone;
            }*/
            if(leadRec.ExistingAccount__c==null && leadRec.LeadSource==Constants.BROKER_PORTAL){
                acc.RingfencedUntil__c = Date.today().addDays(30);
            }
            if(leadRec.ExistingAccount__c != null && leadRec.BrokerAgent__c != null){
                acc.BrokerAgent__c = leadRec.BrokerAgent__c;
            }
            if(leadRec.ExistingAccount__c != null && leadRec.ExistingAccount__r.OwnerId == System.Label.AldarDevelopmentUser){
                acc.OwnerId = UserInfo.getUserId();
            }
			
			//apended Aldar properties/Estates in CustomerVertical__c SSP-364
            UnifiedAccountController.getCustomerVertical(acc, leadRec);
			 //added by Nikhil Mehra 24June25
            /*if(leadRec.Lead_Custodian__c == 'LSQ'){
                acc.LSQ_Owned__c = true;
                acc.Sync_with_SFMC__c = false;
                acc.Sync_with_SFMC__pc = false;
            }*/
            /* Added by Cloudzlab */
            // If the lead is ECSS and the acc already exists, we need to add the value aldarEstate to the customer vertical
            if(leadRec.RecordTypeName__c.contains('ECSS')){
                System.debug('existing accId'+acc.recordTypeId);
                Set<String> customerVerticalValues = new Set<String>();
                if(accVerticalMap.get(acc.Id)!= null && accVerticalMap.get(acc.Id).CustomerVertical__c != null)
                    acc.CustomerVertical__c = accVerticalMap.get(acc.Id).CustomerVertical__c;
                if (acc.CustomerVertical__c != null) {
                    System.debug(acc.CustomerVertical__c);
                    customerVerticalValues.addAll(acc.CustomerVertical__c.split(';'));
                }
                
                // Add new value to the Set
                if (!customerVerticalValues.contains(Constants.ECSSCustomerVerticalVal)) {
                    customerVerticalValues.add(Constants.ECSSCustomerVerticalVal); 
                }
                // Join the values back into a single string
                acc.CustomerVertical__c = String.join(new List<String>(customerVerticalValues), ';');
                if(leadRec.Lead_Type__c== 'Lease'){
                acc.ECSS_Customer_Type__c = 'Tenant';
                    }
                if(leadRec.Company==null){
                    acc.PersonBirthdate  = leadRec.Date_of_Birth__c;
                }
            }
            accList.add(acc);
            
            if (lc.getOpportunityId() != null) {
                Opportunity oppRec = new Opportunity(Id = lc.getOpportunityId());
                /*Added by Cloudzlab*/
                /*Start Of Changes*/
                if(leadRec.RecordTypeName__c.contains('ECSS')){
                    if(leadRec.Lead_Type__c == 'Lease'){
                       oppRec.RecordTypeId = ECSSleaserecordTypeId;
                        oppRec.StageName = Constants.STAGE_NEW;
                    }
                    else if (leadRec.Lead_Type__c == 'Secondary Market Sale'){
                        oppRec.RecordTypeId = ECSSSecondaryMarketRecordTypeId;
                        oppRec.StageName = Constants.STAGE_NEW;
                    }
                    else if (leadRec.Lead_Type__c == 'Off Plan Sale') {
                        oppRec.RecordTypeId = ECSSOffPlanRecordTypeId;
                        oppRec.StageName = Constants.STAGE_NEW;
                    }

                    else {
                    System.debug('Entered in ECSS Opp');
                    oppRec.RecordTypeId = ECSSOpprecordTypeId;
                    System.debug('ECSS OPP RECORDTYPE:'+oppRec.RecordTypeId);
                   // oppList.add(oppRec);
                    // oppRec.SaleType__c = 'New Sale';
                    }
                   /*End Of Changes*/
                }
                else if (leadRec.lead_Type__c == LeadService.RESALE_LEADTYPE) {
                    oppRec.RecordTypeId = oppResaleRecId;
                    oppRec.SaleType__c = 'Resale';
                } else if (leadRec.lead_Type__c == LeadService.NEWSALE_LEADTYPE) {
                    //                    oppRec.RecordTypeId = oppNewsaleRecId;
                    oppRec.SaleType__c = 'New Sale';
                } else if (leadRec.lead_Type__c == LeadService.AMSALE_LEADTYPE) {
                    //                    oppRec.RecordTypeId = oppNewsaleRecId;
                    oppRec.SaleType__c = 'AM Sale';
                }else if( leadRec.lead_Type__c =='Logistics'){
                    oppRec.RecordTypeId = opplogisticsRecId;
                }     
                //Added by Harsh@Aldar OB-788 17/10/2024 Start
                else if(leadRec.lead_Type__c == 'Options and Upgrades' && premParkingLeadSubTypes.contains(leadRec.LeadSubType__c)){
                    oppRec.RecordTypeId = premParkingRecordTypeId;
                    bypassOpportunityTrigger = true;
                    //oppRec.Lead_Type__c = leadRec.lead_Type__c;
                    //oppRec.LeadSubType__c = leadRec.LeadSubType__c;
                }//Added by Harsh@Aldar OB-788 17/10/2024 End  
                if(leadRec.InitiateDigitalBooking__c == true){
                    oppRec.OwnerId = System.label.Digital_SalesManager;
                }            
                oppList.add(oppRec);
                
            }
        }
        
       
        
        if (!conList.isEmpty()) {
            update conList;
        }
        if (!accList.isEmpty()) {
            TriggerHandler.processedIds = new Set<Id>();
            update accList;
        }
        if(!oppList.isEmpty()){
            Update oppList;
        }

        system.debug('point: accList'+ accList);
        
        return  lcr;
    }
    
    /*
*Fetch All Opportunity without sharing to get all Opportunity in the system not just the records that shared with the logged in user.
*used on Opportunity trigger handler to check if there is already Opportunity existing in the system.
*/
    public static Map<Id,Opportunity> getAllOpportunitysByAccountsIds(Set<Id> accountsIDs){
        
        List<Opportunity> allOpportunity = [SELECT Id, AccountId, Account.Name, Account.RecordTypeId, Account.PersonMobilePhone, IsClosed, 
                                            Account.PersonEmail, Account.Email__c, Account.MobileNumber__c, Project__c, Offer__c, Name, CloseDate, StageName, createdDate, OwnerId 
                                            FROM Opportunity WHERE AccountId IN: accountsIDs AND IsClosed = false order by createdDate desc];
        
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
        
        for(Opportunity oppRec : allOpportunity){
            opportunityMap.put(oppRec.AccountId,oppRec);
        }
        return opportunityMap;
    }
    
    /*
*Fetch All Accounts without sharing to get all accounts in the system not just the records that shared with the logged in user.
*used on lead trigger handler to check if there is already account with the same lead information.
*/
    public static Map<String,Account> getAllAccounts(Set<String> uniqueKeys){
        
        Map<String,Account> allAccountsRecMap = new Map<String,Account>();
        
        List<Account> accountDetails = [Select firstName,MiddleName, lastName, PersonEmail, Phone, Id, createdDate, UniqueKey__c, MobileCountryCode__c, MobileNumber__c, Email__c
                                        From Account where UniqueKey__c in : uniqueKeys order by createdDate asc];
        
        
        System.debug('Point: accountDetails'+accountDetails);
        
        for(Account accountRec : accountDetails){ 
            System.debug('Point: accountRec'+accountRec);
            allAccountsRecMap.put(accountRec.UniqueKey__c,accountRec);
        }   
        return allAccountsRecMap ;
    }
    
    public static List<User> getUsersSimilerToUsername(String firstName, String lastName){
        
        List<User> usersWithSameUsername = new List<User>([Select Id, Name, Username From User Where Username LIKE : (firstName + lastName+'%') AND Username LIKE : ('%'+Constants.USERNAME_DOMAIN)]);
        
        return usersWithSameUsername ;
    }
    
    public static void changeSentToYardiField(Id leadId){
        
        Lead leadRecord = [Select SentToYardi__c From Lead where Id =: leadId];
        leadRecord.SentToYardi__c = true;
        update leadRecord;
    }

    public static void updateLastsalesOrderDate(List<Account> accountList){
        update accountList;
    }
    
    /*
public static Map<String,Map<String,String>> getLeadConversionMapping(){

//------ Object Name mapped with object api and lead api
Map<String,Map<String,String>> objectNameobjectLeadAPI = new Map<String,Map<String,String>>();

MetadataService.MetadataPort service = new MetadataService.MetadataPort();
service.SessionHeader = new MetadataService.SessionHeader_element();
service.SessionHeader.sessionId = UserInfo.getSessionId();
service.CallOptions = new MetadataService.CallOptions_element();
service.timeout_x = 120000;

List<MetadataService.LeadConvertSettings> leadConvertSettings = (List<MetadataService.LeadConvertSettings>) service.readMetadata('LeadConvertSettings', new List<String>{'LeadConvertSettings'}).getRecords();

for (MetadataService.LeadConvertSettings leadConvertSetting : leadConvertSettings) {
for (MetadataService.ObjectMapping objectMapping : leadConvertSetting.objectMapping) {
Map<String,String> objectAPILeadAPI = new Map<String,String>();
for (MetadataService.ObjectMappingField fieldMapping : objectMapping.mappingFields) {
if(objectNameobjectLeadAPI.containsKey(objectMapping.outputObject)){
objectAPILeadAPI = objectNameobjectLeadAPI.get(objectMapping.outputObject);
}
objectAPILeadAPI.put(fieldMapping.outputField,fieldMapping.inputField);
objectNameobjectLeadAPI.put(objectMapping.outputObject,objectAPILeadAPI);
}
}
}
System.debug('**objectNameobjectLeadAPI**' + objectNameobjectLeadAPI);
System.debug('**Account Fields**' + objectNameobjectLeadAPI.get('Account'));
System.debug('**Opportunity Fields**' + objectNameobjectLeadAPI.get('Opportunity'));
return objectNameobjectLeadAPI ; 
}
*/
    
    @AuraEnabled(cacheable=false)
    public static User createUserFromContact(String contactId, boolean isActive, String profile) {
        
        List<Contact> objectContactList = new List<Contact>([SELECT FirstName,LastName,Email,AccountId 
                                 FROM Contact Where Email <> null AND Id =: contactId LIMIT 1]);
        if(objectContactList.isEmpty()){
            return null;
        }
        Contact objectContact = objectContactList[0];
        system.debug('Request objectContact: '+ objectContact);
        
        List<Profile> pflist = new List<Profile>([SELECT Id, name FROM profile 
                      WHERE name=: profile LIMIT 1]);
        if(pflist.isEmpty()){
            return null;
        }
        Profile pf = pflist[0];
        system.debug('Request pf: '+ pf);
        String usernamebefore = String.valueOf(objectContact.Email).split('@')[0];
        
        //Adding 4 digit random number
        Integer user4Digits = (Integer)(Math.random() * 9000) + 1000;
        String userName = usernamebefore + user4Digits + Constants.USERNAME_DOMAIN;
        
        
        List<User> usersWithSameUsername = UtilitiesWithoutSharing.getUsersSimilerToUsername(userName, '');
        
        if(!usersWithSameUsername.isEmpty()){
            userName = usernamebefore + user4Digits + (usersWithSameUsername.size() + 1)  + Constants.USERNAME_DOMAIN;
        }

        String nickName = objectContact.LastName + '_'+Math.random();
        if(nickName.length() > 40){
            nickName = nickName.subString(nickName.length()-40);
        }
        
        // Added By Moh Sarfaraj for Bug BRP-5857
        String alias = String.valueOf(String.isNotBlank(objectContact?.FirstName) ? objectContact?.FirstName?.substring(0,1) : ''+ objectContact?.LastName?.substring(0,1) + Math.random());
		alias = alias.length() > 5 ? alias.subString(0,5) : alias;
        

        //Create user 
        User newCommunitiesUser = new User(contactId=objectContact.Id, 
                                           username=userName, 
                                           firstname=objectContact.FirstName,
                                           lastname=objectContact.LastName, 
                                           email=objectContact.Email,
                                           communityNickname = nickName,
                                           alias = alias,
                                           profileid = pf.Id, emailencodingkey='UTF-8',
                                           languagelocalekey='en_US', 
                                           localesidkey='en_US', IsActive=isActive,
                                           timezonesidkey='Asia/Dubai');   
        
        system.debug('Request newCommunitiesUser: '+ newCommunitiesUser);
        
        insert newCommunitiesUser;
        return newCommunitiesUser;
    }
    
    /*
----- used with addAgentModel
*/
     // Added By Moh Sarfaraj for BPM-497   
    public static User updateExistingCommunityUser(String contactId, boolean isActive, String profile) {

        List<Contact> objectContactList = new List<Contact>([SELECT FirstName,LastName,Email,AccountId 
                                 FROM Contact Where Email <> null AND Id =: contactId LIMIT 1]);

        List<User> listUser = [SELECT Id FROM User WHERE ContactId = : contactId LIMIT 1];
        if(objectContactList.isEmpty() || listUser == null || listUser.isEmpty()){
            return null;
        }

        Contact objectContact = objectContactList[0];
        system.debug('Request objectContact: '+ objectContact);
        
        List<Profile> pflist = new List<Profile>([SELECT Id, name FROM profile 
                      WHERE name=: profile LIMIT 1]);
        if(pflist.isEmpty()){
            return null;
        }
        Profile pf = pflist[0];

        String usernamebefore = String.valueOf(objectContact.Email).split('@')[0];
        
        //Adding 4 digit random number
        Integer user4Digits = (Integer)(Math.random() * 9000) + 1000;
        String userName = usernamebefore + user4Digits + Constants.USERNAME_DOMAIN;
        
        
        List<User> usersWithSameUsername = UtilitiesWithoutSharing.getUsersSimilerToUsername(userName, '');
        
        if(!usersWithSameUsername.isEmpty()){
            userName = usernamebefore + user4Digits + (usersWithSameUsername.size() + 1)  + Constants.USERNAME_DOMAIN;
        }

        String nickName = objectContact.LastName + '_'+Math.random();
        if(nickName.length() > 40){
            nickName = nickName.subString(nickName.length()-40);
        }
        
        // Added By Moh Sarfaraj for Bug BRP-5857
        String alias = String.valueOf(String.isNotBlank(objectContact?.FirstName) ? objectContact?.FirstName?.substring(0,1) : ''+ objectContact?.LastName?.substring(0,1) + Math.random());
		alias = alias.length() > 5 ? alias.subString(0,5) : alias;
        

        //Update user 
        User newCommunitiesUser = new User(Id = listUser[0].Id,
                                           contactId=objectContact.Id, 
                                           username=userName, 
                                           firstname=objectContact.FirstName,
                                           lastname=objectContact.LastName, 
                                           email=objectContact.Email,
                                           communityNickname = nickName,
                                           alias = alias,
                                           profileid = pf.Id, emailencodingkey='UTF-8',
                                           languagelocalekey='en_US', 
                                           localesidkey='en_US', IsActive=isActive,
                                           timezonesidkey='Asia/Dubai');   
        
        system.debug('Request newCommunitiesUser: '+ newCommunitiesUser);
        
        update newCommunitiesUser;
        return newCommunitiesUser;
    }
    @AuraEnabled
    public static String createAgent(Map<String, Object> agentInfoObject){
        
        Lead newLead = new Lead();
        
        Id brokerAgencyRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.BROKER_AGENCY_ACCOUNT_RT).getRecordTypeId();
        Id brokerAgentRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Constants.BROKER_AGENT).getRecordTypeId();
        
        Contact newContect = new Contact();
        User newUser = new User();
        
        newContect.RecordTypeId = brokerAgentRT;
        system.debug('agentInfoObject:' + agentInfoObject);
        system.debug('agentInfoObject:' + agentInfoObject.get('contactId'));
        
        if(agentInfoObject.get('contactId') != null && agentInfoObject.get('contactId') != '' )
        {
            newContect.Id = (Id)agentInfoObject.get('contactId');
            if(agentInfoObject.get('userId') != null && agentInfoObject.get('userId') != ''){
                newUser.Id = (Id)agentInfoObject.get('userId');
            }
        }
        else{
            newContect.MobilePhone = (String)agentInfoObject.get('phoneNumber');
            newContect.MobilePhone__c = (String)agentInfoObject.get('phoneNumber');
            newContect.Phone = ((String)agentInfoObject.get('phoneNumber'));
            newContect.Email = ((String)agentInfoObject.get('emailId'));
            
            newUser.MobilePhone = (String)agentInfoObject.get('phoneNumber');
            newUser.Email = ((String)agentInfoObject.get('emailId'));
        }
        
        newContect.Salutation = (String)agentInfoObject.get('title');
        newUser.Title = (String)agentInfoObject.get('title');
        
        newContect.AccountId = (String)agentInfoObject.get('agencyName');
        //newContect.Birthdate = date.valueOf((String)agentInfoObject.get('birthdate'));
        if(agentInfoObject.containsKey('birthdate') && ((String) agentInfoObject.get('birthdate') != null || (String) agentInfoObject.get('birthdate') != '')){
            newContect.Birthdate = date.valueOf((String)agentInfoObject.get('birthdate'));
        }
        newContect.BrokerType__c = (String)agentInfoObject.get('role');
        
        newContect.FirstName = (String)agentInfoObject.get('firstName');
        newContect.LastName = (String)agentInfoObject.get('lastName');
        
        newUser.FirstName = (String)agentInfoObject.get('firstName');
        newUser.LastName = (String)agentInfoObject.get('lastName');
        
        newContect.Email = ((String)agentInfoObject.get('emailId'));
        newContect.EmailAddress__c = ((String)agentInfoObject.get('emailId'));
        newUser.Email = ((String)agentInfoObject.get('emailId'));
        
        newContect.MobilePhone = ((String)agentInfoObject.get('countryCode')+(String)agentInfoObject.get('phoneNumber'));
        newContect.Phone = ((String)agentInfoObject.get('countryCode')+(String)agentInfoObject.get('phoneNumber'));
        newContect.MobilePhone__c = ((String)agentInfoObject.get('phoneNumber'));
        newContect.MobileCountryCode__c = ((String)agentInfoObject.get('countryCode'));
        newContect.MobileNumberEnc__c = ((String)agentInfoObject.get('countryCode')+(String)agentInfoObject.get('phoneNumber'));
        
        newUser.MobilePhone = ((String)agentInfoObject.get('countryCode')+(String)agentInfoObject.get('phoneNumber'));
        
        newContect.MailingCity = (String)agentInfoObject.get('residentStatus');
        newUser.City = (String)agentInfoObject.get('residentStatus');

        newContect.NationalIdNumber__c = (String)agentInfoObject.get('emiratesID');
        newContect.NationalIdExpiryDate__c = (String)agentInfoObject.get('expiryDate') != '' && (String)agentInfoObject.get('expiryDate') != null ? date.valueOf((String)agentInfoObject.get('expiryDate')) : null;
        //newContect.Line_Manager_Email__c = ((String)agentInfoObject.get('linemanagerEmail'));
        //newContect.Line_Manager_Name__c = ((String)agentInfoObject.get('linemanagerName'));
        // Added By Moh Sarfaraj for BPE-110
        newContect.PrimaryOwner__c = (Boolean)agentInfoObject.get('primaryOwner');
        newContect.PrimaryAgencyAdmin__c = (Boolean)agentInfoObject.get('primaryAgencyAdmin');
        newContect.Nationality__c = (String)agentInfoObject.get('nationality');
         
        // Added By Moh Sarfaraj for BPE-526
        newContect.PassportNumber__c = (String)agentInfoObject.get('passportNumber');
        newContect.PassportExpiryDate__c = (String)agentInfoObject.get('passportExpiryDate') != '' && (String)agentInfoObject.get('passportExpiryDate') != null ? date.valueOf((String)agentInfoObject.get('passportExpiryDate')) : null;
         
        //Below code is added by Tharun
        Id agencyID = (Id)(String)agentInfoObject.get('agencyName');
        if(agencyID.getSObjectType() == Account.getSObjectType()){
            Id accountOwnerId = [SELECT Id, OwnerId FROM Account WHERE Id =:agencyID].OwnerId;
            if(!String.isblank(accountOwnerId)){
                newContect.AccountOwner__c = accountOwnerId;
            }
        }
        //Below code is added by Tharun
        if(newContect.Id != null){
            
            if(Approval.isLocked(newContect.id)){
                Approval.unlock(newContect.id);
            }
            
            /*String profile = Constants.AGENCY_USER_PROFILE;
            
            if(Constants.AGENCY_ADMIN_PROFILE.equals((String)agentInfoObject.get('role'))){
                profile = Constants.AGENCY_ADMIN_PROFILE;
            }*/
            // String profile = Constants.AGENCY_USER_PROFILE_LOGIN;
            
            // if((Constants.AGENCY_ADMIN_PROFILE.equals((String)agentInfoObject.get('role'))) || (Constants.AGENCY_ADMIN_PROFILE_LOGIN.equals((String)agentInfoObject.get('role')))){
            //     profile = Constants.AGENCY_ADMIN_PROFILE_LOGIN;
            // }
            
            // Profile pf = [SELECT Id, name FROM profile 
            //               WHERE name=: profile LIMIT 1];
            
            // newUser.ProfileId = pf.Id;
            // newContect.AgentStatus__c = Constants.PENDING_VERIFICATION;
            update newContect;
            // // Added by Tharun
            // Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            // req1.setObjectId(newContect.Id);
            // Approval.ProcessResult result = Approval.process(req1);
            // // Added by Tharun
            // if(!String.isBlank(newUser.Id)){
            //     updateUserInFutureMethod(newUser.Id, newUser.Title, newUser.FirstName, newUser.LastName, newUser.Email, newUser.MobilePhone, newUser.City, profile);
            // }
        } else{
            
            List<User> usersWithSameEmail = new List<User>();
            usersWithSameEmail =  [Select Id, Name, Email From User Where Email =: newUser.Email AND isActive = true];
            
            List<Contact> userContactWithSameEmail = new List<Contact>();
            userContactWithSameEmail = [Select Id, Name, Email From Contact Where Email =: newUser.Email AND Account.RecordTypeId =: brokerAgencyRT AND AgentStatus__c != 'In Active'];
            
            if((usersWithSameEmail != null && usersWithSameEmail.size() > 0) || (userContactWithSameEmail != null && userContactWithSameEmail.size() > 0)){
                return 'Duplicate';
            }
            
            newContect.AgentStatus__c = Constants.PENDING_VERIFICATION;
            insert newContect;
            
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setObjectId(newContect.id);
            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
        }
        return newContect.Id;
    }
    
    @future
    public static void updateUserInFutureMethod(String userId, String Title, String FirstName, String LastName, String Email, String MobilePhone, String City, String profileName){
        
        User newUser = new User();
        
        newUser.Id = userId;
        newUser.Title = title;
        newUser.FirstName = FirstName;
        newUser.LastName = LastName;
        newUser.Email = Email;
        newUser.MobilePhone = MobilePhone;
        newUser.City = City;
        
        /*String profile = Constants.AGENCY_USER_PROFILE;
        
        if(Constants.AGENCY_ADMIN_PROFILE.equals(profileName)){
            profile = Constants.AGENCY_ADMIN_PROFILE;
        }*/
        String profile = Constants.AGENCY_USER_PROFILE_LOGIN;
        
        if((Constants.AGENCY_ADMIN_PROFILE.equals(profileName)) || (Constants.AGENCY_ADMIN_PROFILE_LOGIN.equals(profileName))){
            profile = Constants.AGENCY_ADMIN_PROFILE_LOGIN;
        }
        
        // Profile pf = [SELECT Id, name FROM profile 
        //               WHERE name=: profile LIMIT 1];
        
        // newUser.ProfileId = pf.Id;
        
        update newUser;
    }
    
    /*
*Create Contact By Agency Admin
*/
    public static List<Contact> createAgencyContact(List<AgencyTeam__c> agencyTeam, Id accountId, String brokerType, Boolean isRequireToCheckExistingContacts) {
        // Added By Moh Sarfaraj for BPM-497 starts
        Map<String,Contact> mapExistingContactEmailToContact = new Map<String,Contact>();
        Map<String,Contact> mapExitsingContactMobileToContact = new Map<String,Contact>();

        if(isRequireToCheckExistingContacts){
            for(Contact eachContact : [SELECT Id,Email,EmailAddress__c,Phone,MobilePhone,MobilePhone__c,PrimaryAgencyAdmin__c,BrokerType__c FROM Contact WHERE 
                                      RecordTypeId = :ALD_Constants.BROKER_AGENT_RT AND BrokerType__c = :brokerType AND 
                                      AccountId = :accountId]){

                if(brokerType == Constants.AGENCY_ADMIN && eachContact.PrimaryAgencyAdmin__c){
                    mapExistingContactEmailToContact.put(Constants.AGENCY_ADMIN, eachContact);
                }
                else{
                    if(String.isNotBlank(eachContact.Email)){
                        mapExistingContactEmailToContact.put(eachContact.Email, eachContact);
                    }else if(String.isNotBlank(eachContact.EmailAddress__c)){
                        mapExistingContactEmailToContact.put(eachContact.EmailAddress__c, eachContact);
                    }

                    if(String.isNotBlank(eachContact.MobilePhone__c)){
                        mapExitsingContactMobileToContact.put(eachContact.MobilePhone__c, eachContact);
                    }else if(String.isNotBlank(eachContact.MobilePhone)){
                        mapExitsingContactMobileToContact.put(eachContact.MobilePhone, eachContact);
                    }else if(String.isNotBlank(eachContact.Phone)){
                        mapExitsingContactMobileToContact.put(eachContact.Phone, eachContact);
                    }
                }
            }
        }
        // Added By Moh Sarfaraj for BPM-497 end

        List<Contact> contactToBeInsert = new List<Contact>();
        System.debug('Point: agencyTeam: '+agencyTeam);
        for(AgencyTeam__c agency : agencyTeam){
            Contact newContact = new Contact();
            // Added By Moh Sarfaraj for BPM-497 starts
            if(brokerType == Constants.AGENCY_ADMIN && mapExistingContactEmailToContact.containsKey(Constants.AGENCY_ADMIN)){
                newContact.Id = mapExistingContactEmailToContact.get(Constants.AGENCY_ADMIN).Id;
            }else {
                if(agency.EmailAddress__c != null && mapExistingContactEmailToContact.containsKey(agency.EmailAddress__c)){
                    newContact.Id = mapExistingContactEmailToContact.get(agency.EmailAddress__c.trim()).Id;
                }
    
                if(String.isBlank(newContact?.Id) && mapExitsingContactMobileToContact.containsKey(agency.MobileNumber__c)){
                    newContact.Id = mapExitsingContactMobileToContact.get(agency.MobileNumber__c.trim()).Id;
                }
            }
            // Added By Moh Sarfaraj for BPM-497 end

            String agencyName = agency.Name.replaceAll('\\s+',' ');
            if (agencyName.split(' ').size() == 2) {
                newContact.FirstName = agencyName.split(' ')[0];
                newContact.LastName = agencyName.split(' ')[1];
            } else if (agencyName.split(' ').size() == 1) {
                newContact.LastName = agencyName;
            } else {
                newContact.FirstName = agencyName.split(' ')[0];
                newContact.MiddleName = agencyName.split(' ')[1];
                newContact.LastName = agencyName.split(' ')[2];
            }
            newContact.AccountId = accountId;
            newContact.Title = agency.Title__c;
            newContact.Email = agency.EmailAddress__c;
            newContact.EmailAddress__c = agency.EmailAddress__c;
            
            // Uncommented By Moh Sarfaraj
            newContact.MobileCountryCode__c = agency.MobileCountryCode__c;
            newContact.MobilePhone__c = agency.MobileNumber__c;
            newContact.MobilePhone = agency.MobileNumber__c;
            newContact.Phone = agency.MobileNumber__c;
            // Added By Moh Sarfaraj for BPE-110
            newContact.PrimaryOwner__c = agency.PrimaryOwner__c;
            newContact.PrimaryAgencyAdmin__c = agency.PrimaryAgencyAdmin__c;
            // Commented By Moh Sarfaraj
            // if(agency.MobileNumber__c != null){
            //     String agencyMobile = agency.MobileNumber__c;
            //     newContact.MobileCountryCode__c = agency.MobileCountryCode__c <> null ? agency.MobileCountryCode__c: (agencyMobile.split(' ').size() > 1 ? agencyMobile.split(' ')[0] : ''); 
            //     newContact.MobilePhone__c = agencyMobile.split(' ').size() > 1 ? agencyMobile.remove(agencyMobile.split(' ')[0]).replaceAll('\\s+','') : agencyMobile.replaceAll('(\\s+)', '');
            //     newContact.MobilePhone = agencyMobile.replaceAll('(\\s+)', '');
            //     newContact.Phone = agencyMobile.replaceAll('(\\s+)', '');
            // }
            
            if(agency.ServiceRequest__r.BrokerManager__c != null){
                newContact.OwnerId = agency.ServiceRequest__r.BrokerManager__c;
                // Below line added by Tharun
                newContact.AccountOwner__c = agency.ServiceRequest__r.BrokerManager__c;
            }
            
            newContact.MailingCountry = agency.Country__c;
            newContact.BrokerType__c = brokerType;
            newContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Constants.BROKER_AGENT).getRecordTypeId();
            
            contactToBeInsert.add(newContact);
        }
        upsert contactToBeInsert;  // Added By Moh Sarfaraj for BPM-497
        return contactToBeInsert;       
    }

      /*
  * Release units when the Reservation or Booking is cancelled
  */
  /*public static void makeUnitsAvailable(Set<Id> unitIds) {

    List<Unit__c> unitList = new List<Unit__c>();
        
    for(Id unitId : unitIds){
        Unit__c unitRecord = new Unit__c();
        unitRecord.Id = unitId ; 
        unitRecord.Status__c = Constants.UNIT_STATUS_AVAILABLE;
        unitRecord.LockedBy__c = null;
        unitRecord.LockTime__c = null;
        unitRecord.LockExpiryTime__c = null;
        unitRecord.RelatedOpportunity__c = null;
        unitRecord.RelatedSalesOrder__c = null;
        unitList.add(unitRecord);
    }

    if(unitList !=null && unitList.size()>0){
      update unitList; 
    }
     
  }*/
    
    //Commenting for Deployment 
  /*  
    public static void updatesalesOrderSyncStatuses(List<SalesOrder__c> salesOrderListToUpdate){
        update salesOrderListToUpdate;
    }
*/
    /*Method to get mobile number of the Lead in without sharing*/
    @AuraEnabled(cacheable=false)
    public static String getMobile(id leadid){
        Lead leaddet = new Lead();
        String mob = '';
        if(leadid!=null){
            leaddet = [select MobilePhone from lead where id = :leadid];
            mob = leaddet.MobilePhone;
        }
        system.debug('Mobile:' +mob);
        return mob;
    }

    /*Method to get mobile number of the sobject (Account/Lead/Contact) in without sharing*/
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getMobileSobject(id recordid, String sobjectname){
        Map<String,String> moblan = new Map<String,String>();
        String mob = '';
        String langpref = 'en';
        if(recordid!=null){
            if(sobjectname =='Lead'){
                Lead LeadRecord = [Select MobilePhone, LanguagePreference__c from lead where id =:recordid];
                mob = LeadRecord.MobilePhone;
                langpref = (LeadRecord.LanguagePreference__c != 'Arabic') ? 'en':'ar';
            } else if (sobjectname =='Account'){
                Account AccountRecord = [Select PersonMobilePhone,LanguagePreference__pc from account where id =:recordid];
                mob = AccountRecord.PersonMobilePhone;
                langpref = (AccountRecord.LanguagePreference__pc != 'Arabic') ? 'en':'ar';
            } else if (sobjectname =='Contact'){
                Contact ContactRecord = [Select MobilePhone,LanguagePreference__c from contact where id =:recordid];
                mob = ContactRecord.MobilePhone;
                langpref = (ContactRecord.LanguagePreference__c != 'Arabic') ? 'en':'ar';
            }
        }
        moblan.put(mob,langpref);
        system.debug('Mobile:' +mob);
        //return mob;
        return moblan;
    }
    //Added by Chirag
    @AuraEnabled
    public static void addacocuntTeamMember(String recordId){
        
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        system.debug('ProfileName'+profileName);
        if(profileName == 'Sales Manager' || Test.isRunningTest()){
            //List<AccountTeamMember> act = [SELECT Id,UserId FROM AccountTeamMember WHERE UserId =: UserInfo.getUserId() ];
            List<UserRecordAccess> userAccess = new List<UserRecordAccess>();
            userAccess = [SELECT RecordId FROM UserRecordAccess WHERE HasEditAccess = TRUE AND UserId =:UserInfo.getUserId() AND RecordId =:recordId ];
            if(userAccess.isEmpty() || Test.isRunningTest()){
//                if(act.size() ==0){
                    AccountTeamMember accountMember = new AccountTeamMember();
                    accountMember.AccountId = recordId;
                    accountMember.UserId = UserInfo.getUserId();
                    accountMember.CaseAccessLevel = Constants.NONE_ACCESS;
                    accountMember.OpportunityAccessLevel = Constants.NONE_ACCESS;
                    accountMember.AccountAccessLevel = 'Edit';
                    accountMember.TeamMemberRole = Constants.TEAM_ROLE_SALES_MANAGER;
                    insert accountMember;
//                }  
            }
        }
    }
     public static Map<String, List<DuplicateAccountWrapper>> findDuplicateAccountsByEmail(Set<String> emails) {
        if(System.Label.DuplicateAccountEnable.trim().toUpperCase() == 'FALSE'){
            return new Map<String, List<DuplicateAccountWrapper>>();
        }
        Set<String>EmailSet = new Set<String>();
        for(String st : emails){
            String emailString = st.toLowerCase();
            System.debug(emailString);
            EmailSet.add(emailString);
        }
        Map<String, List<DuplicateAccountWrapper>> dupeWrapperMap = new Map<String, List<DuplicateAccountWrapper>>();
        
        String salesOrderWhrClause = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
        String accountWhrClause = ' ( RecordType.Name = \'' + Constants.PERSON_ACCOUNT_RT + '\')';
        String query = 'SELECT Id, Name, CustomerVertical__c, Sync_with_SFMC__pc, Sync_with_SFMC__c, RecordTypeId, PersonEmail,EmailApprovalsReason__c,PassportNumber__pc,KYC_Validity_Status__c,ResidentStatus__pc, AccountNumber__c,CustomerType__c,SkipLiveAldarReason__c,CustomerSubType__c,NationalIdNumber__pc,EligibleForMerge__c,MasterAccount__r.Name,ERPID__c,MasterAccount__c,PersonBirthdate,PassportExpiryDate__pc,BlacklistReason__c,SkipDuplicateApprovalStatus__c,VIPClass__c,CustomerAppWebUser__c,Nationality__pc,PersonMobilePhone,FastTrackedAccount__c,ScreeningStatus__c,NationalIdExpiryDate__pc, (SELECT Id,Name FROM Opportunity_Units__r WHERE '+salesOrderWhrClause+' ),(SELECT Id,LastModifiedDate,DocumentType__c FROM Documents__r WHERE (DocumentType__c=\'Signed KYC Form\' OR DocumentType__c=\'Signed CIS Sheet\') AND Status__c =\'Uploaded\' ORDER BY LastModifiedDate ASC)  FROM Account WHERE '+accountWhrClause+' AND PersonEmail IN :EmailSet AND MergedAccount__c= false ORDER BY CreatedDate DESC';                
        System.debug('Print acc query '+query);
        //Execute the query 
        List<Account> queriedAccounts = Database.query(query);
        
        if(!queriedAccounts.isEmpty() && queriedAccounts.size() > 0){
            
            for(Account ac : queriedAccounts){
                DuplicateAccountWrapper wrapper = new DuplicateAccountWrapper();
                wrapper.account = ac;
                wrapper.salesOrderCount = ac.Opportunity_Units__r.size() > 0 ? ac.Opportunity_Units__r.size() : 0;
                
                if(dupeWrapperMap.containsKey(ac.PersonEmail)){
                    dupeWrapperMap.get(ac.PersonEmail).add(wrapper);
                }else{
                    List<DuplicateAccountWrapper> wrapperList = new List<DuplicateAccountWrapper>{wrapper};
                    dupeWrapperMap.put(ac.PersonEmail, wrapperList);
                }
            }
        }
        
        return dupeWrapperMap;
    } 
     public static Map<String, List<DuplicateAccountWrapper>> findDuplicateAccountsByEmirateIdPassport(String emirateIds, String passPortNumber, String nationality, String dateOfBirth) {
        Map<String, List<DuplicateAccountWrapper>> dupeWrapperMap = new Map<String, List<DuplicateAccountWrapper>>();
        //Set<Id> contentDocumentIds = new Set<Id>();
        List<Id> contentVersionIds = new List<Id>();
        //list<string> ContentVersionList = new List<string>();
        if(System.Label.DuplicateAccountEnable.trim().toUpperCase() == 'FALSE'){
            return dupeWrapperMap;
        }
        
        system.debug('passPortNumber '+passPortNumber);
        String salesOrderWhrClause = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
        String accountWhrClause = ' ( RecordType.Name = \'' + Constants.PERSON_ACCOUNT_RT + '\')';
        String query = '';
        if(!String.isBlank(emirateIds))
            query = 'SELECT Id, Name, PersonEmail,PassportNumber__pc,EmailApprovalsReason__c,KYC_Validity_Status__c,ResidentStatus__pc, AccountNumber__c,CustomerType__c,CustomerSubType__c,NationalIdNumber__pc,SkipDuplicateApprovalStatus__c,EligibleForMerge__c,MasterAccount__r.Name,ERPID__c,MasterAccount__c,PersonBirthdate,PassportExpiryDate__pc,BlacklistReason__c,VIPClass__c,Nationality__pc,PersonMobilePhone,ScreeningStatus__c,NationalIdExpiryDate__pc,SkipLiveAldarReason__c,CustomerAppWebUser__c, (SELECT Id,Name FROM Opportunity_Units__r WHERE '+salesOrderWhrClause+' ),(SELECT Id,LastModifiedDate,DocumentType__c FROM Documents__r WHERE (DocumentType__c=\'Signed KYC Form\' OR DocumentType__c=\'Signed CIS Sheet\') AND Status__c =\'Uploaded\' ORDER BY LastModifiedDate ASC) FROM Account WHERE '+accountWhrClause+' AND NationalIdNumber__pc = :emirateIds AND ResidentStatus__pc = \'Resident\' AND MergedAccount__c= false ORDER BY CreatedDate DESC';
        else if(!String.isBlank(passPortNumber))
            query = 'SELECT Id, Name, PersonEmail,PassportNumber__pc,EmailApprovalsReason__c,KYC_Validity_Status__c,ResidentStatus__pc, AccountNumber__c,CustomerType__c,CustomerSubType__c,NationalIdNumber__pc,SkipDuplicateApprovalStatus__c,EligibleForMerge__c,MasterAccount__r.Name,ERPID__c,MasterAccount__c,PersonBirthdate,PassportExpiryDate__pc,BlacklistReason__c,VIPClass__c,Nationality__pc,PersonMobilePhone,ScreeningStatus__c,NationalIdExpiryDate__pc,SkipLiveAldarReason__c,CustomerAppWebUser__c, (SELECT Id,Name FROM Opportunity_Units__r WHERE '+salesOrderWhrClause+' ),(SELECT Id,LastModifiedDate,DocumentType__c FROM Documents__r WHERE (DocumentType__c=\'Signed KYC Form\' OR DocumentType__c=\'Signed CIS Sheet\') AND Status__c =\'Uploaded\' ORDER BY LastModifiedDate ASC) FROM Account WHERE '+accountWhrClause+' AND PassportNumber__pc = \''+passPortNumber+'\' AND Nationality__pc =: nationality AND ResidentStatus__pc = \'Non-Resident\' AND PersonBirthdate ='+dateOfBirth+' AND MergedAccount__c= false ORDER BY CreatedDate DESC';
        system.debug('dateOfBirth = '+dateOfBirth);
        System.debug('Print acc query '+query);
        //Execute the query
        List<Account> queriedAccounts = Database.query(query);
        system.debug('queriedAccounts '+queriedAccounts);
        if (!queriedAccounts.isEmpty() && queriedAccounts.size() > 0) {
            
            
            for (Account ac : queriedAccounts) {
                DuplicateAccountWrapper wrapper = new DuplicateAccountWrapper();
                wrapper.account = ac;
                wrapper.salesOrderCount = ac.Opportunity_Units__r != null ? ac.Opportunity_Units__r.size() : 0;
                
                
                
                if (ac.ResidentStatus__pc == 'Resident' && dupeWrapperMap.containsKey(ac.NationalIdNumber__pc)) {
                    dupeWrapperMap.get(ac.NationalIdNumber__pc).add(wrapper);
                } else if (ac.ResidentStatus__pc == 'Resident'){
                    dupeWrapperMap.put(ac.NationalIdNumber__pc, new List<DuplicateAccountWrapper>{wrapper});
                }
                if (ac.ResidentStatus__pc == 'Non-Resident' && dupeWrapperMap.containsKey(ac.PassportNumber__pc+ac.Nationality__pc+dateOfBirth)) {
                    dupeWrapperMap.get(ac.PassportNumber__pc.toUpperCase()+ac.Nationality__pc+dateOfBirth).add(wrapper);
                } else if(ac.ResidentStatus__pc == 'Non-Resident'){
                    dupeWrapperMap.put(ac.PassportNumber__pc.toUpperCase()+ac.Nationality__pc+dateOfBirth, new List<DuplicateAccountWrapper>{wrapper});
                }
            }
        }
        
        
        return dupeWrapperMap;
    }
   
    
    public class DuplicateAccountWrapper {
        @AuraEnabled
        public Account account{get;set;}
        @AuraEnabled
        public Integer salesOrderCount{get;set;}
        @AuraEnabled
        public String SignedKYCFormDate{get;set;}
        @AuraEnabled
        public String SignedCISFormDate{get;set;}
    }
    // SSC-697, Duplicate Account check based on Email or Mobile Number: Bashim
    // In the below method we have added one more parameter mobile number to get duplicate account based on mobile number
    @AuraEnabled
    public static List<DuplicateAccountWrapper> checkduplicateEmail(String emailId, String mobileNumber){
        String emailfield = emailId.toLowerCase();
        List<UtilitiesWithoutSharing.DuplicateAccountWrapper> AccountMapEmailandMobileNumber = UseExistingAccount.findDuplicateAccountsByEmailAndMobileNumber(new Set<String> {emailfield},new Set<String>{mobileNumber});// created method for both email and mobile
        return AccountMapEmailandMobileNumber;
         
    }
     @AuraEnabled
    public static void sentforApproval(String AccId,String OtherReason, String ExReason){
        UtilitiesWithoutSharing.addacocuntTeamMember(AccId);
        Id acId = AccId;
        Account acc = new Account();
        acc.Id= AccId;
        acc.EmailApprovalsReason__c = ExReason;
        acc.EmailApprovalsOtherReason__c = OtherReason == null ? '':OtherReason;
        update acc;
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
       
        if(profileName == 'Sales Manager' ||profileName == 'Sales Admin'|| Test.isRunningTest()){
            User us =[SELECT ID,ManagerId FROM User WHERE Id=:UserInfo.getUserId()];
            AccountShare  shareAcc = new AccountShare();
            shareAcc.AccountId = AccId;
            shareAcc.UserOrGroupId = us.ManagerId;
            shareAcc.AccountAccessLevel = 'edit';
            shareAcc.OpportunityAccessLevel = 'read';
            shareAcc.CaseAccessLevel = 'read';
            shareAcc.RowCause = Schema.LeadShare.RowCause.Manual;
            insert shareAcc;
        }
        //ProcessDefinition pd =[SELECT Id, Name, DeveloperName, Type, Description, TableEnumOrId, LockType, State, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp FROM ProcessDefinition WHERE DeveloperName='Email_Exceptional_Approvals_Account'];
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(acId);
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Email_Exceptional_Approvals_Account2');
        req1.setSkipEntryCriteria(true);
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        Approval.UnlockResult unlockResultList = Approval.unlock(acc, false);
    }
    @AuraEnabled(cacheable=true)
    public static  List<DuplicateAccountWrapper> getduplicateAccountList(String recordId){
        try {
            Id recroddataId = recordId;
            String emailid = '';
            String sObjName = recroddataId.getSObjectType().getDescribe().getName();
            if(sObjName == 'Case'){
                Case cs = [SELECT Id,Account.PersonEmail from Case WHERE Id =:recordId ];
                emailid = cs.Account.PersonEmail;
            }else{
                Account acc = [select Id,PersonEmail FROM Account WHERE Id=:recordId LIMIT 1];
                emailid = acc.PersonEmail;
            }
            Map<String,List<DuplicateAccountWrapper>> AccountMap = findDuplicateAccountsByEmail(new Set<String>{emailid});
            List<Account> accList =new List<Account>();
            for(String str :AccountMap.keySet()){
                for(DuplicateAccountWrapper dup :AccountMap.get(str)){
                    accList.add(dup.account);
                }
            }
            Map<String, List<DuplicateAccountWrapper>> dupeWrapperMap = new Map<String, List<DuplicateAccountWrapper>>();
            if(!accList.isEmpty() && accList.size() >0){
                Map<Id, List<Document__c>> accountToDocumentsMap = new Map<Id, List<Document__c>>();
                Set<Id> documentIds = new Set<Id>();

                for (Account ac : accList) {
                    if (ac.Documents__r != null) {
                        accountToDocumentsMap.put(ac.Id, ac.Documents__r);
                        for (Document__c doc : ac.Documents__r) {
                            if (doc.DocumentType__c == 'Signed KYC Form' || doc.DocumentType__c == 'Signed CIS Sheet') {
                                documentIds.add(doc.Id);
                            }
                        }
                    }
                }
            
                Map<Id, List<ContentDocumentLink>> documentToLinksMap = new Map<Id, List<ContentDocumentLink>>();
                Set<Id> contentDocumentIds = new Set<Id>();
                if(documentIds.size() >0){
                    for (ContentDocumentLink cdl : [
                        SELECT ContentDocumentId, LinkedEntityId,SystemModstamp
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId IN :documentIds ORDER BY SystemModstamp DESC
                    ]) {
                        if (!documentToLinksMap.containsKey(cdl.LinkedEntityId)) {
                            documentToLinksMap.put(cdl.LinkedEntityId, new List<ContentDocumentLink>());
                        }
                        documentToLinksMap.get(cdl.LinkedEntityId).add(cdl);
                        contentDocumentIds.add(cdl.ContentDocumentId);
                    }
                } 

                for (Account ac : accList) {
                    DuplicateAccountWrapper wrapper = new DuplicateAccountWrapper();
                    wrapper.account = ac;
                    wrapper.salesOrderCount = ac.Opportunity_Units__r != null ? ac.Opportunity_Units__r.size() : 0;
                    
                    if (accountToDocumentsMap.containsKey(ac.Id) && accountToDocumentsMap.get(ac.Id) != null) {
                        for (Document__c doc : accountToDocumentsMap.get(ac.Id)) {
                            List<ContentDocumentLink> cdlList = documentToLinksMap.get(doc.Id);
                            
                            if (cdlList != null && !cdlList.isEmpty()) {
                                    if (doc.DocumentType__c == 'Signed KYC Form') {
                                        wrapper.SignedKYCFormDate = cdlList[0].SystemModstamp.format();
                                    } else if (doc.DocumentType__c == 'Signed CIS Sheet') {
                                        wrapper.SignedCISFormDate = cdlList[0].SystemModstamp.format();
                                    }
                            }
                        }
                    }
                    
                 
                    if (dupeWrapperMap.containsKey(ac.PersonEmail)) {
                        dupeWrapperMap.get(ac.PersonEmail).add(wrapper);
                    } else {
                        dupeWrapperMap.put(ac.PersonEmail, new List<DuplicateAccountWrapper>{wrapper});
                    }
                }

        }
            
            
            return dupeWrapperMap.get(emailid);
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }
    @AuraEnabled
    public static void createMasterAccount(String selectedId,String recordId){
        Id recroddataId = recordId;
        String sObjName = recroddataId.getSObjectType().getDescribe().getName();
        if(sObjName == 'Case'){
            Case cas = [SELECT Id,OwnerId FROM Case WHERE Id =:recordId];
            Case cs = new Case();cs.Id = recordId;cs.AccountMergeStatus__c = 'Submitted for Merge';
            String ownerId = cas.OwnerId;
            if(ownerId != null && ownerId.startsWithIgnoreCase('005')){
            }else{ cs.OwnerId = UserInfo.getUserId();
            }update cs;
        }
        
        Account acc = [select Id,PersonEmail FROM Account WHERE Id=:selectedId];
        Map<String,List<DuplicateAccountWrapper>> AccountMap = findDuplicateAccountsByEmail(new Set<String>{acc.PersonEmail});
        List<Account> accList = new List<Account>();
        for(DuplicateAccountWrapper dp: AccountMap.get(acc.PersonEmail)){
            if(dp.account.Id != selectedId || Test.isRunningTest()){
                Account accupdate = new Account();
                accupdate.Id = dp.account.Id;
                accupdate.EligibleForMerge__c = true;
                accupdate.MasterAccount__c = selectedId;
                accupdate.Sync_with_SFMC__pc = true;//Added by Chirag SFMC 05/08/2024
                accupdate.DuplicateConfirmedBy__c = UserInfo.getUserId();
                accupdate.DuplicateConfirmedDate__c = System.today();
                accList.add(accupdate);
            }
        }
        if(!Test.isRunningTest()){
        update accList;
        }
        List<Group> complianceGroupList = [SELECT Id,(SELECT UserOrGroupId, UserOrGroup.Name FROM GroupMembers WHERE UserOrGroupId =:UserInfo.getUserId()) FROM Group WHERE Name = 'Compliance Group'];
        
        if((complianceGroupList.size() >0 && complianceGroupList[0].GroupMembers.size() >0)){
            Case newCase         = CustomerProfileWebservice.createCaseHelper(new List<Account>{acc}, true);
            newCase.CustomerComment__c  = null;newCase.Origin = 'Chat';newCase.OwnerId = userinfo.getUserId();newCase.AccountMergeStatus__c = 'Submitted for Merge';newCase.SubmitforMergeDate__c = System.now();
            insert newCase;
        }
    }
    
    public static void updateLead(Lead leadRec){
        update leadRec;
    }
    
    public static Map<String, List<Account>> findAccountsByEmailAndPhone(Set<String> emails, Set<String> phones){
        String accountWhrClause = ' ( RecordType.Name = \'' + Constants.PERSON_ACCOUNT_RT + '\')';        
        String query = 'SELECT Id, Name, PersonEmail,PersonMobilePhone FROM Account WHERE '+accountWhrClause+' AND PersonEmail IN :emails AND PersonMobilePhone IN :phones AND MergedAccount__c= false ORDER BY CreatedDate DESC';
        List<Account> accounts = Database.query(query);
        Map<String, List<Account>> accountEmailPhoneMap = new Map<String, List<Account>>();
        if(!accounts.isEmpty()){
            for(Account ac : accounts){
                String key = ac.PersonEmail+'-'+ac.PersonMobilePhone;
                if(!accountEmailPhoneMap.containsKey(key)){
                    accountEmailPhoneMap.put(key, new List<Account> {ac});
                } else {
                    accountEmailPhoneMap.get(key).add(ac);
                }
            }
        }
        return accountEmailPhoneMap;
    }
    
    public static List<Lead> getleadbyLeadNumber(String leadNumber){
        List<Lead> ld = [SELECT Id,ExistingAccount__c,ExistingAccount__r.PersonEmail,LeadNumber__c,EmailApprovalsReason__c,EmailApprovalsOtherReason__c,SkipDuplicateApprovalStatus__c,FirstName,LastName,BrokerAgency__r.Name,BrokerAgent__r.FirstName,BrokerAgent__r.LastName,SalesType__c,PropertyUsage__c,Approval_Status__c,BrokerAgency__r.BillingState,BrokerAgency__r.AgencyCategory__c,RecordType.Name,BrokerAgency__r.AgencyStatus__c,
        BuyRent__c,Project__c,UnitType__c,NumberOfBedrooms__c,Offer1__c,PurposeOfUse__c,Bulk__c,PropertyReadiness__c,Financing__c,CustomerBudget__c,IsConverted,Lead_Type__c,ConvertedOpportunityId,ConvertedFromAppointment__c,LeadSource,OwnerId,Email,MobilePhone,Sodic_Lead_1__c,ExistingAccount__r.FastTrackedAccount__c,ExistingAccount__r.ProspectAccount__c,VIPApproval__c FROM Lead WHERE (LeadNumber__c =:leadNumber AND LeadSource ='Broker Portal') OR (LeadNumber__c =:leadNumber AND OwnerId ='00G25000009XKWJEA4')];
      
        if(ld.size()> 0){
            return ld;
        }else{
            return new List<Lead>();
        }
    }
    public static String checkPrivileges(User us){
        String errorString='';
        //User us = [SELECT Id,Name,Profile.Name,RoleName__c,ProfileName__c FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
        if(us.Profile.Name != 'System Administrator' && us.Profile.Name != 'Sales Manager - SODIC' && us.Profile.Name !='Resale Relationship Manager' && us.Profile.Name !='Sales Manager'){
            errorString ='Insufficient Privileges to search for Lead.';
        }else{
            
               
                if(us.RoleName__c == 'CASA - Sales Manager' && us.ByPassBrokerLeadSearch__c == false){
                    errorString ='Insufficient Privileges to search for Lead.';
                }
            }
        return errorString;
    }
    
    /**
    * sentOTP
    * This method used to
    * @param String
    * @param String
    * @return String
    * @description Added By Moh Sarfaraj for BPE-440
    */
    @AuraEnabled(cacheable=false)
    public static String sentOTP(String contactId, String type, String value){
        try{
            List<Contact> listBroker = new List<Contact>();
            listBroker = [SELECT Id,Name,Email,MobileCountryCode__c,MobilePhone__c,PrimaryOwner__c,OwnerId 
                                FROM Contact WHERE Id = :contactId LIMIT 1];

            if(listBroker != null && !listBroker.isEmpty()){
                Integer sixDigitOTPNumber = Integer.valueof((Math.random() * 1000000));
    
                listBroker[0].BrokerLoginOTPNumber__c = String.valueOf(sixDigitOTPNumber);
                listBroker[0].BrokerLoginOTPDateTime__c = Datetime.now();
                listBroker[0].BrokerResendOTP__c = false;
            
                if(type.equalsIgnorecase('SMS')){
                    // Call Domestic SMS API
                    if(value.startsWith('+971')  || value.startsWith('971') || value.startsWith('+97') || value.startsWith('97')){
                        SmsNotificationAPI.SmsRequest wrp = new SmsNotificationAPI.SmsRequest();
                        wrp.destination = value;
                        wrp.smsBody = 'Dear User' +','+'\r\n' +'Your One Time Passcode is '+sixDigitOTPNumber+'.'+'\r\n'+'\r\n' +'Aldar Properties' ;
                        wrp.record = listBroker[0];
                        if(!Test.isRunningTest()){ SmsNotificationAPI.sendSmsNotification(new List<SmsNotificationAPI.SmsRequest>{wrp}); }
                        update listBroker[0];
                        return 'success';
                    }else{ /* Implement INTL SMS API */ }   
                }else if(type.equalsIgnorecase('EMAIL')){
                    CommunityAuthController.sendBrokerOTPEmail(value, String.valueOf(sixDigitOTPNumber));
                    update listBroker[0];
                    return 'success';
                }
            }
            return 'error';
        }catch (Exception e){throw new AuraHandledException(e.getMessage());}
    }

    /**
    * getOtpDetails
    * This method used to
    * @param String
    * @return List<Contact>
    * @description Added By Moh Sarfaraj for BPE-440
    */
    @AuraEnabled(cacheable=false)
    public static List<Contact> validateOTP(String contactId){
        Timer__mdt otpTimer = Utilities.getTimer(Constants.OTP);

        String timerUnit = otpTimer.Time__c;
        Integer timerDetails = Integer.valueOf(otpTimer.Timer__c);

        if (timerUnit == Constants.HOURS) {
            timerDetails = timerDetails * 60;
        }
    
        List<Contact> listBroker = [SELECT Name,Id, BrokerLoginOTPNumber__c FROM Contact WHERE Id = :contactId];

        if(listBroker != null && !listBroker.isEmpty()){
            return listBroker;
        }
        return new List<Contact>();
    }
}