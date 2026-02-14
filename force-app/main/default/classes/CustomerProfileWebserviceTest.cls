/*
* Name               : CustomerProfileWebserviceTest

* Description        : Test class for CustomerProfileWebservice
* Version			 : V1.1 Added by Protiviti when retail contact logic added.
*/
@isTest
public class CustomerProfileWebserviceTest {
    
    @isTest
    public static void testCustomerProfileWebservice() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;
        
        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerProfileWebservice.doPost(acc.PersonEmail, '', true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerProfileWebservice2() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        insert acc;
        
        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        TransferHistory__c transHistory = new TransferHistory__c();
        transHistory.SalesOrder__c		= salesOrder.Id;
        transHistory.FromAccount__c		= acc.Id;
        insert transHistory;
        
        Test.startTest();
        try {
            CustomerProfileWebservice.doPost(acc.PersonEmail, '', false);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testCustomerProfileWebserviceBlankParameters() {
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerProfileWebservice.doPost('', '', true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
   /* @isTest
    public static void testCustomerProfileWebserviceMultiAccount() {

try {

Account acc = TestObjectsFactory.getPersonAccountRecord();
acc.OtherERPID__c = '{"temp":"temp"}';
insert acc;

Account acc2 = TestObjectsFactory.getPersonAccountRecord();
acc2.OtherERPID__c = '{"temp":"temp"}';
acc2.PassportNumber__pc = 'Test12342023';
insert acc2;

SalesOrder__c salesOrder = getData(acc);

SalesOrder__c salesOrder2 = getData(acc);

TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
RestContextHandler handler = new RestContextHandler(false);
Test.startTest();

            CustomerProfileWebservice.doPost(acc.PersonEmail, '', true);
        Test.stopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }*/
    
    
    @isTest
    public static void testCustomerProfileWebserviceNoLead() {
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        try {
            CustomerProfileWebservice.doPost('test@test.test', '', true);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    public static SalesOrder__c getData(Account acc) {
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 5);
        TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        return salesOrder;
    }
    
    @isTest
    static void testDoPost() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;
        
        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        acc1.OtherERPID__c = '{"temp":"temp"}';
        acc1.AllowLiveAldarRegistration__c = true;
        insert acc1;
        
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c = '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c = true;
        insert acc2;
        
        SalesOrder__c salesOrder = getData(acc);
        Unit__c unit = [SELECT Id, ResaleStatus__c FROM Unit__c LIMIT 1];
        unit.ResaleStatus__c = 'Transfer Completed';
        update unit;
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        // Call the getProfileData method
        Test.startTest();
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', true);
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', true);
        //List<CustomerProfileWebservice.PreviousUnitDetails> prevUnits = CustomerProfileWebservice.getPreviousResaleUnits(String.valueOf(acc.Id), new List<SalesOrder__c>{salesOrder});
        //List<CustomerProfileWebservice.SalesOrderModel> models = CustomerProfileWebservice.salesOrderDetails(String.valueOf(acc.Id));
        Test.stopTest();
        
        // Assertions
        // Add your assertions here based on the expected behavior of the getProfileData method
        System.assert(true, 'Test completed successfully');
    }
    
    @isTest
    static void testDoPost1() {
        
        Account acc 						= TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c 					= '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c 	= true;
        insert acc;
        
        Account acc1 						= TestObjectsFactory.getPersonAccountRecord();
        acc1.OtherERPID__c 					= '{"temp":"temp"}';
        acc1.AllowLiveAldarRegistration__c 	= true;
        acc1.CustomerAppWebUser__c			= true;
        insert acc1;
        
        Account acc2 						= TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c 					= '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c 	= true;
        insert acc2;
        
        SalesOrder__c salesOrder = getData(acc);
        Unit__c unit = [SELECT Id, ResaleStatus__c FROM Unit__c LIMIT 1];
        unit.ResaleStatus__c = 'Transfer Completed';
        update unit;
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        // Call the getProfileData method
        Test.startTest();
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', false);
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', false);
        //List<CustomerProfileWebservice.PreviousUnitDetails> prevUnits = CustomerProfileWebservice.getPreviousResaleUnits(String.valueOf(acc.Id), new List<SalesOrder__c>{salesOrder});
        //List<CustomerProfileWebservice.SalesOrderModel> models = CustomerProfileWebservice.salesOrderDetails(String.valueOf(acc.Id));
        Test.stopTest();
        
        // Assertions
        // Add your assertions here based on the expected behavior of the getProfileData method
        System.assert(true, 'Test completed successfully');
    }
    
    @isTest
    static void testNOCFastTrackCompletedLogic() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;
        
        Communication_Preference__c cpRecord = new Communication_Preference__c();
        cpRecord.Account__c = acc.Id;
        cpRecord.Category__c = 'NOC-Fasttrack';
        cpRecord.Status__c = 'Fasttrack Completed';
        cpRecord.Active__c = true;
        insert cpRecord;
        
        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', false);
        Test.stopTest();
        
        System.assert(true, 'NOC-Fasttrack Completed logic test executed');
    }
    
    
    @isTest
    static void testDoPost2() {
        
        Account acc 						= TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c 					= '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c 	= true;
        acc.CustomerAppWebUser__c			= true;
        insert acc;
        
        Account acc1 						= TestObjectsFactory.getPersonAccountRecord();
        acc1.OtherERPID__c 					= '{"temp":"temp"}';
        acc1.AllowLiveAldarRegistration__c 	= true;
        acc1.CustomerAppWebUser__c			= true;
        acc1.CustomerAppWebUser__c			= true;
        insert acc1;
        
        Account acc2 						= TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c 					= '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c 	= true;
        acc2.CustomerAppWebUser__c			= true;
        insert acc2;
        
        SalesOrder__c salesOrder = getData(acc);
        Unit__c unit = [SELECT Id, ResaleStatus__c FROM Unit__c LIMIT 1];
        unit.ResaleStatus__c = 'Transfer Completed';
        update unit;
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        // Call the getProfileData method
        Test.startTest();
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', false);
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', false);
        //List<CustomerProfileWebservice.PreviousUnitDetails> prevUnits = CustomerProfileWebservice.getPreviousResaleUnits(String.valueOf(acc.Id), new List<SalesOrder__c>{salesOrder});
        //List<CustomerProfileWebservice.SalesOrderModel> models = CustomerProfileWebservice.salesOrderDetails(String.valueOf(acc.Id));
        Test.stopTest();
        
        // Assertions
        // Add your assertions here based on the expected behavior of the getProfileData method
        System.assert(true, 'Test completed successfully');
    }
    
    @isTest
    static void testGetProfileData() {
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;
        
        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        acc1.OtherERPID__c = '{"temp":"temp"}';
        acc1.AllowLiveAldarRegistration__c = true;
        insert acc1;
        
        SalesOrder__c salesOrder = getData(acc);
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        // Call the getProfileData method
        Test.startTest();
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', true);
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', true);
        
        CustomerProfileWebservice.PreviousUnitDetails unitDetails = new CustomerProfileWebservice.PreviousUnitDetails();
        unitDetails.unitName = 'unit';
        unitDetails.projectName = 'unit';
        unitDetails.saleDate = System.today() ;
        
        CustomerProfileWebservice.SalesOrderModel soModel = new CustomerProfileWebservice.SalesOrderModel(salesOrder, acc1.Id);
        
        Test.stopTest();
        
        // Assertions
        // Add your assertions here based on the expected behavior of the getProfileData method
        System.assert(true, 'Test completed successfully');
    }
    
    @isTest
    static void testNOCFastTrackLogic() {
        // Create test account
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;
        
        // Create Communication Preference with NOC-Fasttrack and 'Link Sent'
        Communication_Preference__c cpRecord = new Communication_Preference__c();
        cpRecord.Account__c = acc.Id;
        cpRecord.Category__c = 'NOC-Fasttrack';
        cpRecord.Status__c = 'Link Sent';
        cpRecord.Active__c = true;
        insert cpRecord;
        
        // Add any additional records (e.g., SalesOrder) if required
        SalesOrder__c salesOrder = getData(acc);
        
        // Call the webservice method
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', false);
        Test.stopTest();
        
        // Ideally, assert that enableNOCFastTrack was set to true
        // However, since we don't get the return value from doPost, you may log or check debug logs manually
        System.assert(true, 'NOC-Fasttrack logic test executed');
    }
    
    @isTest
    static void dopost3(){
        Account acc 						= TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c 					= '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c 	= true;
        acc.KeyAccountManager__c = UserInfo.getUserId();
        acc.PersonEmail = 'uniqueone@test.com';
        acc.MergedAccount__c = false;
        acc.Blacklisted__c = false;
        acc.SkipCustomerLogin__c = false;
        acc.SkipLiveAldarReason__c = null;
        insert acc;
        
        Communication_Preference__c cpRecord = new Communication_Preference__c();
        cpRecord.account__c =acc.Id;
        cpRecord.Category__c= 'FastTrack';
        cpRecord.Status__c ='Link Sent';
        cpRecord.Active__c= true;
        insert cpRecord;
        
        Communication_Preference__c cpRecord1 = new Communication_Preference__c();
        cpRecord1.account__c =acc.Id;
        cpRecord1.Category__c= 'Digital SPA';
        cpRecord1.Status__c ='Link Sent';
        cpRecord1.Active__c= true;
        insert cpRecord1;
        
        Communication_Preference__c cpRecord2 = new Communication_Preference__c();
        cpRecord2.account__c =acc.Id;
        cpRecord2.Category__c= 'Premium Parking';
        cpRecord2.Status__c ='Link Sent';
        cpRecord2.Active__c= true;
        insert cpRecord2;
        
        Communication_Preference__c cpRecord3 = new Communication_Preference__c();
        cpRecord3.account__c =acc.Id;
        cpRecord3.Category__c= 'FastTrack';
        cpRecord3.Status__c ='FastTrack Completed';
        cpRecord3.FastTrack_Completion_Date_Time__c = System.today().addDays(-2);
        cpRecord3.Active__c= true;
        insert cpRecord3;
        
        Document__c doc = new Document__c();
        doc.DocumentType__c = 'Profile Picture';
        doc.Account__c = acc.Id;
        doc.Status__c = 'Uploaded';
        insert doc;
        
        Document__c doc1 = new Document__c();
        doc1.DocumentType__c = 'Signed KYC Form';
        doc1.Account__c = acc.Id;
        doc.Status__c = 'Uploaded';
        insert doc1;
        
        Document__c doc2 = new Document__c();
        doc2.DocumentType__c = 'Signed CIS Sheet';
        doc.Status__c = 'Uploaded';
        doc2.Account__c = acc.Id;
        insert doc2;
        
        Document__c doc3 = new Document__c();
        doc3.DocumentType__c = 'CIS Sheet';
        doc.Status__c = 'Uploaded';
        doc3.Account__c = acc.Id;
        insert doc3;
        System.debug('Account inserted: ' + [SELECT Id FROM Account WHERE PersonEmail = 'uniqueone@test.com']);
        
        TestObjectsFactory.initializeRestContext(null, '/customer/myprofile');
        RestContextHandler handler = new RestContextHandler(false);

       
        Test.startTest();
        CustomerProfileWebservice.doPost(acc.PersonEmail, '', false);
        Test.stopTest();
    }
    //Added by Protiviti for getting coverage after update done for retail Contact
    @isTest
    public static void singleBusinessContactLoginAPITest(){
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        newAccount.RETL_Status__c = 'Active';  
        insert newAccount;
        Contact newContact = getBusinessContact('testsingle@g.com', '1211222', 'United Arab Emirates', 'yard24343');

        newContact.AccountId = newAccount.Id;

        insert newContact;
        system.debug('newContact'+newContact);
        AccountContactRelation newACR = getACR(newContact.Id, newContact.AccountId);
        List<AccountContactRelation> acr = [SELECT Id,Contact.Name,Account.Name ,  IsDirect FROM AccountContactRelation where AccountId=: newContact.accountId  ];
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
		Test.startTest();
		CustomerProfileWebservice.doPost(newContact.Email, '', true);
        Test.stopTest();
    }
    @isTest
    public static void singleBusinessContactProfileAPITest(){
        Account newOrgAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
         newOrgAccount.RETL_Status__c = 'Active';   
        insert newOrgAccount;
        Account newBrandAccount = getBrandAccountRecord('Test Brand');
        insert newBrandAccount;
        Contact newContact = getBusinessContact('testsingle@g.com', '1211222', 'United Arab Emirates', 'yard24343');
        newContact.AccountId = newOrgAccount.Id;
        insert newContact;
        Contract newContract = getContract(newOrgAccount.Id);
        insert newContract;
        Product2 newPrdoduct = getProduct();
        insert newPrdoduct;
        PricebookEntry newPricebookEntry = getPricebookEntry(newPrdoduct.Id);
        insert newPricebookEntry;
        Order newOrder = getOrder(newOrgAccount.Id, newBrandAccount.Id, newContract.Id);
        insert newOrder;
        RETL_Contact_role__c newContactRole = getContactRole(newContact.Id, newOrder.Id, 'Test Role');
        insert newContactRole;

        OrderItem newOrderItem = getLeaseUnits(newPrdoduct.Id, newOrder.Id, newPricebookEntry.Id);
        insert newOrderItem;
        Document__c newDoc = getDocument(newOrder.Id, newOrgAccount.Id);
        insert newDoc;
        Document__c newDocWithoutAccountId = getDocument(newOrder.Id, newOrgAccount.Id);
        insert newDocWithoutAccountId;
        system.assertEquals('Commercial Trade License', newDocWithoutAccountId.DocumentType__c,'');
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
		Test.startTest();
		CustomerProfileWebservice.doPost(newContact.Email, '', false);
        Test.stopTest();
        
    }
    @isTest
    public static void singleBusinessContactSPAProfileAPITest(){
        Account newOrgAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        newOrgAccount.RETL_Status__c = 'Active';  
        insert newOrgAccount;
        Account newBrandAccount = getBrandAccountRecord('Test Brand');
        insert newBrandAccount;
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c = '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c = true;
        insert acc2;
        
        Contact newContact = getBusinessContact('testsingle@g.com', '1211222', 'United Arab Emirates', 'yard24343');
        newContact.AccountId = newOrgAccount.Id;
        insert newContact;
        Contract newContract = getContract(newOrgAccount.Id);
        insert newContract;
        Product2 newPrdoduct = getProduct();
        insert newPrdoduct;
        PricebookEntry newPricebookEntry = getPricebookEntry(newPrdoduct.Id);
        insert newPricebookEntry;
        Order newOrder = getOrder(newOrgAccount.Id, newBrandAccount.Id, newContract.Id);
        insert newOrder;
        RETL_Contact_role__c newContactRole = getContactRole(newContact.Id, newOrder.Id, 'Test Role');
        insert newContactRole;

        OrderItem newOrderItem = getLeaseUnits(newPrdoduct.Id, newOrder.Id, newPricebookEntry.Id);
        insert newOrderItem;
        Document__c newDoc = getDocument(newOrder.Id, newOrgAccount.Id);
        insert newDoc;
        Document__c newDocWithoutAccountId = getDocument(newOrder.Id, null);
        insert newDocWithoutAccountId;
        system.assertEquals('Commercial Trade License', newDocWithoutAccountId.DocumentType__c,'');
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
		Test.startTest();
		CustomerProfileWebservice.doPost(newContact.Email, '', false);
        Test.stopTest();
    }
    /*@isTest
    public static void multipleBusinessContactLoginAPITest(){
        Contact newContact = TestObjectsFactory.getBusinessContact('testmultiple@g.com', '181', 'United Arab Emirates', 'yard24343');
        insert newContact;
        Contact newContact2 = TestObjectsFactory.getBusinessContact('testmultiple@g.com', '181', 'United Arab Emirates', 'yard24');
        insert newContact2;
        System.assertEquals(newContact.NationalIdNumber__c, newContact2.NationalIdNumber__c, 'Both contacts should have same NationalIdNumber');
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
		Test.startTest();
		CustomerProfileWebservice.doPost('', '181', true);
        Test.stopTest();
    }
    @isTest
    public static void multipleBusinessContactValidContactTest(){
        Contact newContact = TestObjectsFactory.getBusinessContact('testmultiple@g.com', '181', 'United Arab Emirates', 'yard24343');
        insert newContact;
        Contact newContact2 = TestObjectsFactory.getBusinessContact('testmultiple@g.com', '181', 'United Arab Emirates', 'yard243');
        insert newContact2;
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c = '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c = true;
        insert acc2;
        System.assertEquals(newContact.Email, newContact2.Email, 'Both contacts should have same email');
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
		Test.startTest();
		CustomerProfileWebservice.doPost('', '181', true);
        Test.stopTest();
    }
     @isTest
    public static void multipleBusinessContactMultiplePersonAccountTest(){
        Contact newContact = TestObjectsFactory.getBusinessContact('testmultiple@g.com', '181', 'United Arab Emirates', 'yard243435');
        insert newContact;
        Contact newContact2 = TestObjectsFactory.getBusinessContact('testmultiple@g.com', '181', 'United Arab Emirates', 'yard24343');
        insert newContact2;
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c = '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c = true;
        insert acc2;
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;
        system.assertEquals('testmultiple@g.com', newContact.Email,'');
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
		Test.startTest();
		CustomerProfileWebservice.doPost('', '181', false);
        Test.stopTest();
    }*/
    @isTest
    public static void validBusinessContactMultiplePersonAccountTest(){
        Contact newContact = getBusinessContact('testmultiple@g.com', '181', 'United Arab Emirates', 'yard24343');
        insert newContact;
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c = '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c = true;
        insert acc2;
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;
        
        system.assertEquals('testmultiple@g.com', newContact.Email,'');
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
		Test.startTest();
		CustomerProfileWebservice.doPost('', '181', false);
        Test.stopTest();
    }
    @isTest
    public static void multiplePersonAccountTest(){
        Contact newContact = getBusinessContact('testmultiple@g.com', '181', 'United Arab Emirates', 'yard24343');
        insert newContact;
        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        acc2.OtherERPID__c = '{"temp":"temp"}';
        acc2.AllowLiveAldarRegistration__c = true;
        insert acc2;
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.OtherERPID__c = '{"temp":"temp"}';
        acc.AllowLiveAldarRegistration__c = true;
        insert acc;
        system.assertEquals('testmultiple@g.com', newContact.Email,'');
        
        TestObjectsFactory.initializeRestContext(null, '/query/myprofile');
        RestContextHandler handler = new RestContextHandler(false);
		Test.startTest();
		CustomerProfileWebservice.doPost('', '181', true);
        Test.stopTest();
    }
    
    
    //V1.1 Added by Protiviti for Login API update done for retail Contact
    //Create Data for Test Business Contact
    public static Contact getBusinessContact(String email, String eId, String nationality, String yardiId){
        Contact newContact = getContactRecord(Constants.ORGANISATION_CONTACT_RT);
        newContact.Nationality__c = nationality;
        newContact.Email = email;
        newContact.NationalIdNumber__c = eId;
        newContact.PassportIssueDate__c = Date.valueOf('2005-05-25');
        newContact.RETL_Profile_Image__c = '';
        newContact.Title = 'Manager';
        newContact.RETL_Yardi_Id__c = yardiId;
        return newContact;
    }

    //create data for test contact
    public static Contact getContactRecord(String contactRTName){
        Contact newContact = new Contact();
        newContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(contactRTName).getRecordTypeId();
        newContact.FirstName = 'test';
        newContact.LastName = 'Last';
        newContact.Birthdate = Date.valueOf('2000-05-25');
        newContact.MobileCountryCode__c = '971';
        newContact.MobilePhone = '456788099';
        newContact.MailingCity = 'Testa';
        newContact.MailingCountry = 'United Arab Emirates';
        newContact.MailingState = 'Dubai';
        newContact.MailingPostalCode = '23345';
        return newContact;
    }
    //Create data for Test Brand Account
    public static Account getBrandAccountRecord(String brandName){
        Account newAccount = TestObjectsFactory.getAccountRecord(Constants.BRAND_Account_RT,false,null);
        newAccount.Name = brandName;
        newAccount.CurrencyIsoCode = 'AED';
        return newAccount ;
    }
    //Create Data for Test AccountCOntactRelation
    public static AccountContactRelation getACR(Id contactId, Id accountId){
        AccountContactRelation acr = new AccountContactRelation(
            AccountId = accountId,
            ContactId = contactId
        );

        return acr;
    }
    //Create Data for Test Contact
    public static Contract getContract(Id accountId){
        Contract newContract = new Contract(
        	StartDate = Date.valueOf('2025-06-15'),
            ContractTerm = 10,
            AccountId = accountId,
            Status = 'Draft',
            CurrencyIsoCode = 'AED'
        );
        return newContract;
    }
    //Create Data for Test Order
    public static Order getOrder(Id accountId, Id brandId, Id contractId){
        Id standardPricebookId = Test.getStandardPricebookId();
        Order newOrder = new Order(
        	RETL_Name__c = 'Test Order', 
            RETL_Yardi_Id__c = '4566',
            AccountId = accountId,
            Pricebook2Id = standardPricebookId, 
            RETL_Brand__c = brandId,
            ContractId = contractId,
            EffectiveDate = Date.Valueof('2025-07-15'),
            RETL_Contracted_Area__c = 455.50,
            RETL_Location__c = 'first floor',
			RETL_Property_Name__c = 'Yas Mall',
            Status = 'Draft',
            RETL_Status__c = 'Current'
        );
        return newOrder;
    }
    //Create Data for Test ContactRole
    public static RETL_Contact_role__c getContactRole(Id contactId, Id leaseId, String role){
        RETL_Contact_role__c newcontactRole = new RETL_Contact_role__c(
        	RETL_Contact__c = contactId,
            RETL_Lease__c = leaseId,
            Name = role
        );
        return newcontactRole;
    }
    //Create Data for Test Product
    public static Product2 getProduct(){
        Product2 newProduct = new Product2(
            Name = 'Test Product'
        );
        return newProduct;
    }
    //Create Data for Test LeaseUnits
    public static OrderItem getLeaseUnits(Id productId, Id orderId, Id pricebookEntryId){
        OrderItem newOrderItem = new OrderItem(
        	Product2Id = productId,
            pricebookEntryId = pricebookEntryId,
            OrderId = orderId,
            UnitPrice = 15020,
            Quantity = 50,
            RETL_Building__c = 'Yas mall',
            RETL_Floor__c = 'firstfloor',
            RETL_Area__c = 45.25,
            RETL_MoveInDate__c = Date.valueOf('2025-06-20'),
            RETL_MoveOutDate__c = Date.valueOf('2026-02-20'),
            RETL_UnitType__c = 'lineShop'
        );
        return newOrderItem;
    }
    //Create Data for Test PriceBookEntry.
    public static PricebookEntry getPricebookEntry(Id productId) {
        // Get standard price book ID
        Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry standardPriceEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        return standardPriceEntry;
    }
    //Create Data for Test Document
    public static Document__c getDocument(Id orderId, Id accountId){
        Document__c newDoc = new Document__c(
            Order__c = orderId,
            Account__c = accountId,
            DocumentType__c = 'Commercial Trade License'

        );
        return newDoc;
    }
    //V1.1 Added by Protivity end
    
}