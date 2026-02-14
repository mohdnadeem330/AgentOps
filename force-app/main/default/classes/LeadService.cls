public with sharing class LeadService{
    public static String RESALE_LEADTYPE = 'Resale';
    public static String NEWSALE_LEADTYPE = 'New Sale';
    public static String AMSALE_LEADTYPE = 'AM Sale';

    @InvocableMethod
    public static void convertLead(List<Id> request) {
    
       Database.LeadConvert lc = new Database.LeadConvert();
       lc.setLeadId(request[0]);
       lc.setOwnerId(Userinfo.getuserid()) ;
   
       LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
       lc.setConvertedStatus(convertStatus.MasterLabel);
       Database.LeadConvertResult lcr = Database.convertLead(lc);
    }

    public static Map<String,Lead> getExistingLeadByUniqueKey(Set<String> uniqueKeys){
   
        Map<String,Lead> allLeadRecMap = new Map<String,Lead>();
   
        List<Lead> leadDetails = [Select firstName, MiddleName, lastName, Email, Phone, OwnerId, Status, Id, CreatedDate, UniqueKey__c, ParentLead__c, UniqueKey1__c, MobileCountryCode__c, MobileNumber1__c,Owner.IsActive,IsConverted
                                       From Lead where (UniqueKey1__c IN : uniqueKeys OR  UniqueKey__c IN : uniqueKeys) order by createdDate asc];
      
        for(Lead leadRec : leadDetails){   
            if(leadRec.UniqueKey1__c != null){
                allLeadRecMap.put(leadRec.UniqueKey1__c.toLowercase(),leadRec);
            }
            if(leadRec.UniqueKey__c != null){
                allLeadRecMap.put(leadRec.UniqueKey__c.toLowercase(),leadRec);
            }
        }
        return allLeadRecMap ;
    }
       
    public static map<id,Lead> getLeadDetailsMapbyId(String leadID){
        map<id,Lead> leadMap = new map<id,Lead>();

        leadMap= new map<id,Lead>([select id,CustomerSubType__c,Nationality__c,ResidentStatus__c,LeadSource from Lead where id=:leadID  WITH SECURITY_ENFORCED]);

        return leadMap;
    }

    public static Id getOrganizaionRecordTypeId(){
        Id orgRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(Constants.ORGANIZATION_LEAD_RECORD_TYPE_Name).getRecordTypeId();
        return orgRecordTypeId;
    }

    public static void populateAgencyAccount(list<lead> newList){

        Set<String> agencyName = new Set<String>();
        List<Lead> agencyLeads = new List<Lead>();
        for(Lead leadRec : newList){
            if(String.isNotBlank(leadRec.agencyName__c)){
                agencyName.add(leadRec.agencyName__c);
                agencyLeads.add(leadRec);
            }
        }

        if(!agencyName.isEmpty()){
            Map<String,Account> agencyNameMap = AccountService.getAgenciesByName(agencyName) ;
            for(Lead leadRecord : agencyLeads){
                String agencyNameValue = leadRecord.AgencyName__c;
                if(agencyNameMap.containsKey(agencyNameValue)){
                    leadRecord.BrokerAgency__c = agencyNameMap.get(agencyNameValue).Id;
                }
            }
        }
    }

    public static void populateAgentContact(list<lead> newList){

        Set<String> agentName = new Set<String>();
        List<Lead> agentLeads = new List<Lead>();
        for(Lead leadRec : newList){
            if(String.isNotBlank(leadRec.agentName__c)){
                agentName.add(leadRec.agentName__c);
                agentLeads.add(leadRec);
            }
        }

        if(!agentName.isEmpty()){
            Map<String,Contact> agentNameMap = ContactService.getAgentsByName(agentName) ;
            for(Lead leadRecord : agentLeads){
                String agentNameValue = leadRecord.AgentName__c;
                if(agentNameMap.containsKey(agentNameValue)){
                    leadRecord.BrokerAgent__c = agentNameMap.get(agentNameValue).Id;
                }
            }
        }
    }

    /*
    *Fetch Lead by LeadIds
	* Updated by Harsh@Aldar 17/10/2024 - Added LeadSubType__c OB-825 / OB-788
    */
    //Modified by CLOUDZLAB
    public static List<Lead> getAllLeadByIds(Set<Id> leadIds){
         List<Lead> exisitingLeads = [Select CreatedDate, ParentLead__c, OwnerId, ExistingAccount__c, ExistingAccount__r.OwnerId, Name, Lead_Type__c, LeadSubType__c,Company,Date_of_Birth__c,ECSS_EmiratesId__c ,RecordTypeName__c,
                                    Email, MobilePhone, MobileNumber1__c, RecordType.Name, LeadSource, UniqueKey1__c, BrokerAgent__c, SkipDuplicateApprovalStatus__c,InitiateDigitalBooking__c,Project__c
                                       From Lead WHERE Id IN : leadIds]; 
        return exisitingLeads;
    }

    /*
    *Fetch Lead by Id
    */
    public static Lead fetchLeadById(String leadId) {   
        
        Set<String> leadFields = Schema.getGlobalDescribe().get('Lead').getDescribe().fields.getMap().keySet();
        List<String> leadFieldsList = new List<String>();
        leadFieldsList.addAll(leadFields);
        String allLeadFields = String.join(leadFieldsList, ',');
        String query = 'SELECT QualifiedBy__r.Name, Recordtype.Name, ' + allLeadFields + ' FROM Lead WHERE Id =\'' + leadId + '\'';
        System.debug('***Lead query***'+query);

        Lead leadRec = Database.Query(query);
        
        return leadRec ;
        
    }

    /*
    *Fetch Lead by LeadNumber
    */
    public static Lead fetchLeadByLeadNumber(String leadNumber) {   
        
        Set<String> leadFields = Schema.getGlobalDescribe().get('Lead').getDescribe().fields.getMap().keySet();
        List<String> leadFieldsList = new List<String>();
        leadFieldsList.addAll(leadFields);
        String allLeadFields = String.join(leadFieldsList, ',');
        String query = 'SELECT QualifiedBy__r.Name, Recordtype.Name, ' + allLeadFields + ' FROM Lead WHERE LeadNumber__c =\'' + leadNumber + '\'';
        System.debug('***Lead query***'+query);

        Lead leadRec = Database.Query(query);
        
        return leadRec ;
        
    }

    /*
    *Fetch Lead by MobilePhone
    */
    public static List<Lead> fetchLeadByMobilePhone(String mobilePhone) {   
        
        Set<String> leadFields = Schema.getGlobalDescribe().get('Lead').getDescribe().fields.getMap().keySet();
        List<String> leadFieldsList = new List<String>();
        leadFieldsList.addAll(leadFields);
        String allLeadFields = String.join(leadFieldsList, ',');
        String query = 'SELECT QualifiedBy__r.Name, Recordtype.Name, ' + allLeadFields + ' FROM Lead WHERE IsNagwaCustomer__c = true and MobilePhone =\'' + mobilePhone + '\' order by createddate desc';
        System.debug('***Lead query***'+query);

        List<Lead> leadRec = Database.Query(query);
        
        return leadRec ;
        
    }
     // Added by Arvind
    public static List<Lead> fetchLeadByAppNumber(String appNum,String emiratesId, String mobileNumberwithCountrycode) 
    {
        return [SELECT Id, Status FROM Lead WHERE  Application_Number__c !=: null  AND MobilePhone !=: null AND  NationalId__c !=: null AND Application_Number__c =: appNum AND NationalId__c =: emiratesId AND MobilePhone =: mobileNumberwithCountrycode];
    }

    public static List<Lead> fetchLeadByAccountId(String accountId) {
        return [SELECT Id, Status FROM Lead WHERE ExistingAccount__c =: accountId AND Status !=: Constants.CONVERTED_LEAD];
    }
    
    public static List<Lead> fetchLeadForAPIByUser(String userId) {
        // Datetime dateWhrCluse = Datetime.newinstance(2022, 08, 08);
        return [SELECT Id, Status, IsConverted, ConvertedOpportunityId, ConvertedOpportunity.StageName FROM Lead WHERE OwnerId =: userId AND (OriginalCreationDate__c = THIS_FISCAL_YEAR OR (OriginalCreationDate__c = null AND CreatedDate = THIS_FISCAL_YEAR))];
    }

    public static Map<id,String> fetchLeadNumber(Set<Id> leadIds){
        Map<id,String> leadIdNumberMap = new Map<id,String>();
        for(Lead lead : [select id,Leadnumber__c from Lead where id IN: leadIds])
        {
            leadIdNumberMap.put(lead.Id,'Lead-'+lead.Leadnumber__c);
        } 
        System.debug('leadNumberMap '+leadIdNumberMap);
        return leadIdNumberMap;
    }


    //----Fetch list of Leads based on condition
    public static List<Lead> fetchLeads(string whereCondition){
        List<Lead> leadList = new List<Lead>();
        try{ 
            String convertedLead = Constants.CONVERTED_LEAD;
            String strQuery = 'Select Id,Name,CustomerType__c,CustomerSubType__c,Email,MobilePhone,LeadSource,Status,Project__c,EnquiryCategory__c,EnquiryTrigger__c,LeadNumber__c,CreatedDate,MediaSource__c FROM Lead WHERE Id != null AND IsConverted=false AND Status != \''+Constants.CONVERTED_LEAD+'\'';
                
            if(whereCondition != null && string.isNotEmpty(whereCondition)){
                strQuery += ' and ('+whereCondition+')';
            }
            strQuery += ' Order By CreatedDate DESC limit '+Utilities.getRecordCount('AppFetchRecordCount',Utilities.getRecordCount('AppMaxRecordCount',0));
            System.debug('---Lead Query---'+strQuery);
            leadList =  Database.query(strQuery);
            System.debug('***leadList***'+leadList.size());
            return leadList;
        }
        catch(Exception e){
            System.debug('*** Exception e***'+e.getMessage());
            System.debug('*** Exception e***'+e.getLineNumber());
            throw e;
        }
    }

    
    public static void populateOfferRecord(list<lead> newList){

        Set<String> offersPromotionsNames = new Set<String>();
        List<Lead> leadsWithOfferPromotion = new List<Lead>();

        for(Lead leadRec : newList){
            if(String.isNotBlank(leadRec.offer1__c)){
                offersPromotionsNames.add(leadRec.offer1__c);
                leadsWithOfferPromotion.add(leadRec);
            }
        }

        if(!offersPromotionsNames.isEmpty()){
            Map<String,OffersPromotions__c> offersPromotionsMap = OffersPromotionsService.getOffersPromotionsByName(offersPromotionsNames) ;
            for(Lead leadRecord : leadsWithOfferPromotion){
                String offersPromotionsValue = leadRecord.offer1__c;
                if(offersPromotionsMap.containsKey(offersPromotionsValue)){
                    leadRecord.offer__c = offersPromotionsMap.get(offersPromotionsValue).Id;
                } else{
                    leadRecord.offer__c = null;
                }
            }
        }
    }
}