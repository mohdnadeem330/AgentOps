@IsTest
public class ManageRequestControllerTest
{
    @TestSetup
    public static void testDataSetup()
    {
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        
        Contact con = new Contact();
        con.Lastname='Alice';
        con.AccountId = accountRecord.Id;
        con.Email = 'test13@aldar.com';  
        con.phone = '527583669';  
        con.MobilePhone = '527583669';
        insert con;
        
        con.FirstName = 'Test';
        con.LastName = 'User';
        update con;
        
        User agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'agencyAdmin');
        agencyAdmin.ContactId = con.Id;
        agencyAdmin.Email = 'ali.athamnehtest@pwc.com';
        insert agencyAdmin;
    }
    
    //createHomeFinanceCase
    //
    @isTest
    public static void testHomeFinanceCase() {
      Case caseRecord = new Case();
      caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();
      caseRecord.CaseCategory__c = 'Home Finance';
      caseRecord.CaseComments__c = 'Home Finance Parent Case';
      //caseRecord.Home_Finance_Facilitator__c = 'Huspy';
      caseRecord.Status = 'New';
      caseRecord.SubVertical__c = 'Home Finance';
      //caseRecord.Sum_of_Total_Commission_for_Aldar__c = 10000;
      //insert caseRecord;
      //ManageRequestController.createHomeFinanceCase(caseRecord);
    }
    @isTest
    public static void testGetAgencyWithClassif() {
        Test.startTest();
        User agencyAdmin = [SELECT Id,Email,ContactId,AccountId FROM USER WHERE Email = 'ali.athamnehtest@pwc.com' LIMIT 1];
        System.runAs(agencyAdmin) {
            ManageRequestController.getAgencyName();
            ManageRequestController.getAgencyDetailsWithClassification();
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testMonthlyLimit() {
        Test.startTest();

        BrokerClassification__c brokerClassification = TestObjectsFactory.getBrokerClassificationRecord();
        brokerClassification.Year__c = String.valueOf(System.Today().year());
        insert brokerClassification;
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        acc.BrokerClassification__c = brokerClassification.Id;
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        try {
            ManageRequestController.monthlyLimit(acc.Id, Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID);
            ManageRequestController.quarterlyLimit(acc.Id, Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID, Date.today());
            ManageRequestController.quarterlyLimitNew(acc.Id, Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID, Date.today(), 1, 2024);
            ManageRequestController.getBufferDaysBrokerClassification(acc.Id);
            ManageRequestController.checkForExistingRequestForQuarter(acc.Id, Date.today());
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testUpdateBrokerRecords() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        brokerRequest.Comments__c = 'Test';

        try {
            ManageRequestController.updateBrokerRecords(brokerRequest);
            ManageRequestController.updateStatus(brokerRequest.Id, 'Pending Invoice Verification', 'comments');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testCreateMarketingRequest() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);

        Map<String, String> filesToInsert = new Map<String, String>();
        filesToInsert.put('Title', 'Title');
        filesToInsert.put('VersionData', 'VersionData');

        try {
            ManageRequestController.createMarketingRequest(new List<Object>{filesToInsert}, brokerRequest);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testCreateEventRequest() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        brokerRequest.RecordTypeId = Schema.getGlobalDescribe().get('BrokerRequest__c').getDescribe().getRecordTypeInfosByDeveloperName().get('EventRequest').getRecordTypeId();

        try {
            ManageRequestController.createEventRequest(brokerRequest);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }

    @isTest
    public static void testDisplayBrokerRequestRecord() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        try {
            ManageRequestController.displayBrokerRequestRecord(Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID);
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

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        Map<String, String> filesToInsert = new Map<String, String>();
        filesToInsert.put('Title', 'Title');
        filesToInsert.put('VersionData', 'VersionData');

        try {
            ManageRequestController.createFiles(new List<Object>{filesToInsert}, brokerRequest.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testGetRelatedFilesByCaseId() {
        Test.startTest();

        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        TestObjectsFactory.createContentDocumentLink(brokerRequest.Id);

        try {
            ManageRequestController.getRelatedFilesByCaseId(brokerRequest.Id);
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }

    @isTest
    public static void testGetURLPath() {
        Test.startTest();

        try {
            ManageRequestController.getURLPath();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }

    @isTest
    public static void testBrokerRequestRecords() {
        Test.startTest();

        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

        User newUser = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'newuseradmin');
        newUser.UserRoleId = portalRole.Id;
        newUser.Email = 'test@aldar.com.invalid';
        insert newUser;

        User agencyAdmin = new User();
        Account oAcc = new Account();
        System.runAs(newUser) {
            oAcc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
            oAcc.PreviousAgencyStatus__c = 'In Active';
            oAcc.AgencyStatus__c = 'Active';
            oAcc.OtherERPID__c = '{"temp":"temp"}';
            insert oAcc;

            Contact aCon = new Contact();
            aCon.LastName = 'Alice';
            aCon.FirstName = 'Alice';
            aCon.AccountId = oAcc.Id;
            aCon.BrokerType__c = Constants.AGENCY_ADMIN;
            insert aCon;

            agencyAdmin = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN_PROFILE, 'agencyAdmin2');
            agencyAdmin.ContactId = aCon.Id;
            agencyAdmin.Email = 'test2.portal@aldar.com.invalid';
            insert agencyAdmin;

            BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(oAcc);
            insert brokerRequest;
        }

        try {
            ManageRequestController.brokerRequestRecords('Marketing Reimbursement');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testMonthlyLimitNew() {
        Test.startTest();

        BrokerClassification__c brokerClassification = TestObjectsFactory.getBrokerClassificationRecord();
        brokerClassification.Quarter1MarketingBudget__c = 150000.00;
        brokerClassification.Quarter2MarketingBudget__c = 150000.00;
        brokerClassification.Quarter3MarketingBudget__c = 150000.00;
        brokerClassification.Quarter4MarketingBudget__c = 150000.00;
        
        brokerClassification.Quarter1MarketingBudgetIntl__c = 200000.00;
        brokerClassification.Quarter2MarketingBudgetIntl__c = 200000.00;
        brokerClassification.Quarter3MarketingBudgetIntl__c = 200000.00;
        brokerClassification.Quarter4MarketingBudgetIntl__c = 200000.00;
        brokerClassification.Year__c = String.valueOf(System.Today().year());
        insert brokerClassification;
        Account acc = TestObjectsFactory.getAgencyAccountRecord('Test Agency Account', 'TestRegistrationNo');
        acc.PreviousAgencyStatus__c = 'In Active';
        acc.AgencyStatus__c = 'Active';
        acc.BrokerClassification__c = brokerClassification.Id;
        acc.BillingCountry = 'United Arab Emirates';
        acc.BillingState = 'Abu Dhabi';
        acc.BrokerClassificationInJan__c = 'Test';
        acc.BrokerClassificationInFeb__c = 'Test';
        acc.BrokerClassificationInMar__c = 'Test';
        acc.BrokerClassificationInApr__c = 'Test';
        acc.BrokerClassificationInMay__c = 'Test';
        acc.BrokerClassificationInJun__c = 'Test';
        acc.BrokerClassificationInJul__c = 'Test';
        acc.BrokerClassificationInAug__c = 'Test';
        acc.BrokerClassificationInSep__c = 'Test';
        acc.BrokerClassificationInOct__c = 'Test';
        acc.BrokerClassificationInNov__c = 'Test';
        acc.BrokerClassificationInDec__c = 'Test';
        insert acc;

        BrokerRequest__c brokerRequest = TestObjectsFactory.getMarketingReimbursementRecord(acc);
        insert brokerRequest;

        try {
            ManageRequestController.monthlyLimit(acc.Id, Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID);
            ManageRequestController.quarterlyLimit(acc.Id, Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID, Date.today());
            ManageRequestController.quarterlyLimitNew(acc.Id, Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID, Date.newInstance(2024, 03, 31), 2, 2024);
            ManageRequestController.quarterlyLimitNew(acc.Id, Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID, Date.newInstance(2024, 06, 30), 3, 2023);
            ManageRequestController.quarterlyLimitNew(acc.Id, Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID, Date.newInstance(2024, 09, 30), 4, 2024);
            ManageRequestController.quarterlyLimitNew(acc.Id, Constants.MARKETING_REIMBURSEMENT_RECORD_TYPE_ID, Date.newInstance(2024, 12, 31), 1, 2024);
            ManageRequestController.getBufferDaysBrokerClassification(acc.Id); 
            ManageRequestController.checkExistingRequests(acc.Id, 'Q3', '2024');
            ManageRequestController.getQuarters();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }

        Test.stopTest();
    }
    
    @isTest
    public static void testcalculateInvoiceAmount() { 
        List<Account> listAgency = [SELECT Id FROM Account LIMIT 1];
        
        ManageRequestController.getYears();
        ManageRequestController.calculateInvoiceAmount(listAgency[0].Id, 'Domestic', 'Q1' , '2025');
    }
}