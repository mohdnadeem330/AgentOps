public with sharing class OpportunityService {

    
    @AuraEnabled(cacheable=false)
    public static void updateOpportunityStage(String opportunityId, String eventSubject){
        Opportunity opportunityRecord = new Opportunity();
        opportunityRecord.Id = opportunityId;
        if (eventSubject.toLowerCase().contains(Constants.ALDAR_SALES_OFFER.toLowerCase())) {
            opportunityRecord.StageName= Constants.STAGE_PROPOSAL;
        } else if (eventSubject.toLowerCase().contains(Constants.MEETING.toLowerCase())) {
            opportunityRecord.StageName= Constants.MEETING;
        } else if (eventSubject.toLowerCase().contains(Constants.CLOSEDWON.toLowerCase())) {
            opportunityRecord.StageName= Constants.STAGE_CLOSEDWON;
        }
        update opportunityRecord;     
    }
    
    public static List<Opportunity> fetchOpportunityForAPIByUser(String userId) {
        return [SELECT Id, StageName, Amount, AgentType__c, Bank__c, BankName__c, CreatedDate, CloseDate, CreationDate__c FROM Opportunity WHERE OwnerId =: userId AND CreationDate__c = THIS_FISCAL_YEAR];
    }
    
    /**
     * To get Opportunity present in account
     */
    public static Map<Id,Opportunity> getAllOpportunitys(Set<Id> accountsIDs, List<Account> accountList){
    
        List<Opportunity> allOpportunity = [select AccountId, Name, CloseDate, StageName, createdDate, OwnerId  from Opportunity where AccountId IN: accountsIDs order by createdDate asc ]                                                                                     ;
    
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
    
        for(Opportunity oppRec : allOpportunity){
            for(Account accountRec : accountList){
                if(oppRec.AccountId == accountRec.Id && oppRec.createdDate >= accountRec.createdDate){
                    opportunityMap.put(oppRec.AccountId,oppRec);
                }
            }
        }
        return opportunityMap;
    }
    
    /**
     * Get lastest Opportunity for an account
     */
    public static Map<Id,Opportunity> getOpportunityForAccount(Map<Id,Account> accountMap){
    
        List<Opportunity> allOpportunity = [SELECT AccountId, Name, CloseDate, StageName, createdDate, OwnerId  FROM Opportunity WHERE AccountId IN: accountMap.keySet() ORDER BY createdDate ASC];
    
        Map<Id,Opportunity> accountOpportunityMap = new Map<Id,Opportunity>();
    
        for(Opportunity oppRec : allOpportunity){
            Account accountRec = accountMap.get(oppRec.AccountId);
                if(oppRec.createdDate >= accountRec.createdDate){
                    accountOpportunityMap.put(oppRec.AccountId,oppRec);
                }
        }
        return accountOpportunityMap;
    }
    
    @AuraEnabled(cacheable=false)
    public static Opportunity getOpportunityDetailsbyId(String opportunityID){
    
        Opportunity opportunityObj = [select AccountId, Name, CloseDate, StageName, createdDate, OwnerId, SaleType__c, DealType__c, BookingType__c, AgentType__c, ReferralType__c, BankName__c,BrokerAgentName__c,BrokerAgencyAccount__c, EmployeeName__c,SubsidyYears__c,CanAllowBooking__c,ServiceRequest__c,IsDigitalSales__c  from Opportunity where Id =: opportunityID limit 1];
    
        return opportunityObj;
    }
    
    public static map<id,Opportunity> getOpportunityDetailsMapbyId(String opportunityID){
        map<id,Opportunity> opportunityMap = new map<id,Opportunity>();
        //ASF-3111
        opportunityMap = new map<id,Opportunity>([select id,Name,StageName,SubsidyYears__c,AgentType__c,ReferralType__c,
                                                  AccountId,Account.Nationality__pc,Account.ResidentStatus__pc ,
                                                  Account.CustomerSubType__c,ContactId,ResidentStatus__c,FirstEnquiryCategory__c,
                                                  FirstEnquiryTrigger__c,FirstMethodofContact__c,LeadSource,Contact__r.MobilePhone,Contact__r.Email,
                                                  Contact__r.nationality__c,Contact__r.Name,Contact__r.ResidentStatus__c,
                                                  ownerId,owner.ManagerId,SaleType__c,BrokerAgencyAccount__r.AgencyRegion__c,
                                                  BrokerAgentContact__c,BrokerAgencyAccount__c,Financing__c,OwnerRole__c,Account.CustomerType__c,
                                                  ReferredBy__c, recordTypeId, EmployeeId__c, EmployeeEmail__c, 
                                                  Account.VIPClass__c,ReferralCustomer__c,Account.CorporateWealthName__c,EnquiryCategory__c,
                                                  Account.RecordType.Name,Account.BillingCountry
                                                  FROM Opportunity where id=:opportunityID  ]);
    
        return opportunityMap;
    }
    
    @AuraEnabled(cacheable=false)
        public static List<Opportunity> getOpportunityQuery(String query) {
        List<Opportunity> records = Database.query(query);
        return records;
    }
    
    @AuraEnabled(cacheable=false)
    public static String opportunityFieldsValidation(String opportunityId){ 
    
        /*
        List<Opportunity> OpportunityDetails =  [SELECT SaleType__c,DealType__c,AgentType__c,
        BookingType__c,DeliveryMethod__c,Contact__c FROM Opportunity WHERE Id =: opportunityId]; 
        String opportunityValdiation = null;
        
    
        for(Opportunity OpportunityRec : OpportunityDetails){ 
            opportunityValdiation = (String.isNotBlank(OpportunityRec.SaleType__c)
            ? ''
            : 'Sale Type');
    
            opportunityValdiation += (String.isNotBlank(OpportunityRec.DealType__c)
            ? ''
            : (String.isNotBlank(opportunityValdiation) ? +', ' : '') + 'Deal Type');
    
            opportunityValdiation += (String.isNotBlank(OpportunityRec.Contact__c)
            ? ''
            : (String.isNotBlank(opportunityValdiation) ? +', ' : '') + 'Customer');
    
            opportunityValdiation += (String.isNotBlank(OpportunityRec.AgentType__c)
            ? ''
            : (String.isNotBlank(opportunityValdiation) ? +', ' : '') + 'Agent Type');
    
            opportunityValdiation += (String.isNotBlank(OpportunityRec.BookingType__c)
            ? ''
            : (String.isNotBlank(opportunityValdiation) ? +', ' : '') + 'Booking Type');
    
            opportunityValdiation += (String.isNotBlank(OpportunityRec.DeliveryMethod__c)
            ? ''
            : (String.isNotBlank(opportunityValdiation) ? +', ' : '') + 'Delivery Method');
        }
        return opportunityValdiation ;
    
        */
    
        return opportunityFieldsValidationmt(opportunityId);
    }
        /*
        * Purpose : To validate Opportunity fields added in custom metadata(Validate fields)
        * Created by : Ajay Thakur
        */
        @AuraEnabled(cacheable=false)
        public static String opportunityFieldsValidationmt(String opportunityId){ 
    
            Set<String> oppFieldList = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet();
            List<String> strList = new List<String>();
            strList.addAll(oppFieldList);
            String opptyfields = string.join(strList,',');
            String query = 'SELECT ' + opptyfields + ' FROM Opportunity WHERE Id = \'' + opportunityId + '\'';
            System.debug('***Opportunity query***'+query);
            List<Opportunity> opportunityList = Database.Query(query);
            System.debug('***Opportunity Record***'+opportunityList);
            
			//LAS-7 starts here by Nikhil Mehra
			User userObj = Utilities.getLoggedInUserDetail();
            Boolean isLSQ = userObj.Team__c == 'LSQ'? true : false;
            //LAS-7 ends here by Nikhil Mehra
            
            Map<String,List<ValidationFields__mdt>> validationFieldsMap = Utilities.getValidationFields();
    
            String opportunityValdiation = '';
    
            Opportunity oppRec = opportunityList[0] ;
        
            for(ValidationFields__mdt field : validationFieldsMap.get('Opportunity')){
    
                String fieldValue = (String) oppRec.get(field.FieldAPI__c);
                System.debug('FieldAPI-'+field.FieldAPI__c+'- FieldValue-'+fieldValue);
                //LAS-7 starts here by Nikhil Mehra
                String applicableFor = field.ApplicableFor__c;
                Boolean isApplicable = false;
                if (isLSQ) {
                    if (applicableFor.containsIgnoreCase('LSQ') || applicableFor.containsIgnoreCase('All')) {
                        isApplicable = true;
                    }
                } else {
                    if (applicableFor.containsIgnoreCase('Aldar') || applicableFor.containsIgnoreCase('All')) {
                        isApplicable = true;
                    }
                }
                
                //opportunityValdiation += (String.isNotBlank((String) oppRec.get(field.FieldAPI__c)) && isApplicable? '': (String.isNotBlank(opportunityValdiation) ? +', ' : '') + field.Label);
                if (!String.isNotBlank(String.valueOf(oppRec.get(field.FieldAPI__c))) && isApplicable) {
                    if (String.isNotBlank(opportunityValdiation)) {
                        opportunityValdiation += ', ';
                    }
                    opportunityValdiation += field.Label;
                }
                 //LAS-7 ends here by Nikhil Mehra
               
            }       
            System.debug('opportunityValdiation '+opportunityValdiation);
            return opportunityValdiation ;
        }
        
        public static List<Opportunity> fetchOpportunitiesByAccountId(String accountId) {
            return [select id, StageName from Opportunity where AccountId =: accountId];
        }
        
        public static Map<String,List<ValidationFields__mdt>> getValidationFields()
        {
            List<ValidationFields__mdt> valFieldList = ValidationFields__mdt.getall().values();
            
            Map<String,List<ValidationFields__mdt>> validationFieldsMap = new Map<String,List<ValidationFields__mdt>>();
            
            for(ValidationFields__mdt vf : valFieldList)
            {
                if(!validationFieldsMap.containsKey(vf.ObjectName__c))
                    validationFieldsMap.put(vf.ObjectName__c, new List<ValidationFields__mdt>{vf});
                else
                {
                    List<ValidationFields__mdt> valfldList = validationFieldsMap.get(vf.ObjectName__c);
                    valfldList.add(vf);
                    validationFieldsMap.put(vf.ObjectName__c, valfldList);
                }
                    
            }
            
            return validationFieldsMap;
        }
        
    
    public static Boolean cancelOpportunityReservation(Set<String> idList) {
    
        system.debug('cancelOpportunityReservation' + idList);
        
    
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        User usr = Utilities.getLoggedInUserDetail();

        for(Opportunity objOpportunity : [Select id,Name from Opportunity where id IN:idList]){
            if(usr.Profile.name =='System Administrator' || usr.Profile.name =='Integration Profile' )
            {
    
                ProcessInstanceWorkitem[] Pval = [SELECT Id FROM ProcessInstanceWorkItem WHERE ProcessInstance.TargetObjectId = :objOpportunity.Id AND ProcessInstance.Status = 'Pending']; 
                
                if(Pval.size() > 0){
            
                    Approval.ProcessWorkItemRequest Preq= new Approval.ProcessWorkItemRequest();
                    Preq.setAction('Removed');
                    Preq.setWorkItemId(Pval[0].Id);
                    Approval.ProcessResult result = Approval.process(Preq);
                }
                Approval.unlock(objOpportunity);
            }
    
            objOpportunity.ReservationApprovalStatus__c = null;
            objOpportunity.ReservationApprovalRequestTime__c = null;
         
            
            
            
            
            
            //Approval.unlock(objOpportunity);
            opportunityList.add(objOpportunity);
        }
        update opportunityList;
        return true;     
    }
    
    public static Map<id,String> fetchOpportunityNumber(Set<Id> opportunityIds){
        Map<id,String> opportunityIdNumberMap = new Map<id,String>();
        for(Opportunity opportunity : [select id,OpportunityNumber__c from Opportunity where id IN: opportunityIds])
        {
            opportunityIdNumberMap.put(opportunity.Id,'Opportunity-'+opportunity.OpportunityNumber__c);
        } 
        System.debug('opportunityIdNumberMap '+opportunityIdNumberMap);
        return opportunityIdNumberMap;
    }
        /*
        *Fetch Lead by Id
        */
        public static Opportunity fetchOpportunityById(String opportunityId) {
            
            Set<String> oppFieldList = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet();
            List<String> strList = new List<String>();
            strList.addAll(oppFieldList);
            //strList.add('​BrokerAgencyAccount__r.Name');
            //strList.add('​BrokerAgentContact__r.Name');
            String opptyfields = string.join(strList,',');
    
            Set<String> accFieldList = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet();
            List<String> strAccList = new List<String>();
            for(String accountField : accFieldList){
                strAccList.add('Account.'+accountField);
            }
            String accountFields = string.join(strAccList,',');
    
            Set<String> conFieldList = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().keySet();
            List<String> strConList = new List<String>();
            //strConList.addAll(conFieldList);
            for(String contactField : conFieldList){
                strConList.add('Contact__r.'+contactField);
            }
            String conFields = string.join(strConList,',');
    
            String query = 'SELECT (select id from OpportunityEOIsOpportunity__r), (select id, Name, ApprovalStatus__c, MemoSubject__c, MemoType__c, isApproved__c from Memos__r),' + opptyfields + ','+accountFields+','+conFields+' FROM Opportunity WHERE Id = \'' + opportunityId + '\'';
            System.debug('***Opportunity query***'+query);
            Opportunity opportunityRec = Database.Query(query);
            System.debug('***Opportunity Record***'+opportunityRec);
            return opportunityRec;
        }
    
        //----Fetch list of Leads based on condition
        public static List<Opportunity> fetchOpportunities(string whereCondition){
            List<Opportunity> opportunityList = new List<Opportunity>();
            try{ 
                String strQuery = 'Select Id, Account.NationalIdExpiryDate__pc, Name,CloseDate,OpportunityNumber__c,StageName,Account.Name,Project__c,LeadSource,SaleType__c,CreatedDate, CanAllowBooking__c FROM Opportunity WHERE Id != null AND Account.Blacklisted__c = False ';   
                if(whereCondition != null && string.isNotEmpty(whereCondition)){
                    strQuery += ' and ('+whereCondition+')';
                }
                strQuery += ' Order By CreatedDate DESC limit '+Utilities.getRecordCount('AppFetchRecordCount',Utilities.getRecordCount('AppMaxRecordCount',0));
                System.debug('---Opportunity Query---'+strQuery);
                opportunityList =  Database.query(strQuery);
                System.debug('***opportunityList***'+opportunityList.size());
                return opportunityList;
            }
            catch(Exception e){
                System.debug('*** Exception e***'+e.getMessage());
                throw e;
            }
        }   
    }