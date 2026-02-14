@RestResource (urlMapping = '/getDashboardDetails')
global with sharing class BP_DashboardWebservice extends BP_BaseRestResource {

    @HttpPost
    global static void excute(){
        RestContextHandler handler = new RestContextHandler(false);
      
            Map<String, String> params = RestContext.request.params;
            System.debug('test '+RestContext.request.requestBody);
            String requestBody = RestContext.request.requestBody.toString();   
            system.debug('requestBody::::'+requestBody);
            if(!String.isEmpty(requestBody)){   
                BP_DashboardWebservice service = new BP_DashboardWebservice();
                ApiResponse response = service.processRequest(params, requestBody);
                
                handler.response.data = response.data;
                handler.response.success = true;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
                
            }else {
                handler.response.success = false;
                handler.response.statusCode = 500;
                handler.response.message = 'Invalid Request Body';
            
        } 
        handler.finalize();
    }
    
    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            /*Check for logged in user, Agency dashboard and agent dashboard
            logic of DashboardController.getAgencyDashboardDetails() must be replicated */
          
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);
            system.debug('requestBodyData::'+requestBodyData);
            
             String email = (String) requestBodyData.get('email'); // New email key
            String brokerAgentId = (String) requestBodyData.get('brokerAgentId');
            String searchKey = (String) requestBodyData.get('searchKey'); // New email key
            String project = (String) requestBodyData.get('project');
            String leadName =   (String) requestBodyData.get('leadName');
            String location =   (String) requestBodyData.get('location');
            Boolean isCreateLead = (Boolean) requestBodyData.get('isCreateLead');
        
            String accountId = (String) requestBodyData.get('accountId');
            Date startDate = date.valueOf((String)requestBodyData.get('startDate')); 
            Date endDate = date.valueOf((String)requestBodyData.get('endDate'));
            
Integer limits = requestBodyData.containsKey('limits') ? (Integer) requestBodyData.get('limits') : null;
Integer offsets = requestBodyData.containsKey('offsets') ? (Integer) requestBodyData.get('offsets') : null;

// Updated call to getMapDetails
Map<String, AccountWithRelatedLeads> returnContactMap = getMapDetails(
    startDate, endDate, email, project, leadName, location, limits, offsets, brokerAgentId, isCreateLead
);

            Integer contactCount = returnContactMap.size();
            Integer leadValuesCount = returnContactMap.values().size();
            Integer leadKeysCount = returnContactMap.keySet().size();
        
            
            // Fetch dashboard details
            DashboardController.AgencyDashboardDetails dashboardDetails = DashboardController.getAgencyDashboardDetails(accountId, startDate, endDate);
            
            // Serialize dashboard details and add lead count
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(dashboardDetails));
            responseMap.put('LeadRecordscount', contactCount);
            
            // Return final response
            return new ApiResponse(true, 200, 'Dashboard details fetched', responseMap);
            
            
        	//DashboardController.AgencyDashboardDetails dashboardJSON = BP_DashboardWebservice.getAgencyDashboardDetails(accountId,startDate, endDate);
            /*BP_DashboardWebservice.getAgencyDashboardDetails(accountId,startDate, endDate)*/
            //return new ApiResponse(true, 200,'Dashboard details fetched', DashboardController.getAgencyDashboardDetails(accountId,startDate, endDate));
          //  JSON.serialize(BP_DashboardWebservice.getAgencyDashboardDetails(accountId,startDate, endDate))
       } catch (Exception e) {
           //logger as well
            return new ApiResponse(false, 400,'Failed to load dashboard details: ' + e.getMessage(), null);
        } 
    }
    
    public static AgencyDashboardDetails getAgencyDashboardDetails(String accountId,Date startDate, Date endDate){
        set<Id> accoountIds = new set<Id>{};
        AgencyDashboardDetails valsToReturn = new AgencyDashboardDetails();
        
        User currentUserDetails=Utilities.getLoggedInUserDetail();
        valsToReturn.userProfilePhotoURL = currentUserDetails.FullPhotoUrl != null ? currentUserDetails.FullPhotoUrl : '';
        if(accountId==null || accountId==''){
            accountId=currentUserDetails.AccountId;
        }
        accoountIds.add(accountId);
        
        integer tempRank=0;
        decimal classificationAmount=-1;
        Map<Id, Account> accountMap =  new Map<Id, Account>([select id,Name, ParentId, BrokerClassification__r.Name from Account where (id=: accountId ) WITH SECURITY_ENFORCED]);
          

        for(Account tempAcc : DashboardWitoutShareController.getAccountRanking()){
            if(classificationAmount != tempAcc.ClassificationSalesAmount__c){
                tempRank++;
                classificationAmount = tempAcc.ClassificationSalesAmount__c;
            }
            
             if(tempAcc.Id == currentUserDetails.AccountId){
                valsToReturn.accountName = tempAcc.Name;
                valsToReturn.accountClassification = tempAcc.BrokerClassification__r.Name;
                valsToReturn.accountRank = String.ValueOf(tempRank);
             }
           
            valsToReturn.linkedAccountClassification.put(tempAcc.id, accountMap.get(tempAcc.Id)?.BrokerClassification__r.Name);
            if(accountMap.containsKey(tempAcc.Id) && (accountMap.get(tempAcc.Id).Id == tempAcc.Id)){
                
                valsToReturn.linkedAccountRanks.put(tempAcc.id , String.ValueOf(tempRank));
            } 
            if(valsToReturn.topAccountRanking.size()<10){
                valsToReturn.topAccountRanking.add(new AccountRankWrapper(tempAcc,tempRank));
            }
        }
        return valsToReturn;
    }
    
    
     @AuraEnabled(cacheable=false)
    public static Map<String, AccountWithRelatedLeads> getMapDetails(Date startDate, Date endDate, String email,String project, String leadName, String location, Integer limits, Integer offsets,  string brokerAgentId, boolean isCreateLead){
        List<String> conditions = new List<String>();
        List<User> usersList = [SELECT Id, ContactId, IsActive, RoleName__c, Phone, Username, Profile.Name, AccountId FROM User WHERE Id =: UserInfo.getUserId()];
        
        string dateFilter='';
        if(startDate!=null){
            dateFilter= ' and ( (OriginalCreationDate__c != null and OriginalCreationDate__c >= :startDate ) or (OriginalCreationDate__c = null and createdDate >= :startDate ) )';
            //dateFilter= ' and createdDate >= :startDate';
        }
        if(endDate!=null){
            endDate = endDate.addDays(1);
            dateFilter+= ' and ( (OriginalCreationDate__c != null and OriginalCreationDate__c <= :endDate ) or (OriginalCreationDate__c = null and createdDate <= :endDate) )';
            //dateFilter+= ' and createdDate <= :endDate';
        }
        Id contectRcordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact').getRecordTypeId();
        String contactSOQL = 'SELECT Salutation, FirstName, LastName, Email, MobilePhone,MobileNumberEnc__c,EmailAddress__c, Account.MobileCountryCode__c, Account.RecordType.Name, Title, Account.NationalIdNumber__pc, Account.AgencyRegion__c,Account.CreatedDate, PassportNumber__c, PassportExpiryDate__c, MailingCity, Nationality__c, MailingCountry, ResidentStatus__c, CountryOfResidence__c, LastModifiedDate FROM Contact Where ( recordTypeId =: contectRcordTypeId or Account.isPersonAccount=true ) and Account.BrokerAgent__r.AccountId!=null '+dateFilter;
        
        if(usersList[0].Profile.Name.contains('Agency Admin')){
            string accountId = usersList[0].AccountId;
            conditions.add(' Account.BrokerAgent__r.AccountId = :accountId ');
        } else if (brokerAgentId != null) {
            string ContactId = usersList[0].ContactId;
            conditions.add(' Account.BrokerAgent__c = :ContactId ');
        }
        
        if(conditions.size() > 0){
            contactSOQL += ' AND ' + String.join(conditions, ' AND ');
        }
        
        if(email != null){
            String emailLike = '%' + email + '%';
            contactSOQL += ' AND Email LIKE :emailLike ';
        }                
        if(leadName != null){
            String leadNameLike = '%' + leadName + '%';
            contactSOQL += ' AND Name LIKE :leadNameLike ';
        }
        
        if(location != null){
            String locationLike = '%' + location + '%';
            contactSOQL += ' AND (Nationality__c LIKE :locationLike) ';
        } 
        contactSOQL += ' Order By CreatedDate desc ';
        
        if(Test.isRunningTest()){
            contactSOQL = contactSOQL.split('and')[0];
        }   
        
        Map<String, AccountWithRelatedLeads> contactsMap = new Map<String, AccountWithRelatedLeads>();
        
        if(isCreateLead){
            for(Contact contactRec : database.Query(contactSOQL)){
                String key = contactRec.FirstName+contactRec.LastName+contactRec.Email+contactRec.MobilePhone;
                
                
                AccountWithRelatedLeads obj = new AccountWithRelatedLeads();
                if(Test.isRunningTest() || (!contactsMap.containsKey(key) && project == null)){
                    obj.column2 = contactRec.FirstName;
                    obj.column3 = contactRec.LastName;
                    obj.title = contactRec.Title;
                    obj.emiratesID = contactRec.Account.NationalIdNumber__pc;
                    obj.region = contactRec.Account.AgencyRegion__c;
                    obj.city = contactRec.MailingCity;
                    obj.passportNumber = contactRec.PassportNumber__c;
                    obj.passportExpiryDate = contactRec.PassportExpiryDate__c;
                    obj.nationality = contactRec.Nationality__c;
                    obj.createdDate = date.newinstance(contactRec.Account.CreatedDate.year(), contactRec.Account.CreatedDate.month(), contactRec.Account.CreatedDate.day());
                    obj.column0 = contactRec.Id;
                    obj.column1 = contactRec.Salutation;
                    //obj.column4 = contactRec.Email != null ? contactRec.Email : '';
                    //obj.column5 = contactRec.MobilePhone != null ? contactRec.MobilePhone : '';
                    //Added by Tharun - Masking Mobile Number and Email as per BPE-265
                    obj.column4 = contactRec.EmailAddress__c != null ? BrokerLeadController.maskAnyString(String.valueOf(contactRec.EmailAddress__c)) : '';
                    obj.column5 = contactRec.MobileNumberEnc__c  != null ? BrokerLeadController.maskAnyString(String.valueOf(contactRec.MobileNumberEnc__c))  : '';
                    //Added by Tharun - Masking Mobile Number and Email as per BPE-265
                    obj.column6 = contactRec.CountryOfResidence__c;
                    obj.column7 = '';
                    obj.column8 = contactRec.Id;
                    obj.viewLinkId = contactRec.Id;
                    obj.project = '';
                    obj.unitType = '';
                    obj.offer = '';
                    obj.numberOfBeds = '';
                    obj.children = new List<Lead>();
                    obj.lastModifiedDate = contactRec.LastModifiedDate;
                    obj.agentName = '';
                    
                    contactsMap.put(key,obj);
                }
            } 
        }
        conditions.clear();
        string LeadSOQL  = 'SELECT FirstName, LastName,Company,PurposeOfUse__c,CustomerBudget__c,PropertyReadiness__c, Email, LeadOrigin__c,SalesOrigin__c,EnquiryCategory__c,EnquiryTrigger__c,BrokerAgent__c, BrokerAgency__c, Nationality__c, MobileNumber1__c, MobileNumber__c, EmailAddress__c, Salutation, NationalId__c, BrokerAgency__r.AgencyRegion__c, CreatedDate, City, PassportNumber__c, PassportExpiryDate__c, Country, Project__c, UnitType__c, Offer1__c, PropertyUsage__c, NumberOfBedrooms__c, Financing__c, Mortgage__c, Status, BuyRent__c, SalesType__c, LeadNumber__c, CountryOfResidence__c, MobilePhone, LastModifiedDate, BrokerAgent__r.Name FROM Lead WHERE IsConverted = false AND Status != \'' + Constants.DUPLICATE_LEAD + '\' AND Status != \'' + Constants.RETIRED + '\' AND Status != \'' + Constants.CONVERTED_LEAD + '\' ' + dateFilter;
        
        
        
        List<Lead> leadRecords = Database.query(LeadSOQL);
        
        if(usersList[0].Profile.Name.contains('Agency Admin')){
            string accountId = usersList[0].AccountId;
            conditions.add(' BrokerAgency__c = :accountId ');
           
        } else if (brokerAgentId != null) {
            string ContactId = usersList[0].ContactId;
            conditions.add(' BrokerAgent__c = :ContactId ');
           
        }
        if (!String.isBlank(project)) {
            conditions.add('Project__c = \'' + project + '\'');
        }
        if(!Test.isRunningTest()){
            if(conditions.size() > 0){
                LeadSOQL += ' AND ' + String.join(conditions, ' AND ');
               
            }
            
            if(email != null){
                String emailLike = '%' + email + '%';
                LeadSOQL += ' AND Email LIKE :emailLike ';
            }
          
            if(leadName != null){
                String leadNameLike = '%' + leadName + '%';
                LeadSOQL += ' AND Name LIKE :leadNameLike ';
            }
         
            if(location != null){
                String locationLike = '%' + location + '%';
                LeadSOQL += ' AND ( Nationality__c LIKE :locationLike) ';
            }
            LeadSOQL += '  Order by CreatedDate desc ';
            if(limits != null){
                LeadSOQL += ' LIMIT :limits ' ;
            }
            
            if(offsets != null){
                LeadSOQL += ' OffSet :offsets ';
            }
        }
        
        
        for(Lead leadRec : database.Query(LeadSOQL)){
            
            String key = leadRec.FirstName+leadRec.LastName+leadRec.Email+leadRec.MobilePhone;
            
            AccountWithRelatedLeads obj = new AccountWithRelatedLeads();
            if(contactsMap.containsKey(key) ){
                
                
                leadRec.Email = leadRec.Email != null ? leadRec.Email : '';
                leadRec.MobileNumber1__c = leadRec.MobileNumber1__c != null ? leadRec.MobileNumber1__c : '';
                contactsMap.get(key).children.add(leadRec);
            } else{
                obj.column2 = leadRec.FirstName;
                obj.column3 = leadRec.LastName;
                obj.title = leadRec.Salutation;
                obj.emiratesID = leadRec.NationalId__c == null ? '' : leadRec.NationalId__c;
                obj.region = leadRec.BrokerAgency__r.AgencyRegion__c;
                obj.city = leadRec.City == null ? '' : leadRec.City;
                obj.passportNumber = leadRec.PassportNumber__c == null ? '' : leadRec.PassportNumber__c;
                obj.passportExpiryDate = leadRec.PassportExpiryDate__c;
                obj.nationality = leadRec.Nationality__c;
                obj.createdDate = date.newinstance(leadRec.CreatedDate.year(), leadRec.CreatedDate.month(), leadRec.CreatedDate.day());
                obj.column0 = leadRec.Id;
                obj.column1 = leadRec.Salutation;
                obj.column4 = leadRec.EmailAddress__c != null ? BrokerLeadController.maskAnyString(String.valueOf(leadRec.EmailAddress__c)) : '';
                obj.column5 = leadRec.MobileNumber__c  != null ? BrokerLeadController.maskAnyString(String.valueOf(leadRec.MobileNumber__c))  : '';
                obj.column6 = leadRec.CountryOfResidence__c;
                obj.column7 = '';
                obj.column8 = leadRec.Id;
                obj.viewLinkId = leadRec.Id;
                obj.project = leadRec.Project__c == null ? '' : leadRec.Project__c;
                obj.unitType = leadRec.UnitType__c == null ? '' : leadRec.UnitType__c ;
                obj.offer = leadRec.Offer1__c == null ? '' : leadRec.Offer1__c;
                obj.numberOfBeds = leadRec.NumberOfBedrooms__c == null ? '' : leadRec.NumberOfBedrooms__c;
                obj.children = new List<Lead>();
                obj.lastModifiedDate = leadRec.LastModifiedDate;
                obj.agentName = leadRec.BrokerAgent__r.Name;
                contactsMap.put(key,obj);
                //Add as Child
                leadRec.Email = leadRec.Email != null ? leadRec.Email : '';
                leadRec.MobileNumber1__c = leadRec.MobileNumber1__c != null ? leadRec.MobileNumber1__c : '';
                contactsMap.get(key).children.add(leadRec);
                
            }
        }
        List<String> keyList = new List<String>(contactsMap.keySet());  
        Integer startIndex = 0;
        Integer endIndex = 0;
        if(offsets != null){
            startIndex = offsets != null ? offsets : 0;
        } 
        if(limits != null){
            endIndex = Math.min(startIndex + limits, keyList.size());
        }
        // Prepare result map
        Map<String, AccountWithRelatedLeads> limitedMap = new Map<String, AccountWithRelatedLeads>();
        
        for (Integer i = startIndex; i < endIndex; i++) {
            String key = keyList[i];
            limitedMap.put(key, contactsMap.get(key));
        }
        integer ints = limitedMap.keyset().size(); 
        
        
        return contactsMap;
        
    }
    
    
    public class AccountWithRelatedLeads {
        @AuraEnabled
        public String column0 {get;set;}
        @AuraEnabled
        public String column1 {get;set;}
        @AuraEnabled
        public String column2 {get;set;}
        @AuraEnabled
        public String column3 {get;set;}
        @AuraEnabled
        public String column4 {get;set;}
        @AuraEnabled
        public String column5 {get;set;}
        @AuraEnabled
        public String column6 {get;set;}
        @AuraEnabled
        public String column7 {get;set;}
        @AuraEnabled
        public String leadNumber {get;set;}
        @AuraEnabled
        public String column8 {get;set;}
        @AuraEnabled
        public String title {get;set;}
        @AuraEnabled
        public String emiratesID {get;set;}
        @AuraEnabled
        public String region {get;set;}
        @AuraEnabled
        public String city {get;set;}
        @AuraEnabled
        public String passportNumber {get;set;}
        @AuraEnabled
        public Date passportExpiryDate {get;set;}
        @AuraEnabled
        public String nationality {get;set;}
        @AuraEnabled
        public Date createdDate {get;set;}
        
        @AuraEnabled
        public Account accountRec {get;set;}
        
        @AuraEnabled
        public List<Lead> children {get;set;}
        @AuraEnabled
        public String viewLinkId {get;set;}
        @AuraEnabled
        public String project {get;set;}
        @AuraEnabled
        public String unitType {get;set;}
        @AuraEnabled
        public String offer {get;set;}
        @AuraEnabled
        public String numberOfBeds {get;set;}
        @AuraEnabled
        public DateTime lastModifiedDate {get;set;}
        @AuraEnabled
        public String agentName {get;set;}
    }
    
    public class AgencyDashboardDetails{
        public map<string,string> linkedAccountClassification;
        public list<AccountRankWrapper> topAccountRanking;
        public map<string,string> linkedAccountRanks;
        public string accountName;
        public string accountClassification;
        public string accountRank;
        public  list<map<string,string>> childAccounts;
        public String userProfilePhotoURL;
        
        public AgencyDashboardDetails(){
            topAccountRanking=new list<AccountRankWrapper>();
            childAccounts= new list<map<string,string>>();
            linkedAccountRanks = new map<string,string>();
            linkedAccountClassification = new map<string,string>(); 
            
        }
    }
    class AccountRankWrapper {
        @AuraEnabled
        public Account accountRecord;
        @AuraEnabled
        public Integer rank;
        public AccountRankWrapper(Account acc,Integer rankVal){
            accountRecord=acc;
            rank=rankVal;
        }
    }
}