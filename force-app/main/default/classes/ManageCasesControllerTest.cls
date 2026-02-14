/*
*Created By     : Hardik Vitthani
*Description    : Test class for CaseCommentsService
*/
@isTest
public class ManageCasesControllerTest {
    
    @testSetup static void setup() {
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        
        User newUser = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'newuseradmin');
        newUser.UserRoleId = portalRole.Id;
        newUser.Email = 'test@aldar.com.invalid';
        insert newUser;
        
        User agencyAdmin = new User();
        System.runAs(newUser) {
            Account oAcc = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
            insert oAcc;
            
            Contact aCon = new Contact();
            aCon.LastName = 'Alice';
            aCon.FirstName = 'Alice';
            aCon.Email='aupendra14@gmail.com';
            aCon.AccountId = oAcc.Id;
            aCon.BrokerType__c = Constants.AGENCY_ADMIN;
            insert aCon;
            
             Case cs = TestObjectsFactory.getCase(oAcc.Id, aCon.Id, 'Compliance');
            insert cs;
            
            Case newCase = new Case();
        newCase.RecordTypeId = Schema.getGlobalDescribe()
            .get('Case')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerCase')
            .getRecordTypeId();
        newCase.Subject = 'Test Subject';
        newCase.Description = 'Test Description';
        newCase.Status = 'New';
        newCase.Origin='Broker Portal';
        newCase.AccountId = oAcc.Id;
        newCase.ContactId = aCon.Id;
        newCase.Category__c = 'Compliance';
        insert newCase;
            
            TestObjectsFactory.createContentDocumentLink(newCase.Id);
            
            agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'agencyAdmin');
            agencyAdmin.ContactId = aCon.Id;
            agencyAdmin.Email = 'test.portal@aldar.com.saran';
            insert agencyAdmin;
        }
    }

    
    @isTest
    static void testGetAccountIdWithUnitIdOnly() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Project__c proj = new Project__c(Name='Gate', ProjectCode__c='test', BusinessUnitId__c='test');
        insert proj;
        
        BuildingSection__c build = new BuildingSection__c(Name='ABC', BuildingSectionCode__c = 'test', Project__c=proj.Id);
		insert build;
        // Create test Unit
        Unit__c unit = new Unit__c(Name = 'Test Unit', BuildingSectionName__c=build.Id, Project__c=proj.Id, UnitType__c='Villa');
        insert unit;

        // Create test Sales Order
        SalesOrder__c so = new SalesOrder__c(Unit__c = unit.Id, Account__c = acc.Id, Status__c = 'Sold');
        insert so;

        // Create test Contact
        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;

        // Call method
        Test.startTest();
        ManageCasesController.wrapdata result = ManageCasesController.getAccountid(unit.Id, null);
        Test.stopTest();
    }
    
    @isTest
    static void testHasSalesOrdersForCaseAccount2(){
        Case newCase2 = new Case();
        newCase2.RecordTypeId = Schema.getGlobalDescribe()
            .get('Case')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Requests')
            .getRecordTypeId();
        newCase2.Subject = 'Test Subject';
        newCase2.Description = 'Test Description';
        newCase2.Status = 'New';
        newCase2.Origin='Phone';
        //newCase.AccountId = oAcc.Id;
        //newCase2.ContactId = aCon.Id;
        newCase2.Category__c = 'Compliance';
        insert newCase2;
        
        try{
            Test.startTest();
            ManageCasesController.hasSalesOrdersForCaseAccount(newCase2.Id);
            Test.stopTest();
        }catch(Exception ex){
            
        }
        
    }
    
    @isTest
     static void testHasSalesOrdersForCaseAccount(){
        Account oAcc = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
            insert oAcc;
            
            Contact aCon = new Contact();
            aCon.LastName = 'Alice';
            aCon.FirstName = 'Alice';
            aCon.Email='aupendra14@gmail.com';
            aCon.AccountId = oAcc.Id;
            //aCon.BrokerType__c = Constants.AGENCY_ADMIN;
            insert aCon;
            
             Case cs = TestObjectsFactory.getCase(oAcc.Id, aCon.Id, '');
            insert cs;
            
            Case newCase = new Case();
        newCase.RecordTypeId = Schema.getGlobalDescribe()
            .get('Case')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Requests')
            .getRecordTypeId();
        newCase.Subject = 'Test Subject';
        newCase.Description = 'Test Description';
        newCase.Status = 'New';
        newCase.Origin='Phone';
        newCase.AccountId = oAcc.Id;
        newCase.ContactId = aCon.Id;
        newCase.Category__c = 'Compliance';
        insert newCase;
        
        try{
            Test.startTest();
            ManageCasesController.hasSalesOrdersForCaseAccount(newCase.Id);
            
            Test.stopTest();
        }catch(Exception ex){
            
        }
    }
    
    @isTest
    public static void testReturnFiles() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;

        Case cs = TestObjectsFactory.getCase(acc.Id, con.Id, 'Compliance');
        cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('District Management').getRecordTypeId();
        insert cs;

        TestObjectsFactory.createContentDocumentLink(cs.Id);
        ContentVersion cv = [SELECT Id FROM contentversion LIMIT 1];

        try {
            ManageCasesController.returnFiles(new List<String>{cv.Id});
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testSaveFiles() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;

        Case cs = TestObjectsFactory.getCase(acc.Id, con.Id, 'Compliance');
        cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('District Management').getRecordTypeId();
        Map<String, String> filesToInsert = new Map<String, String>();
        filesToInsert.put('Title', 'Title');
        filesToInsert.put('VersionData', 'VersionData');

        try {
            ManageCasesController.saveFiles(new List<Object>{filesToInsert}, cs, 'Test',acc.Id, con.Id);
           
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    
    @isTest
    public static void testDisplayCaseRecords() {
        Test.startTest();
        User agencyAdmin = [SELECT Id FROM User WHERE Email='test.portal@aldar.com.saran'];
       
        try {
            System.runAs(agencyAdmin) {
                ManageCasesController.displayCaseRecords(null, '');
            }
        } catch (Exception ex) {
           System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    /*@isTest
    public static void testDisplayCaseRecordsWithPrentAccount() {
        Test.startTest();

        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

        User newUser = TestObjectsFactory.getUserRecord('Broker Sales Admin', 'newuseradmin');
        newUser.UserRoleId = portalRole.Id;
        newUser.Email = 'test@aldar.com.invalid';
        insert newUser;

        User agencyAdmin = new User();
        System.runAs(newUser) {
            Account acc = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
            insert acc;

            Contact con = new Contact();
            con.LastName = 'Alice';
            con.FirstName = 'Alice';
            con.AccountId = acc.Id;
            insert con;

            Case cs = TestObjectsFactory.getCase(acc.Id, con.Id, 'Compliance');
            cs.Status = 'In Progress';
            cs.OwnerId = newUser.Id;
            cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('District Management').getRecordTypeId();
            insert cs;

            Account oAcc = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
            oAcc.ParentId = acc.Id;
            insert oAcc;

            Contact aCon = new Contact();
            aCon.LastName = 'Alice';
            aCon.FirstName = 'Alice';
            aCon.AccountId = oAcc.Id;
            aCon.BrokerType__c = Constants.AGENCY_ADMIN;
            insert aCon;

            Case aCs = TestObjectsFactory.getCase(oAcc.Id, aCon.Id, 'Compliance');
            aCs.OwnerId = newUser.Id;
            aCs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('District Management').getRecordTypeId();
            insert aCs;

            TestObjectsFactory.createContentDocumentLink(cs.Id);

            agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'agencyAdmin');
            agencyAdmin.ContactId = aCon.Id;
            agencyAdmin.Email = 'test.portal@aldar.com.invalid';
            insert agencyAdmin;
       }

        try {
            System.runAs(agencyAdmin) {
                ManageCasesController.displayCaseRecords(null, '');
            }
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }*/
    
    @isTest
    public static void testGetRelatedFilesByCaseId() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;

        Case cs = TestObjectsFactory.getCase(acc.Id, con.Id, 'Compliance');
        cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('District Management').getRecordTypeId();
        insert cs;

        TestObjectsFactory.createContentDocumentLink(cs.Id);

        try {
            ManageCasesController.getRelatedFilesByCaseId(cs.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testCreateFiles() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        Contact con = new Contact();
        con.Lastname = 'Alice';
        con.AccountId = acc.Id;
        con.BrokerType__c = Constants.AGENCY_ADMIN;
        insert con;
        
		/*
        Case cs = TestObjectsFactory.getCase(acc.Id, con.Id, 'Compliance');
        insert cs;*/

        Map<String, String> filesToInsert = new Map<String, String>();
        filesToInsert.put('Title', 'Title');
        filesToInsert.put('VersionData', 'VersionData');

        try {
            ManageCasesController.createFiles(new List<Object>{filesToInsert},null);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }

    @isTest
    public static void testGetURLPath() {
        Test.startTest();

        try {
            ManageCasesController.getURLPath();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
     @isTest
    public static void testSalesRecord() {
        Test.startTest();        
        Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
        insert newAccount;
        Opportunity newOpportunity = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        newOpportunity.SaleType__c = 'New Sale';
        insert newOpportunity;
        //Contact con = new Contact();
        //con.Lastname = 'Alice';
      //  con.AccountId = newAccount.Id;
        //con.BrokerType__c = Constants.AGENCY_ADMIN;
      //  insert con;
        
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('Aldar');
		insert newUnit;
   		
        
       SalesOrder__c newSalesOrder = TestObjectsFactory.getSalesOrderRecord(newOpportunity.Id,newAccount.Id);
        newSalesOrder.Unit__c = newUnit.Id;
        Insert newSalesOrder;
       
		ManageCasesController.getAccountid(newUnit.Id,Null);
        ManageCasesController.getAccountid(Null,newAccount.Id);
       
        Test.stopTest();
    }
    
     @isTest
    public static void testSalesRecord2() {
        Test.startTest();        
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('V1', 'P1');
        insert newAccount;
        Opportunity newOpportunity = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        insert newOpportunity;
       
        Unit__c newUnit = TestObjectsFactory.unitDataSetup('Aldar');
		insert newUnit;
   		
        
       SalesOrder__c newSalesOrder = TestObjectsFactory.getSalesOrderRecord(newOpportunity.Id,newAccount.Id);
        newSalesOrder.Unit__c = newUnit.Id;
        Insert newSalesOrder;
       
		ManageCasesController.getAccountid(newUnit.Id,Null);
        ManageCasesController.getAccountid(Null,newAccount.Id);
       
        Test.stopTest();
    }
    
    @isTest
    static void testSaveFilesMethod() {
        // Create an Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a Contact associated with the Account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
		
        User agencyAdmin = [SELECT Id FROM User WHERE Email='test.portal@aldar.com.saran'];
        
        
        
        // Run as the created user
        System.runAs(agencyAdmin) {
            // Mock file data
            Map<String, String> filesToInsert = new Map<String, String>();
            filesToInsert.put('Title', 'Title');
            filesToInsert.put('VersionData', 'VersionData');

            // Prepare Case object
            Case tempCase = new Case(Subject = 'Test Case');

            // Call the method under test
            Test.startTest();
            List<Id> result = ManageCasesController.saveFiles(
                new List<Object>{filesToInsert},
                tempCase,
                'Test Comment',
                testAccount.Id,
                testContact.Id
            );
            Test.stopTest();
        }
    }
}