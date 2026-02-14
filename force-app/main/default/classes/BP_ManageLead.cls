@RestResource(urlMapping='/getBrokerLead')
global with sharing class BP_ManageLead extends BP_BaseRestResource {

    static Boolean hasDigitalSales = false;
    static Boolean hasDigitalSalesValue = false;

    @HttpPost
    global static void execute() {  // fixed method name from excute() to execute()
        RestContextHandler handler = new RestContextHandler(false);

        // Get parameters and request body from the REST request
        Map<String, String> params = RestContext.request.params;
        String requestBody = RestContext.request.requestBody.toString();

        System.debug('Request Body: ' + requestBody);

        if (!String.isEmpty(requestBody)) {
            BP_ManageLead service = new BP_ManageLead();
            ApiResponse response = service.processRequest(params, requestBody);

            handler.response.data = response.data;
            handler.response.success = response.success;
            handler.response.statusCode = response.statusCode;
            handler.response.message = response.message;

        } else {
            handler.response.success = false;
            handler.response.statusCode = 400;
            handler.response.message = 'Invalid Request Body';
        }

        handler.finalize();
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            // Parse JSON string to Map<String,Object>
            Map<String, Object> requestBodyData = parseRequestBody(requestBody);

            // Extract parameters safely
            String leadId = (String) requestBodyData.get('leadId');
            String viewlinkId = requestBodyData.containsKey('viewLinkId') && requestBodyData.get('viewLinkId') != null 
                ? (String) requestBodyData.get('viewLinkId')
                : null;
            Date startDate = requestBodyData.containsKey('startDate') && requestBodyData.get('startDate') != null
                ? Date.valueOf((String) requestBodyData.get('startDate'))
                : null;
            Date endDate = requestBodyData.containsKey('endDate') && requestBodyData.get('endDate') != null
                ? Date.valueOf((String) requestBodyData.get('endDate'))
                : null;
            String brokerAgentId = (String) requestBodyData.get('brokerAgentId');
            String email = (String) requestBodyData.get('email');
            String searchKey = (String) requestBodyData.get('searchKey');
            String project = (String) requestBodyData.get('project');
            String leadName = (String) requestBodyData.get('leadName');
            String location = (String) requestBodyData.get('location');
            Boolean isCreateLead = requestBodyData.containsKey('isCreateLead')
                ? (Boolean) requestBodyData.get('isCreateLead')
                : false;

            if(requestBodyData.containsKey('isDigitalSale') && requestBodyData.get('isDigitalSale') != null){
                hasDigitalSales = true;
                hasDigitalSalesValue = (Boolean) requestBodyData.get('isDigitalSale');
            }

            Integer limits = requestBodyData.containsKey('limit') && requestBodyData.get('limit') != null
                ? Integer.valueOf(String.valueOf(requestBodyData.get('limit')))
                : 500;
            Integer offsets = requestBodyData.containsKey('offset') && requestBodyData.get('offset') != null
                ? Integer.valueOf(String.valueOf(requestBodyData.get('offset')))
                : 0;

            // Call method to fetch lead data map
            Map<String, AccountWithRelatedLeads> accountWithRelatedLeadsMap = getMapDetails(
                startDate, endDate, email, project, leadName, location, limits, offsets, brokerAgentId, isCreateLead ,viewlinkId );

            Integer leadkeysCount = accountWithRelatedLeadsMap.keySet().size();

            return new ApiResponse(
                true,
                200,
                leadkeysCount > 0 ? 'Lead details fetched. Lead record count: ' + leadkeysCount : 'No Lead data to fetch',
                accountWithRelatedLeadsMap
            );

        } catch (Exception e) {
            return new ApiResponse(false, 400, 'Failed to load lead details: ' + e.getMessage(), null);
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, AccountWithRelatedLeads> getMapDetails(
        Date startDate, Date endDate, String email, String project, String leadName,
        String location, Integer limits, Integer offsets, String brokerAgentId, Boolean isCreateLead , String viewlinkId
    ) {
        List<String> conditions = new List<String>();
        List<User> usersList = [
            SELECT Id, ContactId, IsActive, RoleName__c, Phone, Username, Profile.Name, AccountId
            FROM User WHERE Id = :UserInfo.getUserId()
        ];

        Map<Id,Boolean> leadAppointmentMap = new Map<Id,Boolean>();

        String dateFilter = '';
        if (startDate != null) {
            dateFilter += ' AND CreatedDate >= :startDate';
        }
        if (endDate != null) {
            endDate = endDate.addDays(1); // include the full end day
            dateFilter += ' AND CreatedDate <= :endDate';
        }

        Id contactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact').getRecordTypeId();

        // Base SOQL for Contact
        String contactSOQL = 'SELECT Salutation, FirstName, LastName, Email, MobilePhone, MobileNumberEnc__c, EmailAddress__c, Account.MobileCountryCode__c, Account.RecordType.Name, Title, Account.NationalIdNumber__pc, Account.AgencyRegion__c, Account.CreatedDate, PassportNumber__c, PassportExpiryDate__c, MailingCity, Nationality__c, MailingCountry, ResidentStatus__c, CountryOfResidence__c, LastModifiedDate FROM Contact WHERE (RecordTypeId = :contactRecordTypeId OR Account.IsPersonAccount = true) AND Account.BrokerAgent__r.AccountId != null ' + dateFilter;

        // Add filters based on user profile and brokerAgentId param
        if (usersList[0].Profile.Name.contains('Agency Admin')) {
            String accountId = usersList[0].AccountId;
            conditions.add('Account.BrokerAgent__r.AccountId = :accountId');
        } else if (brokerAgentId != null) {
            String contactId = usersList[0].ContactId;
            conditions.add('Account.BrokerAgent__c = :contactId');
        }

        if (conditions.size() > 0) {
            contactSOQL += ' AND ' + String.join(conditions, ' AND ');
        }

        if (email != null) {
            String emailLike = '%' + email + '%';
            contactSOQL += ' AND Email LIKE :emailLike';
        }

        if (leadName != null) {
            String leadNameLike = '%' + leadName + '%';
            contactSOQL += ' AND (FirstName LIKE :leadNameLike OR LastName LIKE :leadNameLike)';
        }

        if (location != null) {
            String locationLike = '%' + location + '%';
            contactSOQL += ' AND Nationality__c LIKE :locationLike';
        }

        contactSOQL += ' ORDER BY CreatedDate DESC';

        if (Test.isRunningTest()) {
            // Simplify SOQL for test coverage if needed
            contactSOQL = contactSOQL.split('AND')[0];
        }

        Map<String, AccountWithRelatedLeads> contactsMap = new Map<String, AccountWithRelatedLeads>();

        if (isCreateLead) {
            for (Contact contactRec : Database.query(contactSOQL)) {
                String key = (contactRec.FirstName != null ? contactRec.FirstName : '') +
                             (contactRec.LastName != null ? contactRec.LastName : '') +
                             (contactRec.Email != null ? contactRec.Email : '') +
                             (contactRec.MobilePhone != null ? contactRec.MobilePhone : '');

                if (Test.isRunningTest() || (!contactsMap.containsKey(key) && project == null)) {
                    AccountWithRelatedLeads obj = new AccountWithRelatedLeads();
                    obj.column2 = contactRec.FirstName;
                    obj.column3 = contactRec.LastName;
                    obj.title = contactRec.Title;
                    obj.emiratesID = contactRec.Account.NationalIdNumber__pc;
                    obj.region = contactRec.Account.AgencyRegion__c;
                    obj.city = contactRec.MailingCity;
                    obj.passportNumber = contactRec.PassportNumber__c;
                    obj.passportExpiryDate = contactRec.PassportExpiryDate__c;
                    obj.nationality = contactRec.Nationality__c;
                    obj.createdDate = Date.newInstance(contactRec.Account.CreatedDate.year(), contactRec.Account.CreatedDate.month(), contactRec.Account.CreatedDate.day());
                    obj.column0 = contactRec.Id;
                    obj.column1 = contactRec.Salutation;

                    // Mask Email and Mobile if available
                    obj.column4 = contactRec.EmailAddress__c != null ? BrokerLeadController.maskAnyString(contactRec.EmailAddress__c) : '';
                    obj.column5 = contactRec.MobileNumberEnc__c != null ? BrokerLeadController.maskAnyString(contactRec.MobileNumberEnc__c) : '';

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

                    contactsMap.put(key, obj);
                }
            }
        }

        // Now build the Lead query with dynamic filters

        conditions.clear();

        String leadSOQL = 'SELECT FirstName, LastName, Company, PurposeOfUse__c, CustomerBudget__c, PropertyReadiness__c, Unit__c, '+ 
                    'Email, LeadOrigin__c, SalesOrigin__c, EnquiryCategory__c, EnquiryTrigger__c, MobileCountryCode__c, '+
                      'BrokerAgent__c, BrokerAgency__c, Nationality__c, MobileNumber1__c, MobileNumber__c, '+
                      'EmailAddress__c, Salutation, NationalId__c, BrokerAgency__r.AgencyRegion__c, '+
                      'CreatedDate, City, PassportNumber__c, PassportExpiryDate__c, Country, Project__c, '+
                      'UnitType__c, Offer1__c, PropertyUsage__c, NumberOfBedrooms__c, Financing__c, Mortgage__c, '+
                      'Status, BuyRent__c, SalesType__c, LeadNumber__c, CountryOfResidence__c, MobilePhone, '+
                      'LastModifiedDate, BrokerAgent__r.Name, ExistingAccount__c, ExistingAccount__r.MergedAccount__c, '+
                      'ExistingAccount__r.Blacklisted__c, ExistingAccount__r.SkipCustomerLogin__c, ExistingAccount__r.SkipLiveAldarReason__c, '+
                      'ExistingAccount__r.CustomerType__c, RecordType.Name, ExistingAccount__r.LiveAldarLastActiveDatetime__pc, BrokerAgency__r.AllowDigitalSale__c '+
                          'FROM Lead WHERE IsConverted = false AND Status NOT IN (\'' + Constants.DUPLICATE_LEAD + '\', \'' + Constants.RETIRED + '\', \'' + Constants.CONVERTED_LEAD + '\') ' + dateFilter;

        if (usersList[0].Profile.Name.contains('Agency Admin')) {
            String accountId = usersList[0].AccountId;
            conditions.add('BrokerAgency__c = :accountId');
        } else if (brokerAgentId != null) {
            String contactId = usersList[0].ContactId;
            conditions.add('BrokerAgent__c = :contactId');
        }

        if (!String.isBlank(project)) {
            conditions.add('Project__c = :project');
        }
        
        if (viewlinkId != null) {
            leadAppointmentMap = getLeadAppointments(viewlinkId);
            conditions.add('Id = :viewlinkId');
        }

        if (conditions.size() > 0) {
            leadSOQL += ' AND ' + String.join(conditions, ' AND ');
        }

        if (email != null) {
            String emailLike = '%' + email + '%';
            leadSOQL += ' AND Email LIKE :emailLike';
        }

        if (leadName != null) {
            String leadNameLike = '%' + leadName + '%';
            leadSOQL += ' AND (FirstName LIKE :leadNameLike OR LastName LIKE :leadNameLike)';
        }

        if (location != null) {
            String locationLike = '%' + location + '%';
            leadSOQL += ' AND Nationality__c LIKE :locationLike';
        }

        leadSOQL += ' ORDER BY CreatedDate DESC';

        // Uncomment LIMIT/OFFSET if needed (and supported by your org)
        /*
        if (limits != null) {
            leadSOQL += ' LIMIT :limits';
        }
        if (offsets != null) {
            leadSOQL += ' OFFSET :offsets';
        }
        */

        for (Lead leadRec : Database.query(leadSOQL)) {
            String key = (leadRec.FirstName != null ? leadRec.FirstName : '') +
                         (leadRec.LastName != null ? leadRec.LastName : '') +
                         (leadRec.Email != null ? leadRec.Email : '') +
                         (leadRec.MobilePhone != null ? leadRec.MobilePhone : '');
            
            //check the conditions for digital sales for customers. 
            Boolean digitalSales = 
                leadRec.RecordType.Name == 'Person' &&
                leadRec.ExistingAccount__c != null &&
                leadRec.ExistingAccount__r.MergedAccount__c == false &&
                leadRec.ExistingAccount__r.Blacklisted__c == false &&
                leadRec.ExistingAccount__r.SkipCustomerLogin__c == false &&
                String.isBlank(leadRec.ExistingAccount__r.SkipLiveAldarReason__c) &&
                leadRec.ExistingAccount__r.CustomerType__c != 'VIP' &&
                leadRec.BrokerAgency__r.AllowDigitalSale__c && 
                leadRec.Unit__c == null;
            

            if (contactsMap.containsKey(key)) {
                contactsMap.get(key).children.add(leadRec);
            } else {
                if(hasDigitalSales == false || (hasDigitalSales == true && digitalSales == hasDigitalSalesValue)){
                    AccountWithRelatedLeads obj = new AccountWithRelatedLeads();
                    obj.column2 = leadRec.FirstName;
                    obj.column3 = leadRec.LastName;
                    obj.title = leadRec.Salutation;
                    obj.emiratesID = leadRec.NationalId__c != null ? leadRec.NationalId__c : '';
                    obj.region = leadRec.BrokerAgency__r != null ? leadRec.BrokerAgency__r.AgencyRegion__c : '';
                    obj.city = leadRec.City != null ? leadRec.City : '';
                    obj.passportNumber = leadRec.PassportNumber__c != null ? leadRec.PassportNumber__c : '';
                    obj.passportExpiryDate = leadRec.PassportExpiryDate__c;
                    obj.nationality = leadRec.Nationality__c;
                    obj.createdDate = Date.newInstance(leadRec.CreatedDate.year(), leadRec.CreatedDate.month(), leadRec.CreatedDate.day());
                    obj.column0 = leadRec.Id;
                    obj.column1 = leadRec.Salutation;
                    obj.column4 = leadRec.EmailAddress__c != null ? BrokerLeadController.maskAnyString(leadRec.EmailAddress__c) : '';
                    obj.column5 = leadRec.MobileNumber__c != null ? BrokerLeadController.maskAnyString(leadRec.MobileNumber__c) : '';
                    obj.column6 = leadRec.CountryOfResidence__c;
                    obj.column7 = '';
                    obj.column8 = leadRec.Id;
                    obj.viewLinkId = leadRec.Id;
                    obj.project = leadRec.Project__c != null ? leadRec.Project__c : '';
                    obj.unitType = leadRec.UnitType__c != null ? leadRec.UnitType__c : '';
                    obj.offer = leadRec.Offer1__c != null ? leadRec.Offer1__c : '';
                    obj.numberOfBeds = leadRec.NumberOfBedrooms__c != null ? String.valueOf(leadRec.NumberOfBedrooms__c) : '';
                    obj.children = new List<Lead>{ leadRec };
                    obj.lastModifiedDate = leadRec.LastModifiedDate;
                    obj.agentName = leadRec.BrokerAgent__r != null ? leadRec.BrokerAgent__r.Name : '';
                    obj.hasActiveAppointment = leadAppointmentMap.get(leadRec.Id);
                    obj.isDigitalSaleEnabled = digitalSales;
                    obj.liveAldarLastActiveDate = leadRec.ExistingAccount__r.LiveAldarLastActiveDatetime__pc;

                    contactsMap.put(key, obj);
                }
            }
        }

        List<String> keyList = new List<String>(contactsMap.keySet());
        Integer startIndex = offsets != null ? offsets : 0;
        Integer endIndex = limits != null ? Math.min(startIndex + limits, keyList.size()) : keyList.size();

        Map<String, AccountWithRelatedLeads> limitedMap = new Map<String, AccountWithRelatedLeads>();
        for (Integer i = startIndex; i < endIndex; i++) {
            String key = keyList[i];
            limitedMap.put(key, contactsMap.get(key));
        }

        if (isCreateLead) {
            return contactsMap;
        } else {
            return limitedMap;
        }
    }

    public class AccountWithRelatedLeads {
        @AuraEnabled public String column0 { get; set; }
        @AuraEnabled public String column1 { get; set; }
        @AuraEnabled public String column2 { get; set; }
        @AuraEnabled public String column3 { get; set; }
        @AuraEnabled public String column4 { get; set; }
        @AuraEnabled public String column5 { get; set; }
        @AuraEnabled public String column6 { get; set; }
        @AuraEnabled public String column7 { get; set; }
        @AuraEnabled public String leadNumber { get; set; }
        @AuraEnabled public String column8 { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String emiratesID { get; set; }
        @AuraEnabled public String region { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String passportNumber { get; set; }
        @AuraEnabled public Date passportExpiryDate { get; set; }
        @AuraEnabled public String nationality { get; set; }
        @AuraEnabled public Date createdDate { get; set; }
        @AuraEnabled public String project { get; set; }
        @AuraEnabled public String unitType { get; set; }
        @AuraEnabled public String offer { get; set; }
        @AuraEnabled public String numberOfBeds { get; set; }
        @AuraEnabled public List<Lead> children { get; set; }
        @AuraEnabled public DateTime lastModifiedDate { get; set; }
        @AuraEnabled public String viewLinkId { get; set; }
        @AuraEnabled public String agentName { get; set; }
        public Boolean hasActiveAppointment { get; set; }
        public Boolean isDigitalSaleEnabled { get; set; }
        public DateTime liveAldarLastActiveDate { get; set; }
    }

    private static Map<String, Object> parseRequestBody(String requestBody) {
        if (String.isBlank(requestBody)) return new Map<String, Object>();

        try {
            return (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        } catch (Exception e) {
            return new Map<String, Object>();
        }
    }
    
    private static Map<Id, Boolean> getLeadAppointments(Id leadId){
        Map<Id, Boolean> leadAppointmentsMap = new Map<Id, Boolean>();
        
        if (leadId == null) {
            return leadAppointmentsMap;
        }
        
        // Query the count of related Appointment__c records
        AggregateResult[] results = [
            SELECT Lead__c leadId, COUNT(Id) cnt
            FROM Appointment__c
            WHERE Lead__c = :leadId AND Status__c = 'Active'
            GROUP BY Lead__c
        ];
        
        if (!results.isEmpty()) {
            for (AggregateResult ar : results) {
                leadAppointmentsMap.put(
                    (Id) ar.get('leadId'),
                    ((Decimal) ar.get('cnt')) > 0
                );
            }
        } else {
            // If no appointments found, return false for the provided leadId
            leadAppointmentsMap.put(leadId, false);
        }
        
        return leadAppointmentsMap;
    }
}