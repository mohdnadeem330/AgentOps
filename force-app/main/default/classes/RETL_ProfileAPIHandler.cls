/*
* Name               : RETL_ProfileAPIHandler
* Description        : Helper class for Business Contact Profile API
* Creaed By          : Protiviti
* Version			 : V1.1 Added by Protiviti when retail contact logic added to CustomerProfileWeservice class.
*/
public without sharing class RETL_ProfileAPIHandler {
    public static Map<Id, List<RETL_Contact_Role__c>> accContactRoles; 
    public static String contactId;
    /* @description Method to find contacts by email or Emirates ID  @return List of contact*/
    public static List<Contact> findContacts(String email, String emiratesId) {
        List<Contact> contactList =  new List<Contact>();
        if (String.isNotBlank(emiratesId)) {
            contactList =  [
                SELECT Id, AccountId, Account.CustomerVertical__c, Name, FirstName, LastName, Title, RETL_Profile_Image__c,
                RETL_Yardi_Id__c, Email, MobileCountryCode__c, MobilePhone, Nationality__c, NationalIdNumber__c, // RETL_Authorized_Signatory__c,
                MailingCountry, RETL_Number_of_Login__c, (select Account.CustomerVertical__c from AccountContactRelations)
                FROM Contact
                WHERE NationalIdNumber__c = :emiratesId AND  RecordType.Name = 'Contact'
                AND RETL_SkipContactLogin__c = false WITH USER_MODE
            ];
        } else if (String.isNotBlank(email)) {
            contactList =  [
                SELECT Id, AccountId, Account.CustomerVertical__c, Name, FirstName, LastName, Title, RETL_Profile_Image__c,
                RETL_Yardi_Id__c, Email, MobileCountryCode__c, MobilePhone, Nationality__c, NationalIdNumber__c, // RETL_Authorized_Signatory__c,
                MailingCountry, RETL_Number_of_Login__c, (select Account.CustomerVertical__c from AccountContactRelations)
                FROM Contact
                WHERE Email = :email
                AND RecordType.Name = 'Contact'
                AND RETL_SkipContactLogin__c = false WITH USER_MODE
            ];
        }
        return contactList;
    }
    

    /* @description  Method to prepare contact data for authentication response  @return collection of modified contact data*/
    public static Map<String,Object> prepareContactData(Contact contact) {
        Map<String, Object> contactData = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(contact));
        String customerVertical = getCustomerVertical(contact);
        
        contactData.put('CustomerVertical__c', customerVertical);
        
        contactData.remove('Account');
        contactData.remove('AccountContactRelations');
        contactData.remove('RETL_Number_of_Login__c');
        contactData.remove('RecordTypeId');
        return contactData;
    }
    
    /*@description Method to get username if contact is a portal user*/
    public static String checkAndFetchPortalDetail(Id contactId){
        List<User> userList =  [
            SELECT Id, Name, Username, Email, ContactId ,  UserType
            FROM User
            WHERE ContactId = :contactId 
            LIMIT 1
        ];
        string userName;
        if(userList != null && ! userList.isEmpty()){
            userName = userList[0].userName;
        }
        return userName;
    }

    /* @description  Method to prepare customer vertical @return string  of customer verticals from all related accounts*/
    private static String getCustomerVertical(Contact con){
        Map<String, Object> contactData = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(con));
        Set<String> verticalsSet = new Set<String>();
        if (con.Account != null && String.isNotBlank(con.Account.CustomerVertical__c)) {
            verticalsSet.addAll(con.Account.CustomerVertical__c.split(';'));
        }
        if (con.AccountContactRelations != null) {
            for (AccountContactRelation acr : con.AccountContactRelations) {
                if (acr.Account != null && String.isNotBlank(acr.Account.CustomerVertical__c)) {
                    verticalsSet.addAll(acr.Account.CustomerVertical__c.split(';'));
                }
            }
        }
        String customerVertical = String.join(new List<String>(verticalsSet), ';');
        return customerVertical;
    }

    /* @description  Method to prepare contact data for profileAPI response  @return wrapper of Data (Contact Info, Account Info, Lease Info, lease units, document) */
    public static ContactModel  processProfileAPI(Contact contact){
        ContactModel contactData = new ContactModel(contact);
        contactId = contact.Id;
        String username = checkAndFetchPortalDetail( contact.Id);
        contactData.username = username != null?username:null;
        contactData.isPortalUser = username != null?true:false;
        contactData.customerVerticals = getCustomerVertical(contact);
        List<BusinessAccountModel> businessAccountData = fetchRelatedBusinessAccounts(contact);
        contactData.accounts = businessAccountData;
        return contactData;
    }

    /* @description  Main Method for creating ProfileAPI response  @return collection of Wrapper containing all Account and related data*/
    public static List<BusinessAccountModel> fetchRelatedBusinessAccounts(Contact contact) {
		// This query retrieves all account Ids associated with a specific contact using the AccountContactRelation object.
        Set<Id> relatedAccountIds = getBusinessAccountDetail(contact.Id);
        system.debug('relatedAccountIds'+relatedAccountIds);
        accContactRoles = new  Map<Id, List<RETL_Contact_Role__c>>();
        //Get leases related to accounts
    	List<Order> accountLeases = !relatedAccountIds.isEmpty() ? getDirectOrders(relatedAccountIds) : new List<Order>();
        List<Order> contactLeases = getContactRelatedLease(contact.Id);
        //lead to lease update
        Set<Id> oppRelatedAccountIds = new Set<Id>();
        Map<Id,List<Opportunity>> accountToOpportunities = new Map<Id,List<Opportunity>>();
        List<Opportunity> relatedOpps = getRelatedOpportunities(contact.Id);
        if( !relatedOpps.isEmpty() ){
            for(Opportunity opp: relatedOpps){
                oppRelatedAccountIds.add(opp.AccountId);
                if(!accountToOpportunities.ContainsKey(opp.AccountId)){
                    accountToOpportunities.put(opp.AccountId, new List<Opportunity>());
                }
                accountToOpportunities.get(opp.AccountId).add(opp);
            }
        }
        system.debug('accountToOpportunities'+accountToOpportunities);
        // Combine both list of leases into a single map to avoid duplicates
        Map<Id,Order> allLeasesMap = new Map<Id,Order>();
        allLeasesMap.putAll(accountLeases);
        allLeasesMap.putAll(contactLeases);
        //If no leases at all, return empty
        if (allLeasesMap.isEmpty() && accountToOpportunities.isEmpty()) {
            return new List<BusinessAccountModel>();
        }
        // Create a map of account Ids with their related orders
        Map<Id, List<Order>> accountOrdersMap = new Map<Id, List<Order>>();
        Map<Id, List<OrderItem>> orderItemsMap = new Map<Id, List<OrderItem>>();
        Map<Id, List<RETL_Contact_Role__c>> orderContactRoleMap = new Map<Id, List<RETL_Contact_Role__c>>();
        Set<Id> accountLeaseIds = new Set<Id>();
        for (Order lease : allLeasesMap.values()) {
            // Get the account Ids from all leases
            accountLeaseIds.add(lease.AccountId);
            // Build Order to OrderItems map
            if (lease.OrderItems != null && !lease.OrderItems.isEmpty()) {
                orderItemsMap.put(lease.Id, lease.OrderItems);
            }
            // Build Order to COntact Role Map
            /*if( lease.Contact_roles__r != null && !lease.Contact_roles__r.isEmpty()){
                orderContactRoleMap.put(lease.Id, lease.Contact_roles__r);
            }*/
            // Build Account to Orders map
            if (!accountOrdersMap.containsKey(lease.AccountId)) {
                accountOrdersMap.put(lease.AccountId, new List<Order>());
            }
            accountOrdersMap.get(lease.AccountId).add(lease);
        }
        //get the contact roles related to lease accounts and contact's accounts
        for(RETL_Contact_Role__c cr:[
            SELECT Id, RETL_Account_Name__c, RETL_Contact__c, RETL_Yardi_Id__c, RETL_Contact__r.FirstName,RETL_Contact__r.LastName, 
            RETL_Contact__r.Email, RETL_Contact__r.MobilePhone, RETL_Contact__r.RETL_Yardi_Id__c, 
            RETL_Contact__r.RETL_Profile_Image__c, RETL_Contact_role__c, RETL_Contact__r.Phone, RETL_Is_Authorized_Signatory__c 
            FROM RETL_Contact_Role__c 
            WHERE RETL_Account_Name__c IN: accountLeaseIds]){
            if (!accContactRoles.containsKey(cr.RETL_Account_Name__c)) {
                accContactRoles.put(cr.RETL_Account_Name__c, new List<RETL_Contact_Role__c>());
            }
            accContactRoles.get(cr.RETL_Account_Name__c).add(cr);
        }
        // Fetch details of the accounts and store as a map
        Map<Id, Account> accountDetailsMap = new Map<Id, Account>([
            SELECT Id, AccountNumber, CustomerVertical__c, Name, Type, RETL_Yardi_Id__c, RETL_Status__c, 
            (Select AccountId, Roles From AccountContactRelations WHERE ContactId = :contact.Id),
            (Select Id, RETL_Account_Name__c, RETL_Contact__c, RETL_Contact_role__c from Contact_roles__r WHERE RETL_Contact__c =:contact.Id ) 
            FROM Account WHERE ( Id IN :accountLeaseIds /*AND RETL_Status__c = 'Active'*/ ) OR (Id IN : oppRelatedAccountIds) WITH USER_MODE
        ]);
        system.debug('accountDetailsMap'+accountDetailsMap);
        Map<Id, List<Document__c>> accountDocsMap = buildAccountToDocsMap(allLeasesMap.keySet(), accountDetailsMap.keySet());
        return buildBusinessAccountsWrapper(accountDetailsMap, accountOrdersMap, accountDocsMap, accountToOpportunities);
    }

     /* @description  Method for generating Account- Document Map  @return collection of Account Id-Document Map */
    private static Map<Id, List<Document__c>> buildAccountToDocsMap(Set<Id> leaseIds, Set<Id> accountIds) {
        Map<Id, List<Document__c>> accountToDocs = new Map<Id, List<Document__c>>();
        List<Document__c> docs = getDocuments(leaseIds, accountIds);
        for (Document__c doc : docs) {
            Id accId = doc.Account__c != null ? doc.Account__c  : doc.Order__r.AccountId;
            List<Document__c> docList = accountToDocs.get(accId);
            if (docList == null) {
                docList = new List<Document__c>();
                accountToDocs.put(accId, docList);
            }
            docList.add(doc);
        }
        return accountToDocs;
    }

    /* @description  Method to prepare data for BusinessAccountModel  @return collection of BusinessAccountModel*/
    private static List<BusinessAccountModel> buildBusinessAccountsWrapper(Map<Id, Account> accountMap, Map<Id, List<Order>> accountToOrders, Map<Id, List<Document__c>> accountToDocs, Map<Id, List<Opportunity>> accountToOpportunities) {
        if (accountMap == null || accountMap.isEmpty()) {
            return new List<BusinessAccountModel>();
        }
        List<BusinessAccountModel> result = new List<BusinessAccountModel>();
        for (Id accId : accountMap.keySet()) {
            Account acc = accountMap.get(accId);
            BusinessAccountModel bAcc = new BusinessAccountModel(acc);
			bAcc.leases = buildLeaseModel(accountToOrders.get(accId));
            bAcc.proposals = buildOpportunityModel(accountToOpportunities.get(accId));
            bAcc.Documents = buildDocumentModel(accountToDocs.get(accId));
			result.add(bAcc);
        }
        return result;
    }
    /* @description  Method to create response for lease  @return collection of Lease*/
    private static List<LeaseModel> buildLeaseModel(List<Order> orders) {
        List<LeaseModel> leases = new List<LeaseModel>();
        if (orders != null) {
            for (Order ord : orders) {
                leases.add(new LeaseModel(ord));
            }
        }
        return leases;
    }

    /* @description  Method to create response for opportunity  @return collection of Opportunity*/
    private static List<OpportunityModel> buildOpportunityModel(List<Opportunity> opportunities){
        List<OpportunityModel> oppoList = new List<OpportunityModel>();
        if (opportunities != null) {
            for (Opportunity ord : opportunities) {
                oppoList.add(new OpportunityModel(ord));
            }
        }
        return oppoList;
    } 
    /* @description  Method to create response for document  @return collection of Document*/
    private static List<DocumentModel> buildDocumentModel(List<Document__c> documents) {
        List<DocumentModel> docList = new List<DocumentModel>();
        if (documents != null) {
            for (Document__c doc : documents) {
                docList.add( new DocumentModel(doc));
            }
        }
        return docList;
    }

    /* @description  Method to Capture the last login date and number of login @return  contact*/
    public static Contact  updateContact(Id contactId, Decimal loginCount){
        Contact con = new Contact();
        con.RETL_Last_Login__c = System.now();
        con.Id = contactId;
        con.RETL_Number_of_Login__c = loginCount != null? loginCount+ 1 : 1;
        return con;
    }

    //Get Contact and Parent customer info.
    public static Set<Id> getBusinessAccountDetail(Id contactId) {
        Set<Id> relatedAccountIds = new Set<Id>();
        for(AccountContactRelation acr:[SELECT AccountId FROM AccountContactRelation WHERE ContactId = :contactId  AND Account.RETL_Status__c = 'Active' AND Account.RecordType.Name = 'Organization Account' WITH USER_MODE]){
            relatedAccountIds.add(acr.AccountId);
        }
        for(RETL_Contact_role__c cr:[SELECT RETL_Account_Name__c FROM RETL_Contact_role__c WHERE RETL_Contact__c = :contactId AND RETL_Account_Name__r.RETL_Status__c = 'Active' AND RETL_Account_Name__r.RecordType.Name = 'Organization Account' WITH USER_MODE]){
            relatedAccountIds.add(cr.RETL_Account_Name__c);
        }
        return relatedAccountIds ;
    }

    //Get Leases from Account.
    public static List<Order> getDirectOrders(Set<Id> accountIds){
        
        // This query retrieves all orders associated with the accounts related to the specified contact.
        List<Order> accountLeases =  [
            SELECT Id, AccountId, Status, RETL_Yardi_Id__c, RETL_Status__c, RETL_Brand__c, RETL_Brand__r.Name, RETL_Location__c, RETL_Property_Name__c,RETL_Property_Description__c, RETL_Contracted_Area__c, 
            (SELECT Id,  RETL_Area__c, RETL_PropertyName__c, RETL_Unit__c, RETL_Building__c, ServiceDate, RETL_UnitType__c, OrderId, RETL_MoveOutDate__c, RETL_MoveInDate__c, RETL_Location__c, RETL_Yardi_Id__c, RETL_Floor__c, EndDate FROM OrderItems)
            ,(Select Id, RETL_Contact__c, RETL_Yardi_Id__c, RETL_Contact__r.FirstName,RETL_Contact__r.LastName, RETL_Contact__r.Email, RETL_Contact__r.MobilePhone, RETL_Contact__r.RETL_Yardi_Id__c, RETL_Contact__r.RETL_Profile_Image__c, RETL_Contact_role__c, RETL_Contact__r.Phone From Contact_roles__r )
            FROM Order
            WHERE  RETL_Status__c = 'Current' AND (AccountId IN :accountIds OR Account.ParentId IN :accountIds OR Account.Parent.ParentId IN :accountIds)  WITH USER_MODE
        ];
        return accountLeases;
    }
    /*public static List<Order> getDirectOrders(Set<Id> accountIds){
        List<RETL_Contact_role__c> cr = [ Select RETL_Lease__r.Id, RETL_Lease__r.AccountId, RETL_Lease__r.Status, RETL_Lease__r.RETL_Yardi_Id__c, RETL_Lease__r.RETL_Status__c, RETL_Lease__r.RETL_Brand__c, RETL_Lease__r.RETL_Brand__r.Name, RETL_Location__c, RETL_Lease__r.RETL_Property_Name__c,RETL_Lease__r.RETL_Property_Description__c, RETL_Lease__r.RETL_Contracted_Area__c 
                                         from RETL_Contact_role__c WHERE RETL_Account_Name__c IN: accountIds]
    }*/
    

    //Get contact Role info from Contact Role. This will help to get leases related to contact
    public static List<Order> getContactRelatedLease(Id contactId){
        // This query retrieves all orders associated with a specific contact using the Contact_Role__c object.
        List<Order> contactLeases = [
            SELECT Id, AccountId, Status, RETL_Yardi_Id__c, RETL_Status__c, RETL_Brand__c, RETL_Brand__r.Name, RETL_Location__c, RETL_Property_Name__c, RETL_Property_Description__c, RETL_Contracted_Area__c, (SELECT Id,  RETL_Area__c,  RETL_Building__c, RETL_Unit__c,  RETL_UnitType__c, OrderId, RETL_MoveOutDate__c, RETL_MoveInDate__c, RETL_Location__c, RETL_Yardi_Id__c, RETL_Floor__c, EndDate, RETL_PropertyName__c FROM OrderItems)
            ,(Select Id, RETL_Contact__c, RETL_Yardi_Id__c, RETL_Contact__r.FirstName,RETL_Contact__r.LastName, RETL_Contact__r.Email, RETL_Contact__r.MobilePhone, RETL_Contact__r.RETL_Yardi_Id__c, RETL_Contact__r.RETL_Profile_Image__c, RETL_Contact_role__c, RETL_Contact__r.Phone From Contact_roles__r )
            FROM Order
            WHERE Id IN (SELECT RETL_Lease__c FROM RETL_Contact_Role__c WHERE RETL_Contact__c = :contactId) AND RETL_Status__c = 'Current' WITH USER_MODE
        ];
        return  contactLeases;
    }
    
    //Fetch opportunities related to contact account.
	public static List<Opportunity> getRelatedOpportunities(Id ContactId){
        List<Opportunity> oppList = [SELECT Id, AccountId, Name, CloseDate, Start_Date__c, StageName , RETL_Yardi_Id__c, RETL_Project__r.Name, RETL_Live_Aldar_Phase__c, RETL_Tenant_Code__c, RETL_Yardi_Proposal_Id__c,   
                                     		RETL_Brand__r.Name, RETL_Project__r.ProjectCode__c, RETL_Project__r.RETL_Property_Yardi_Code__c, RETL_Project__r.Image_URL__c
                                     FROM Opportunity
                                     WHERE StageName != 'Closed Lost' AND RETL_Live_Aldar_Phase__c != null AND AccountId IN (SELECT RETL_Account_Name__c FROM RETL_Contact_Role__c WHERE RETL_Contact__c =: ContactId)];
        return oppList;
    }
    
    //Fetch documents linked to either Order or Account
    public static List<Document__c> getDocuments(Set<Id> leaseIds, Set<Id> accountIds){
        List<Document__c> documents = [
                                       SELECT Id, Other_Document_Name__c,AttachmentUpdatedTime__c,ContentSize__c, Order__c, Order__r.Name, Order__r.AccountId,  Account__r.Name, Account__c, DocumentType__c, RETL_Yardi_Id__c
                                       FROM Document__c
                                       WHERE Order__c IN :leaseIds OR Account__c IN :accountIds WITH USER_MODE
                                      ];
        return documents;
    }

	/* @description  Method to Create case when duplicate contact found @return  case*/
    public static Case createCaseHelperForContact( List<Contact> contactList, Boolean isRegistration) {
        Group queue                                                       = Utilities.getQueueInformation('MergeCaseQueue');
        String caseOwnerId                                          	  = queue.Id != null ? queue.Id : UserInfo.getUserId();
        Case newCase                                                   	  = new Case();
        newCase.RecordTypeId                    						  = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT);
        newCase.CustomerType__c                          				  = CustomerAPIConstants.CASE_CUSTOMER_TYPE_OWNER;
        newCase.Origin                                                 	  = CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL;
        newCase.AccountId   											  = contactList[0].AccountId != null ? contactList[0].AccountId : null;
        newCase.ContactId                                                 =  contactList[0].Id;
        newCase.CaseCategory__c                           				  = 'Data - Account Merge';
        newCase.Subject                                					  = CustomerAPIConstants.MULTI_CONTACT_FOUND_SUBJECT + ' ' + contactList[0].Email;
        newCase.CustomerComment__c 										  = isRegistration ? CustomerAPIConstants.MULTI_CONTACT_FOUND_REGISTRATION : CustomerAPIConstants.MULTI_CONTACT_FOUND_LOGIN;
        newCase.SubVertical__c                  						  = 'Customer Portal and App - Live Aldar';
        newCase.OwnerId                              					  = caseOwnerId;
        newCase.isValidationBypass__c 									  = true;
        Database.DMLOptions options                                       = new Database.DMLOptions();
        options.assignmentRuleHeader.useDefaultRule 					  = false;
        newCase.setOptions(options);
        return newCase;
    }

    /* @description  Future Method to Create case when duplicate contact found */
    /*@future()
    public static void createCaseHelperForContact( String jsonContact, Boolean isRegistration) {
        Contact cont = (Contact)JSON.deserialize(jsonContact, Contact.class);
        Group queue                                                       = Utilities.getQueueInformation('MergeCaseQueue');
        String caseOwnerId                                          	  = queue.Id != null ? queue.Id : UserInfo.getUserId();
        Case newCase                                                   	  = new Case();
        newCase.RecordTypeId                    						  = Utilities.getRecordTypeId('Case', Constants.STANDARD_CASE_RT);
        newCase.CustomerType__c                          				  = CustomerAPIConstants.CASE_CUSTOMER_TYPE_OWNER;
        newCase.Origin                                                 	  = CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL;
        newCase.AccountId   											  = cont.AccountId != null ? cont.AccountId : null;
        newCase.ContactId                                                 =  cont.Id;
        newCase.CaseCategory__c                           				  = 'Data - Account Merge';
        newCase.Subject                                					  = CustomerAPIConstants.MULTI_CONTACT_FOUND_SUBJECT + ' ' + cont.Email;
        newCase.CustomerComment__c 										  = isRegistration ? CustomerAPIConstants.MULTI_CONTACT_FOUND_REGISTRATION : CustomerAPIConstants.MULTI_CONTACT_FOUND_LOGIN;
        newCase.SubVertical__c                  						  = 'Customer Portal and App - Live Aldar';
        newCase.OwnerId                              					  = caseOwnerId;
        newCase.isValidationBypass__c 									  = true;
        Database.DMLOptions options                                       = new Database.DMLOptions();
        options.assignmentRuleHeader.useDefaultRule 					  = false;
        newCase.setOptions(options);
        try{
            insert as user newCase;
        }
        catch(exception e){
            LoggerService.save(LoggerService.addApexLog(e,'DuplicateContactCaseCreation','CustomerProfileWebservice','getProfileData'));
        }
    }*/
    /* @description  wrapper for contact node @return  */
    public class ContactModel{
        public String id;
        public String accountId;
        public String name;
        public String firstName;
        public String lastName;
        public String email;
        public String yardiId;
        public String nationality;
        public String nationalIdNumber;
        public String mailingCountry;
        public String mobileNumber;
        public String customerVerticals;
        public String countryCode;
        public String profileImage;
        public String designation;
        public String username;//for login to service request through lightning out
        public Boolean isPortalUser;
        // public Boolean isAuthorizedSignatory;
        public List<BusinessAccountModel> accounts;
        public ErrorWrapper error;

        public ContactModel(){
            this.error = new ErrorWrapper();
        }
        public ContactModel(Contact con){
            this.id = con.Id;
            this.accountId = con.AccountId;
            this.name = con.Name;
            this.firstName = con.FirstName;
            this.lastName = con.LastName;
            this.email = con.Email;
            this.yardiId = con.RETL_Yardi_Id__c;
            this.nationality = con.Nationality__c;
            this.nationalIdNumber = con.NationalIdNumber__c;
            this.mailingCountry = con.MailingCountry;
            this.mobileNumber = con.MobilePhone;
            this.customerVerticals =   con.Account?.CustomerVertical__c != null ? con.Account.CustomerVertical__c : null ;
            this.countryCode = con.MobileCountryCode__c;
            this.profileImage =con.RETL_Profile_Image__c;
            this.designation = con.Title;
            // this.isAuthorizedSignatory = con.RETL_Authorized_Signatory__c;
            this.accounts = new List<BusinessAccountModel>();
        }

    }

    /*@description  wrapper for capturing data when error occur @return  */
    public class ErrorWrapper {//wrapper for capturing data when error occur.
        public Integer errorCode;
        public String message;
        public ErrorWrapper(){
            this.errorcode = null;
            this.message = null;
        }
        public ErrorWrapper(Integer code, String msg) {//constructor with parameter
            errorCode = code;
            message = msg;
        }
    }
    /*@description  wrapper for capturing data from bussiness accounts to build the response @return  */
    public class BusinessAccountModel {
        public String id;
        public String name;
        public String type;
        public String contactRoles;
        public Boolean isAuthorizedSignatory;
        public String yardiId;
        public String status;
        public List<LeaseModel> leases;
        public List<OpportunityModel> proposals;
        public List<DocumentModel> documents;

        public BusinessAccountModel(Account acc){
            this.id = acc.Id;
            this.name = acc.Name;
            this.type = acc.Type != null?acc.Type:null;
            this.yardiId = acc.RETL_Yardi_Id__c!= null?acc.RETL_Yardi_Id__c:null;
            this.contactRoles = null;
            this.isAuthorizedSignatory = false;
            this.status =acc.RETL_Status__c != null?acc.RETL_Status__c:null;
            if (acc.AccountContactRelations != null) {
                for (AccountContactRelation acr : acc.AccountContactRelations) {
                    this.contactRoles = acr.Roles != null ? acr.Roles : null;
                }
            }
            else if(acc.Contact_Roles__r != null){
                Set<String> contactRolesList = new Set<String>();
                for (RETL_Contact_Role__c cr : acc.Contact_Roles__r) {
                    if(cr.RETL_Contact_role__c != null && cr.RETL_Contact__c == contactId){
                        contactRolesList.add(cr.RETL_Contact_role__c);
                    }
                    if(cr.RETL_Is_Authorized_Signatory__c == true && cr.RETL_Contact__c == contactId ){
                        this.isAuthorizedSignatory = true;
                    }
                }
                if(!contactRolesList.isEmpty()){
                    this.contactRoles = String.join(new List<String>(contactRolesList), ', ');
                }
            }
        }
    }
    /*@description  wrapper for capturing data from lease @return  */
    public class LeaseModel {
        public String yardiId;
        public String id;
        public String brandName;
        public String propertyName;
        public String propertyDescription;
        public String location;
        public Decimal contractedArea;
        public String status;
        public List<LeaseUnitModel> leaseUnits;
        public List<ContactRolesModel> contactRoles;

        public LeaseModel(Order ord){
            this.id = ord.Id;
            this.yardiId = ord.RETL_Yardi_Id__c;
            this.propertyName = ord.RETL_Property_Name__c;
            this.propertyDescription = ord.RETL_Property_Description__c;
            this.location = ord.RETL_Location__c;
            this.brandName = ord.RETL_Brand__r != null ? ord.RETL_Brand__r.Name : null;
            this.contractedArea = ord.RETL_Contracted_Area__c;
            this.status = ord.RETL_Status__c;
            this.leaseUnits = new List<LeaseUnitModel>();
            if (ord.OrderItems != null ) {
                for (OrderItem item : ord.OrderItems ) {
                    LeaseUnitModel unit = new LeaseUnitModel(item);

                    this.leaseUnits.add(unit);
                }
            }
            this.contactRoles = new List<ContactRolesModel>();
            Map<Id, RETL_Contact_Role__c> contactRoleMap = new Map<Id, RETL_Contact_Role__c>();
            if(ord.Contact_roles__r != null){
                for (RETL_Contact_Role__c contRole : ord.Contact_roles__r ) {
                    ContactRolesModel contactRole = new ContactRolesModel(contRole);
                    this.contactRoles.add(contactRole);
                    contactRoleMap.put(contRole.Id,contRole);
                }
                
            }
            if( accContactRoles.containsKey(ord.AccountId)){
                system.debug('accContactRoles if');
                system.debug('contactRoleOfAccountMap if');
                    for(RETL_Contact_Role__c cr:accContactRoles.get(ord.AccountId) ){
                        if(!contactRoleMap.containsKey(cr.Id) ){
                            ContactRolesModel contactRole = new ContactRolesModel(cr);
                            this.contactRoles.add(contactRole);
                        }
                    }
            }
            system.debug('this.contactRoles'+this.contactRoles);
        }
    }
    
    public class OpportunityModel {
        public String title;
        public String id;
        public String yardiId;
        public String stageName;
        public String amount;
        public String brandName;
        public String propertyName;
        public String propertyCode;
        public Date startDate;
        public Date endDate;
        public String imageURL;
        public String currentPhase;
        public String yardiProposalId;
        public String yardiTenantCode;
        
		public OpportunityModel(Opportunity opp){
            this.brandName = opp.RETL_Brand__r.Name;
            this.yardiId = opp.RETL_Yardi_Id__c;
            this.imageURL = opp.RETL_Project__r.Image_URL__c;
            this.title = opp.RETL_Brand__r?.Name != null?opp.RETL_Brand__r?.Name :'';
            if( this.title != null && opp.RETL_Project__r?.Name != null ){
               	this.title += ', '; 
            }
            this.title +=   opp.RETL_Project__r?.Name != null ? opp.RETL_Project__r?.Name: '';
            this.propertyName = opp.RETL_Project__r?.Name;
            this.propertyCode = opp.RETL_Project__r?.RETL_Property_Yardi_Code__c;
            this.id = opp.Id;
            this.stageName = opp.StageName;
            this.startDate = opp.Start_date__c;
            this.endDate = opp.CloseDate;
            this.currentPhase = opp.RETL_Live_Aldar_Phase__c;
            this.yardiTenantCode = opp.RETL_Tenant_Code__c;
            this.yardiProposalId = opp.RETL_Yardi_Proposal_Id__c;
        }
    }
    /*@description wrapper for capturing data from leaseunits @return  */
    public class LeaseUnitModel{
        public String yardiId;
        public String id;
        public String area;
        public String building;
        public String unit;
        public String unitType;
        public String orderId;
        public Date moveOutDate;
        public Date moveInDate;
        public String location;
        public String floor;
		public String propertyName;
        public LeaseUnitModel(OrderItem item){
            this.id = item.Id;
            this.yardiId = item.RETL_Yardi_Id__c;
            this.area = item.RETL_Area__c != null ? String.valueOf(item.RETL_Area__c) : null;
            this.building = item.RETL_Building__c;
            this.unit = item.RETL_Unit__c;
            this.unitType = item.RETL_UnitType__c;
            this.orderId = item.OrderId;
            this.moveOutDate = item.RETL_MoveOutDate__c;
            this.moveInDate = item.RETL_MoveInDate__c;
            this.location = item.RETL_Location__c;
            this.floor = item.RETL_Floor__c;
            this.propertyName = item.RETL_PropertyName__c;
        }
    }

    public class ContactRolesModel{
        public String firstName;
        public String lastName;
       public String yardiId;
        public String email;
        public String phone;

        public String profileImage;
        public String designation;
		public String sfContactID;


        public ContactRolesModel(RETL_Contact_Role__c conRole){
            this.firstName = conRole.RETL_Contact__r.FirstName;
            this.lastName = conRole.RETL_Contact__r.LastName;
            this.yardiId = conRole.RETL_Yardi_Id__c;
            this.profileImage =conRole.RETL_Contact__r.RETL_Profile_Image__c;
            this.designation = conRole.RETL_Contact_Role__c;
            this.email  = conRole.RETL_Contact__r.Email;
            this.phone = conRole.RETL_Contact__r.MobilePhone;
			this.sfContactID = conRole.RETL_Contact__c;
        }
    }
    /*@description  wrapper for capturing data from documents @return  */
    public class DocumentModel{
        public String id;
        public String yardiId;
        public String documentName;
        public String orderName;
        public String accountName;
        public String documentType;
        public String accountId;
        public String leaseID;
        public DateTime createdUploadedDate;
        public Double documentSize;

        public DocumentModel(Document__c doc){
            this.id =  doc.id;
            this.yardiId = doc.RETL_Yardi_Id__c;
            this.documentName = doc.Other_Document_Name__c;
            this.documentType = doc.DocumentType__c;
            this.accountID = doc.Account__c;
            this.accountName = doc.Account__r.Name != null?doc.Account__r.Name:null;
            this.leaseID = doc.Order__c;
            this.createdUploadedDate = doc.AttachmentUpdatedTime__c;
            this.documentSize = doc.ContentSize__c;
            this.leaseID = doc.Order__c;
            this.orderName = doc.Order__r.Name != null? doc.Order__r.Name:null;
        }
    }
}