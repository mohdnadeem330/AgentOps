public with sharing class BrokerLeadController {
    

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
   
    /*@AuraEnabled(cacheable=false)
    public static List<Contact> getContacts(){
        
        Id orgRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(Constants.BROKER_AGENT).getRecordTypeId();
        List<Contact> contactsList = [SELECT Salutation, FirstName, LastName, Email, MobilePhone, Account.MobileCountryCode__c, Account.RecordType.Name, Title, Account.NationalIdNumber__pc, Account.AgencyRegion__c,
         Account.CreatedDate, PassportNumber__c, PassportExpiryDate__c, MailingCity, Nationality__c, MailingCountry, ResidentStatus__c, CountryOfResidence__c, LastModifiedDate
        FROM Contact Where RecordTypeId !=: orgRecordTypeId Order By CreatedDate desc];
 
        return contactsList;
    }*/

    /*@AuraEnabled(cacheable=false)
    public static List<Lead> getLeadsRelatedToLoggedInUser(){

        User loggedInUser = getUserDetails(UserInfo.getUserId());

        List<Lead> leads = [SELECT FirstName, LastName, Email, MobileNumber1__c, Salutation, NationalId__c, BrokerAgency__r.AgencyRegion__c, createdDate, City, PassportNumber__c, 
                            PassportExpiryDate__c, Nationality__c, Country, Project__c, UnitType__c, Offer1__c, PropertyUsage__c, NumberOfBedrooms__c, Financing__c, Mortgage__c, 
                            BuyRent__c, SalesType__c, LeadNumber__c, CountryOfResidence__c, MobilePhone, LastModifiedDate, BrokerAgent__r.Name
                            FROM Lead Where IsConverted = false Order By LastModifiedDate desc];
 
        return leads;
    }*/

    @AuraEnabled(cacheable=false)
    public static Map<String, AccountWithRelatedLeads> getMapDetails(Date startDate, Date endDate){
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
        String contactSOQL = 'SELECT Salutation, FirstName, LastName, Email, MobilePhone,MobileNumberEnc__c,EmailAddress__c, Account.MobileCountryCode__c, Account.RecordType.Name, Title, Account.NationalIdNumber__pc, Account.AgencyRegion__c,Account.CreatedDate, PassportNumber__c, PassportExpiryDate__c, MailingCity, Nationality__c, MailingCountry, ResidentStatus__c, CountryOfResidence__c, LastModifiedDate FROM Contact Where ( recordTypeId =: contectRcordTypeId or Account.isPersonAccount=true ) and Account.BrokerAgent__r.AccountId!=null '+dateFilter+' Order By name,CreatedDate desc';


        Map<String, AccountWithRelatedLeads> contactsMap = new Map<String, AccountWithRelatedLeads>();
        
        for(Contact contactRec : database.Query(contactSOQL)){
            String key = contactRec.FirstName+contactRec.LastName+contactRec.Email+contactRec.MobilePhone;
            AccountWithRelatedLeads obj = new AccountWithRelatedLeads();
            if(!contactsMap.containsKey(key)){
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
                obj.column4 = contactRec.EmailAddress__c != null ? maskAnyString(String.valueOf(contactRec.EmailAddress__c)) : '';
                obj.column5 = contactRec.MobileNumberEnc__c  != null ? maskAnyString(String.valueOf(contactRec.MobileNumberEnc__c))  : '';
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
        
        string LeadSOQL  = 'SELECT FirstName, LastName, Email,BrokerAgent__c, MobileNumber1__c, MobileNumber__c,EmailAddress__c,Salutation, NationalId__c, BrokerAgency__r.AgencyRegion__c, createdDate, City, PassportNumber__c, PassportExpiryDate__c, Nationality__c, Country, Project__c, UnitType__c, Offer1__c, PropertyUsage__c, NumberOfBedrooms__c, Financing__c, Mortgage__c, BuyRent__c, SalesType__c, LeadNumber__c, CountryOfResidence__c, MobilePhone, LastModifiedDate, BrokerAgent__r.Name FROM Lead Where IsConverted = false and status != \'' +Constants.DUPLICATE_LEAD+'\' and status != \''+Constants.RETIRED+'\' and status != \''+Constants.CONVERTED_LEAD+'\'' + dateFilter +' Order By FirstName asc';
        
        for(Lead leadRec : database.Query(LeadSOQL)){
            String key = leadRec.FirstName+leadRec.LastName+leadRec.Email+leadRec.MobilePhone;
            
            AccountWithRelatedLeads obj = new AccountWithRelatedLeads();
            if(contactsMap.containsKey(key)){
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
                //obj.column4 = leadRec.Email != null ? leadRec.Email : '';
                //obj.column5 = leadRec.MobilePhone != null ? leadRec.MobilePhone : '';
                //Added by Tharun - Masking Mobile Number and Email as per BPE-265
                obj.column4 = leadRec.EmailAddress__c != null ? maskAnyString(String.valueOf(leadRec.EmailAddress__c)) : '';
                obj.column5 = leadRec.MobileNumber__c  != null ? maskAnyString(String.valueOf(leadRec.MobileNumber__c))  : '';
                //Added by Tharun - Masking Mobile Number and Email as per BPE-265
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
        
        return contactsMap;
    }
    /*@AuraEnabled(cacheable=false)
    public static Map<String, AccountWithRelatedLeads> prepareLeadData(List<Lead> leadsList, Map<String, AccountWithRelatedLeads> contactsMap)
    {
        for(Lead leadRec : leadsList){
            String key = leadRec.FirstName+leadRec.LastName+leadRec.Email+leadRec.MobilePhone;
            system.debug('Point Lead key: '+ key);
            system.debug('Point contactsMap.size(): '+contactsMap.size());


            AccountWithRelatedLeads obj = new AccountWithRelatedLeads();
            if(contactsMap.containsKey(key)){
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
                obj.column4 = leadRec.Email != null ? leadRec.Email : '';
                obj.column5 = leadRec.MobilePhone != null ? leadRec.MobilePhone : '';
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
            }
        }
        
        return contactsMap;
    }*/
    
    /*@AuraEnabled(cacheable=false)
    public static Map<String, AccountWithRelatedLeads> getLeadQuery(String query) {
        List<Lead> records = Database.query(query);
        
        Map<String, AccountWithRelatedLeads> leadMap = prepareLeadData(records,new Map<String, AccountWithRelatedLeads>());
        
        return leadMap;
    }*/

    public static List<Lead> getLeadsRelatedToAccount(Account accountRecord){
        List<Lead> leads = [SELECT Project__c, UnitType__c, CreatedDate, Offer1__c, BrokerAgency__c
        FROM Lead WHERE BrokerAgency__c != null AND BrokerAgency__c =: accountRecord.Id];
        return leads;
    }

    @AuraEnabled(cacheable=false)
    public static List<AccountWithRelatedLeads> getLeadsRelatedToContact(String contactUserId){

        List<Lead> leads = [SELECT Salutation, FirstName, LastName, Project__c, UnitType__c, CreatedDate, Offer1__c, BrokerAgent__c, Email, MobileCountryCode__c,
         MobileNumber1__c, MobileNumber__c, Nationality__c, PropertyUsage__c, NumberOfBedrooms__c, Financing__c, Mortgage__c, PurposeOfUse__c,
         BuyRent__c, SalesType__c, MobilePhone
        FROM Lead WHERE BrokerAgent__c != null AND BrokerAgent__c =: contactUserId Order by createddate desc];
 
        List<AccountWithRelatedLeads> contactLeads = new List<AccountWithRelatedLeads>();

        for(lead leadRec : leads){

            AccountWithRelatedLeads acc = new AccountWithRelatedLeads();

            String mobileNumber = leadRec.MobilePhone;
            acc.title = leadRec.Salutation;
            acc.column0 = leadRec.Id;
            acc.column2 = leadRec.FirstName;
            acc.column3 = leadRec.LastName;
            acc.column4 = leadRec.Email;
            acc.column5 = mobileNumber;
            acc.column6 = leadRec.Nationality__c;
            acc.column7 = '';
            acc.column8 = leadRec.Id;

            acc.children = new List<Lead>{(leadRec)};

            contactLeads.add(acc);
        }

        return contactLeads;
    }

    @AuraEnabled(cacheable=false)
    public static User getUserDetails(String userId){

        List<User> user = [SELECT Id, ContactId, Contact.Account.Id, Contact.Account.Name, Contact.BlockSales__c FROM User WHERE Id =: userId limit 1];
        return user[0];

    }

    @AuraEnabled
    public static String maskString(String strText, integer start1, integer end1, String maskChar){
    
        if(strText == null || strText.equals(''))
            return '';
    
        if(start1 < 0)
            start1 = 0;
    
        if( end1 > strText.length() ) 
            end1 = strText.length();
    
            integer maskLength = end1 - start1;
    
        if(maskLength == 0)
            return strText;
    
        String sbMaskString='';
    
        for(integer i = 0; i < maskLength; i++){
            sbMaskString += maskChar;
        }   
    
        return strText.substring(0, start1) + sbMaskString + strText.substring(start1 + maskLength);
    }

    @AuraEnabled(cacheable=false)
    public static String createLead(Map<String, Object> leadInfoObject){
        try
        {
            Lead newLead = new Lead();
            
            if(leadInfoObject.get('leadId') != null && leadInfoObject.get('leadId') != ''){
                newLead.Id = (Id)leadInfoObject.get('leadId');
            }  else{
                newLead.MobileNumber1__c = (String)leadInfoObject.get('mobileNumber');
                newLead.Email = ((String)leadInfoObject.get('emailAddress'));
            }
            
            newLead.Salutation = (String)leadInfoObject.get('title');
            newLead.MobileCountryCode__c = (String)leadInfoObject.get('countryCode');
            newLead.FirstName = (String)leadInfoObject.get('firstName');
            newLead.LastName = (String)leadInfoObject.get('lastName');
            
            if(!(((String)leadInfoObject.get('emailAddress')).contains('*'))){
                newLead.Email = ((String)leadInfoObject.get('emailAddress'));
            } else{
                newLead.Email = ((String)leadInfoObject.get('realEmail'));
            }
            if(!((String)leadInfoObject.get('mobileNumber')).contains('*')){
                newLead.MobileNumber1__c = ((String)leadInfoObject.get('mobileNumber'));
            } else{
                String mobileNum = (String)leadInfoObject.get('realMobileNumber');
                newLead.MobileNumber1__c = mobileNum.substring(((String)leadInfoObject.get('countryCode')).length(),mobileNum.length());
            }
            newLead.ResidentStatus__c = (String)leadInfoObject.get('residentStatus');
            newLead.Nationality__c = (String)leadInfoObject.get('nationality');
            newLead.City = (String)leadInfoObject.get('city');
            // Added By Moh Sarfaraj for ASF-1998
            newLead.CustomerLocation__c = (String)leadInfoObject.get('city');
            newLead.SalesType__c = (String)leadInfoObject.get('salesType');
            newLead.PropertyUsage__c = (String)leadInfoObject.get('propertyUsage');
            newLead.BuyRent__c = (String)leadInfoObject.get('buyRent');
            newLead.Project__c = (String)leadInfoObject.get('property');
            newLead.UnitType__c = (String)leadInfoObject.get('unitType');
            newLead.NumberOfBedrooms__c = (String)leadInfoObject.get('numberOfBeds');
            newLead.Offer1__c = (String)leadInfoObject.get('events');
            newLead.PurposeOfUse__c = (String)leadInfoObject.get('purposeOfUse');
            newLead.Bulk__c = (String)leadInfoObject.get('bulk');
            newLead.PropertyReadiness__c = (String)leadInfoObject.get('propertyReadiness');
            newLead.Financing__c = (String)leadInfoObject.get('financing');
            newLead.CustomerBudget__c = (String)leadInfoObject.get('customerBudget');
            newLead.NationalId__c = (String)leadInfoObject.get('emiratesID');
            newLead.PassportNumber__c = (String)leadInfoObject.get('passportNumber');
            newLead.PassportExpiryDate__c = leadInfoObject.get('passportExpiryDate') != null ? Date.valueOf((String)leadInfoObject.get('passportExpiryDate')) : null;
            newLead.CountryOfResidence__c = (String)leadInfoObject.get('residanceCountry');
            newLead.Mortgage__c = (String)leadInfoObject.get('mortgage');
            newLead.SalesOrigin__c = (String)leadInfoObject.get('salesOrigin');
            newLead.LeadOrigin__c = (String)leadInfoObject.get('leadOrigin');
            
            newLead.LeadSource = 'Broker Portal';
            newLead.EnquiryCategory__c = (String)leadInfoObject.get('enquiryCategory');
            newLead.EnquiryTrigger__c = (String)leadInfoObject.get('enquiryTrigger');
            //Below is added by Tharun as per BPM-360 - consent
            newLead.Consent__c = (Boolean)leadInfoObject.get('consent');
            User userDetails = Utilities.getLoggedInUserDetail();
            
            newLead.BrokerAgency__c = userDetails.Contact.AccountId;
            newLead.BrokerAgent__c = userDetails.ContactId;
            newLead.Company =  (String)(leadInfoObject.containsKey('company')  ? leadInfoObject.get('company'):'');
            newLead.OwnerId = Utilities.getQueueInformation(Constants.BROKER_QUEUE).Id;
            Boolean isResale = false;
            //Resale code added by Muzammil
            //if(leadInfoObject.containsKey('isResaleUnit')){
            if(leadInfoObject.containsKey('isResaleUnit') && leadInfoObject.get('isResaleUnit') != null && leadInfoObject.get('isResaleUnit') != '' ){
                isResale = (Boolean) leadInfoObject.get('isResaleUnit');
                newLead.Lead_Type__c = 'Resale';            
            }
            //Resale code added by Muzammil
            //if(leadInfoObject.containsKey('resaleUnitId')){
            if(leadInfoObject.containsKey('resaleUnitId') && leadInfoObject.get('resaleUnitId') != null && leadInfoObject.get('resaleUnitId') != ''){
                newLead.Unit__c = (String)leadInfoObject.get('resaleUnitId');
            }
            if(leadInfoObject.containsKey('resaleUnitSalesOrderId')){
                //   newLead.Sales_Order__c = (String)leadInfoObject.get('resaleUnitSalesOrderId');
            }
            
            if(newLead.Id != null){
                if(isResale){
                    UtilitiesWithoutSharing.createUpdateLeadWithoutSharing(newLead);// Added this to create resale lead with unit - Muzammil
                }else{
                    update newLead;
                }
            } else{
                
                Datetime datetimeMinus1Hour = datetime.now().addHours(-1);
                
                system.debug('point: datetimeMinus1Hour: ' + datetimeMinus1Hour);
                
                List<Lead> leads = new List<Lead>([SELECT FirstName, LastName, Email, MobileNumber1__c, Project__c, Offer1__c, createdDate
                                                   FROM Lead Where createdDate >: datetimeMinus1Hour AND FirstName=: newLead.FirstName AND LastName=: newLead.LastName AND Email=: newLead.Email AND MobileNumber1__c=: newLead.MobileNumber1__c
                                                   AND Project__c =: newLead.Project__c ]);
                
                system.debug('point: leads: ' + leads);
                
                if(leads.size() > 0){
                    for(Lead lead : leads){
                        if(lead.Offer1__c != null && lead.Offer1__c == newLead.Offer1__c){
                            return 'Duplicate';
                        }
                    }
                    return 'Duplicate';
                }
                newLead.Status = Constants.WORKING_LEAD;
                if(isResale){
                    UtilitiesWithoutSharing.createUpdateLeadWithoutSharing(newLead);
                }else{
                    insert newLead;
                }
            }
            return 'Success';
        }
        catch(Exception ex){
            LoggerService.save(LoggerService.addApexLog(ex,'','BrokerLeadController','createLead'));
            return ex.getMessage();
        }
    }

    @AuraEnabled(cacheable=false)
    public static Lead getLeadById(String leadId){


        List<Lead> leadRec = [SELECT Salutation, FirstName, LastName, Project__c, UnitType__c, CreatedDate, Offer1__c, BrokerAgent__c, Email, MobileCountryCode__c, LeadNumber__c, BrokerAgent__r.Name,
         MobileNumber1__c, MobileNumber__c, Nationality__c, PropertyUsage__c, NumberOfBedrooms__c, Financing__c, Mortgage__c, PurposeOfUse__c, LeadOrigin__c, Country, EmailAddress__c, MobilePhone, 
         BuyRent__c, SalesType__c, ResidentStatus__c, City, Bulk__c, PropertyReadiness__c, CustomerBudget__c, NationalId__c, PassportNumber__c, PassportExpiryDate__c, SalesOrigin__c, CountryOfResidence__c,
         EnquiryCategory__c, EnquiryTrigger__c FROM Lead WHERE Id =: leadId order by CreatedDate asc];

        if(leadRec.size() > 0){
        leadRec[0].Email = leadRec[0].Email != null ? leadRec[0].Email : '' ;
        leadRec[0].MobileNumber1__c = leadRec[0].MobileNumber1__c != null ? leadRec[0].MobileNumber1__c : '';
    
        return leadRec[0];
        } else{
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static map<String,object> getsObjectType(Id recordID){
        map<String,sObject> mapToReturn = new map<String,sObject>();
        try{
            Schema.SObjectType sobjectType = recordID.getSObjectType();
            string sobjectName = sobjectType.getDescribe().getName();
            if(sobjectName.equalsIgnoreCase('Contact')){
                mapToReturn.put(sobjectName,[SELECT Salutation, FirstName, LastName, Email, MobilePhone, MobilePhone__c, Account.MobileCountryCode__c, Account.RecordType.Name, Title, Account.NationalIdNumber__pc, Account.AgencyRegion__c,
                                             Account.CreatedDate, PassportNumber__c, PassportExpiryDate__c, MailingCity, Nationality__c, MailingCountry, ResidentStatus__c
                                             FROM Contact WHERE Id =: recordID]);
            }else if(sobjectName.equalsIgnoreCase('Lead')){
                mapToReturn.put(sobjectName,getLeadById(String.valueOf(recordID)));
            }
        }
        catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,recordID,'BrokerLeadController','getsObjectType'));
        }
        return mapToReturn;
    }

    @AuraEnabled(cacheable=false)
    public static map<String,object> getsobjectName(String recordID){

        map<String,sObject> mapToReturn = new map<String,sObject>();

        Id recId = Id.valueOf(recordID);
        Schema.SObjectType sobjectType = recId.getSObjectType();
        string sobjectName = sobjectType.getDescribe().getName();

        if(sobjectName == 'Lead'){
            mapToReturn.put(sobjectName, getLeadById(recordID));
        }
        return mapToReturn;
    }

    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getCountryCodeValues(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Lead.MobileCountryCode__c.getDescribe();        
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }

    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getEmiratesValues(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Lead.Emirate__c.getDescribe();        
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getPropertyPicklistValues(){
        
        Schema.DescribeFieldResult fieldResult = Lead.Project__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> propertyPickList = new List<String>();
        
        for( Schema.PicklistEntry pickListVal : ple){
            propertyPickList.add(pickListVal.getLabel());
        }
        return propertyPickList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getNoOfBedroomPicklistValues(){
        
        Schema.DescribeFieldResult fieldResult = Lead.NumberOfBedrooms__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> noOfBedroomPickList = new List<String>();
        
        for( Schema.PicklistEntry pickListVal : ple){
            noOfBedroomPickList.add(pickListVal.getLabel());
        }
        return noOfBedroomPickList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getLeadOriginPicklistValues(){
        
        Schema.DescribeFieldResult fieldResult = Lead.LeadOrigin__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> leadOriginPickList = new List<String>();
        
        for( Schema.PicklistEntry pickListVal : ple){
            leadOriginPickList.add(pickListVal.getLabel());
        }
        return leadOriginPickList;
    }
    
    /* Name : maskEmail
     * Description: Masking the email address & mobile number as per BPE-265
     */ 
    @AuraEnabled
    public static String maskAnyString(String emailAddress) {
        if (emailAddress != null) {
            // Split the email address into local and domain parts
            List<String> parts = emailAddress.split('@');
            if (parts.size() == 2) {
                String localPart = parts[0];
                String maskedLocalPart = localPart.length() <= 1 ? localPart : localPart.substring(0, 1) + '*'.repeat(localPart.length() - 1);
                // Reconstruct the masked email address
                return maskedLocalPart + '@' + parts[1];
            }else{
                String maskedEmail = emailAddress.substring(0, 1) + '*'.repeat(emailAddress.length() - 1);
                return maskedEmail;
            }
        } else {
            return emailAddress;
        }
    }
    
    // Added By Moh Sarfaraj for BPE-279
    @AuraEnabled
    public static String validateBrokersEmailMobileForLeadCreation(String value, String type){
        try {
            Boolean canCreateLead = false;
            Id currentAgencyId = [SELECT AccountId FROM User WHERE Id = : UserInfo.getUserId()]?.AccountId;
            
            if(String.isNotBlank(currentAgencyId)){
                List<Contact> listBrokers = [SELECT Email, MobilePhone__c FROM Contact WHERE AccountId =:currentAgencyId];
                if(listBrokers != null && !listBrokers.isEmpty()){
                    canCreateLead = true;
                    // Mobile Validation
                    if(String.isNotBlank(type) && type.equalsIgnoreCase('MOBILE')){
                        for(Contact broker : listBrokers){
                            // Mobile Validation
                            if(broker?.MobilePhone__c?.deleteWhitespace() == value){
                                canCreateLead = false;
                                break;
                                return 'No'; 
                            }
                        } 
                        // Email Validation
                    }else if(String.isNotBlank(type) && type.equalsIgnoreCase('EMAIL')){
                        final Set<String> setIgnoreDomains = new Set<String>(System.Label.BPE_IgnoreBrokerEmailDomainToLeadCreation.split(','));
                        Set<String> setEmailDomains = new Set<String>();

                        for(Contact broker : listBrokers){
                            // Email Validation
                            setEmailDomains.add(broker?.Email?.split('@')[1]?.toLowerCase());
                        } 
                        setEmailDomains.removeAll(setIgnoreDomains);
                        canCreateLead = (setEmailDomains.contains(value.split('@')[1].toLowerCase())) ? false : true;
                    }
                }
            }
            return canCreateLead ? 'Yes' : 'No';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}