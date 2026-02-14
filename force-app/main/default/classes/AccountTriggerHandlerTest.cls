@isTest
public class AccountTriggerHandlerTest {
    
    @isTest
    public static void insertTest() {
        Test.startTest(); 
       	List<Account> accList = new List<Account>();
        TriggerHandler.processedIds = new Set<Id>();
        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;
        
        TriggerHandler.processedIds = new Set<Id>();
        Account orgAcc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc1;
        
        TriggerHandler.processedIds = new Set<Id>();
        orgAcc1.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        orgAcc1.ParentId = orgAcc.Id;
        update orgAcc1;
        
        TriggerHandler.processedIds = new Set<Id>();
        orgAcc1.ParentId = null;
        update orgAcc1;
        
        AccountTriggerHandler.recalculateAccountRelationShip(new set<id>{orgAcc1.Id});
        
        Test.stopTest();
    }
    
     @isTest
    public static void insertTest2() {
        Test.startTest(); 
        List<Account> accList = new List<Account>();
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        acc.VIP_Change_Apporval_Status__c = 'Pending';
        insert acc;
         try{
            TriggerHandler.processedIds = new Set<Id>();
            acc.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            acc.ERPID__c = '123456789';
            acc.BillingStateCode = 'AJ';
            acc.BillingCity = 'Ajman';
            acc.ShippingStateCode = 'AJ';
            acc.ShippingCity = 'Ajman';
            acc.VIP_Change_Apporval_Status__c = 'Pending';
            acc.SubAccountManager__c = [SELECT Id FROM User LIMIT 1].Id;
            acc.OwnerId = Userinfo.getUserId();
            acc.PersonEmail = 'Test@gm.com';
            update acc;
         }catch(exception ex){
             system.debug('###EXCEPTION###'+ex);
         }
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.SaleType__c = 'New Sale';
        insert opp;
        
        Test.stopTest();
    }
    
    @isTest
    public static void insertTest3() {
        Test.startTest(); 
        List<Account> accList = new List<Account>();
        TriggerHandler.processedIds = new Set<Id>();
        Account agencyAcc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'G123456');
        insert agencyAcc;
        
        TriggerHandler.processedIds = new Set<Id>();
        agencyAcc.AgencyStatus__c = 'Active';
        agencyAcc.SyncStatus__c = Constants.STATUS_SYNCED;
        update agencyAcc;
        
        TriggerHandler.processedIds = new Set<Id>();
        agencyAcc.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
        update agencyAcc;
        
        TriggerHandler.processedIds = new Set<Id>();
        agencyAcc.AgencyStatus__c = Constants.UNIT_STATUS_BLOCKED;
        update agencyAcc;
        Test.stopTest(); 
    }
    
    @isTest
    public static void duplicateAccountPreventionTest() {
        List<Account> accList = new List<Account>();
        User custMgmtUserRecord = TestObjectsFactory.getUserRecord(Constants.CUSTOMER_MGMT_PROFILE, 'testUser');
        insert custMgmtUserRecord;
        Test.startTest();
        Account residentacc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        residentacc.MobileNumber__c = '123456789';
        residentacc.ResidentStatus__pc = 'Resident';
        residentacc.NationalIdNumber__pc = 'NID12345';
        insert residentacc;
        
        residentacc.OwnerId = [Select Id from User Where Profile.name = 'System Administrator' and isActive = true and Id !=: residentacc.OwnerId limit 1].Id;
        update residentacc;
        // AccountTriggerHandler.documentShareWithAccountOwner(new List<Account>{residentacc});
        Account nonresidentacc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        nonresidentacc.MobileNumber__c = '123456789';
        nonresidentacc.ResidentStatus__pc = 'Non-Resident';
        nonresidentacc.PassportNumber__pc = 'PN12345';
        nonresidentacc.Nationality__pc = 'India';
        nonresidentacc.VisaType__pc  = 'Visa not applicable';
        nonresidentacc.PersonBirthDate = system.today().addYears(-50);
        insert nonresidentacc;
        system.runAs(custMgmtUserRecord) {
            try{
                Account duplicateresidentacc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
                duplicateresidentacc.MobileNumber__c = '123456789';
                duplicateresidentacc.ResidentStatus__pc = 'Resident';
                duplicateresidentacc.NationalIdNumber__pc = 'NID12345';
                insert duplicateresidentacc;
                TriggerHandler.processedIds = new Set<Id>();
                duplicateresidentacc.MobileNumber__c = '123456789';
                update duplicateresidentacc;
                Account duplicatenonresidentacc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
                duplicatenonresidentacc.MobileNumber__c = '123456789';
                duplicatenonresidentacc.ResidentStatus__pc = 'Non-Resident';
                duplicatenonresidentacc.PassportNumber__pc = 'PN12346';
                duplicatenonresidentacc.Nationality__pc = 'India';
                duplicatenonresidentacc.PersonBirthDate = system.today().addYears(-50);
                insert duplicatenonresidentacc;
                Account updateDuplicate = new Account(Id = duplicatenonresidentacc.Id);
                updateDuplicate.PassportNumber__pc = 'PN12345';
                updateDuplicate.Nationality__pc = 'India';
                updateDuplicate.PersonBirthDate = system.today().addYears(-50);
                TriggerHandler.processedIds = new Set<Id>();
                update updateDuplicate;
                AccountTriggerHandler.updateInvoiceBundle(new List<Id>{updateDuplicate.Id});
            } catch(exception ex){
                system.debug('###EXCEPTION###'+ex);
            }
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testAccountSharewithSubManagers() {
        // Create test data
        List<Account> accList = new List<Account>();
        Account testAccount = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'G123456');
        testAccount.SubAccountManager__c = UserInfo.getUserId();
        insert testAccount;
        
        // Create an old version of the account
        Account oldAccount = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'G123456');
        oldAccount.OwnerId = UserInfo.getUserId(); 
        oldAccount.SubAccountManager__c = null;
        insert oldAccount;
        
        Map<Id, Account> oldMap = new Map<Id, Account>();
        oldMap.put(oldAccount.Id, oldAccount);
        
        // Set up initial data
        List<Account> newList = new List<Account>{testAccount};
            Set<Id> AccountOwnerIdSet = new Set<Id>{testAccount.OwnerId};
                Set<Id> oldSubAccountManagerIds = new Set<Id>{};
                    
                    // Perform the test
                    Test.startTest();
        List<Account> accountsToBeShared = new List<Account>();
        for (Account acc : newList) {
            Account oldAcc2 = oldMap.get(acc.Id);
            if (acc.SubAccountManager__c != null) {
                AccountOwnerIdSet.add(acc.OwnerId);
                accountsToBeShared.add(acc);
                // oldSubAccountManagerIds.add(oldAcc2.SubAccountManager__c);
            }
            /* if (oldAcc2.SubAccountManager__c != null && acc.SubAccountManager__c == null) {
oldSubAccountManagerIds.add(oldAcc2.SubAccountManager__c);
accountsToBeShared.add(acc);
} */
        }
        AccountTriggerHandler.accountSharewithSubManagers(AccountOwnerIdSet, accountsToBeShared, oldSubAccountManagerIds);
        Test.stopTest();
        
        // Verify the results
        List<AccountShare> subManageraccountShares = [SELECT Id FROM AccountShare WHERE AccountId = :testAccount.Id];
        System.assertEquals(1, subManageraccountShares.size(), 'Expected one AccountShare record to be inserted');
        
    }
    
    @isTest
    public static void RequiredFieldMissingTest() {
        Test.startTest();
        List<Account> accList = new List<Account>();
        User custMgmtUserRecord = TestObjectsFactory.getUserRecord(Constants.CUSTOMER_MGMT_PROFILE, 'testUser');
        insert custMgmtUserRecord;
        system.runAs(custMgmtUserRecord) {
            try{
                Account duplicateresidentacc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
                duplicateresidentacc.MobileNumber__c = '123456789';
                duplicateresidentacc.ResidentStatus__pc = 'Resident';
                duplicateresidentacc.NationalIdNumber__pc = '123156789101112';
                duplicateresidentacc.VisaUIDNo__pc = '123456789101112';
                insert duplicateresidentacc;
                
                Account duplicatenonresidentacc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
                duplicatenonresidentacc.MobileNumber__c = '123456789';
                duplicatenonresidentacc.ResidentStatus__pc = 'Non-Resident';
                duplicatenonresidentacc.PlaceofIssue__pc = null;
                duplicatenonresidentacc.NationalIdNumber__pc = '123156789101112';
                duplicatenonresidentacc.VisaUIDNo__pc = '123456789101112';
                insert duplicatenonresidentacc;
            } catch(exception ex){
                system.debug('###EXCEPTION###'+ex);
            }
        }
        Test.stopTest();
    }
    
    @isTest
    public static void RequiredFieldMissingTest2() {
        Test.startTest();
        List<Account> accList = new List<Account>();
        User custMgmtUserRecord = TestObjectsFactory.getUserRecord(Constants.CUSTOMER_MGMT_PROFILE, 'testUser');
        insert custMgmtUserRecord;
        system.runAs(custMgmtUserRecord) {
            try{
                Account duplicateresidentacc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
                duplicateresidentacc.MobileNumber__c = '123456789';
                duplicateresidentacc.ResidentStatus__pc = 'Resident';
                duplicateresidentacc.NationalIdNumber__pc = '123456789101112';
                duplicateresidentacc.PassportNumber__pc = '123456789';
                duplicateresidentacc.PersonBirthdate = Date.newInstance(1993, 4, 8);
            	duplicateresidentacc.VisaUIDNo__pc = '123456789101112';
                insert duplicateresidentacc;
                
                Account duplicatenonresidentacc = duplicateresidentacc;
                duplicatenonresidentacc.MobileNumber__c = '123456789';
                duplicatenonresidentacc.ResidentStatus__pc = 'Non-Resident';
                duplicatenonresidentacc.PlaceofIssue__pc = null;
                duplicatenonresidentacc.NationalIdNumber__pc = '123156789101112';
                duplicatenonresidentacc.PassportNumber__pc = '123451789';
                duplicatenonresidentacc.PersonBirthdate = Date.newInstance(1993, 4, 8);
                duplicatenonresidentacc.Nationality__pc = 'United Arab Emirates';
                update duplicatenonresidentacc;
            } catch(exception ex){
                system.debug('###EXCEPTION###'+ex);
            }
        }
        Test.stopTest();
    }
    
    @isTest
    public static void updateDDRIdsTest(){
        Test.startTest();
        List<Account> accList = new List<Account>();
        Account residentacc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        residentacc.MobileNumber__c = '123456789';
        residentacc.ResidentStatus__pc = 'Resident';
        residentacc.NationalIdNumber__pc = 'NID12345';
        insert residentacc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(residentacc.Id);
        opp.SaleType__c ='New Sale';
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1= TestObjectsFactory.getSalesOrderRecord(opp.Id, residentacc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        ddr.PayerAccount__c=residentacc.Id;
        ddr.Account__c=residentacc.Id;
        ddr.Status__c = 'Sent to Bank';
        insert ddr;
        
        AccountTriggerHandler.updateDDRIds(new List<Account>{residentacc});
        AccountTriggerHandler.documentShareWithAccountOwner(new List<Account>{residentacc});
        test.stopTest();
    }
    
    /* Method           : bankDetailsApproved
     * Description      : Test class coverage for bank details create/update
     */ 
    @isTest 
    public static void bankDetailsApproved(){
        Test.startTest();
        List<Account> accList = new List<Account>();
        Account testAccount = TestObjectsFactory.getAgencyAccountRecord('TestAgency21213', 'G132344');
        testAccount.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        testAccount.BranchAddress__c = 'Abu Dhabi UAE';
        testAccount.CurrencyIsoCode = 'AED';
        testAccount.BankCountry__c = 'United Arab Emirates';
        testAccount.IBANNumber__c = 'AE620030010047289020001';
        testAccount.SwiftCode__c = 'ADCBAEAA';
        testAccount.BankAccountNumber__c = 'A00032589';
        testAccount.BankName__c = 'ADCB';
        testAccount.ProposedBankDetailStatus__c = 'Pending';
        insert testAccount;
        
        System.debug('testAccount---->'+testAccount.Id);
        
        Account updateAcc                       = new Account(Id=testAccount.Id);
        updateAcc.Name                          = 'UpdatedAgencyName';
        updateAcc.ProposedBranchAddress__c      = 'Dubai UAE';
        updateAcc.ProposedBankCountry__c        = 'United Arab Emirates';
        updateAcc.ProposedIBANNumber__c         = 'AE620030010047289020009';
        updateAcc.ProposedSwiftCode__c          = 'ADIBAEAA';
        updateAcc.ProposedBankAccountNumber__c  = 'A00032599';
        updateAcc.ProposedBankName__c           = 'ADIB';
        updateAcc.ProposedBankDetailStatus__c   = 'Approved';
        
        TriggerHandler.processedIds = new Set<Id>();
        updateAcc.AgencyStatus__c = 'Active';
        updateAcc.SyncStatus__c = Constants.STATUS_SYNCED;
        update updateAcc;
        
        Test.stopTest();
        
    }
    @isTest 
    public static void customerAppLockedTest(){
        List<Account> accList = new List<Account>();
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V2', 'P2');
        acc.MobileNumber__c = '1234567890';
        acc.isCustomerAppLocked__c      = false;
        insert acc;    
        
        try{
            List<SObject> oldList = new List<SObject>();
            Map<Id, SObject> oldMap = new Map<Id, SObject>{acc.Id => (SObject)acc};
                oldList.add((SObject) acc);
            
            Account testAccount = [SELECT Id, CustomerType__c, ParentId, RegistrationNumber__c, ERPID__c, PassportNumber__pc, CustomerSubType__c, NationalIdNumber__pc, MobileNumber__c, AgencyStatus__c, BrokerAgent__c, PersonEmail, SyncStatus__c, isCustomerAppLocked__c, RecordTypeId FROM Account WHERE MobileNumber__c = '1234567890'];
            
            Test.startTest();
            testAccount.isCustomerAppLocked__c      = true;
            update testAccount;
            
            List<SObject> newList = new List<SObject>();
            Map<Id, SObject> newMap = new Map<Id, SObject>{acc.Id => (SObject)acc};
                newList.add(testAccount);
            AccountTriggerHandler trig = new AccountTriggerHandler();
            trig.afterUpdateMethod(newList, newMap, oldList, oldMap);
            Test.stopTest();
        } catch(Exception e) {}
    }
    
    @isTest 
    public static void bankDetailsApproved1(){
    
        Test.startTest();
        List<Account> accList = new List<Account>();
        Account testAccount = TestObjectsFactory.getAgencyAccountRecord('TestAgency21213', 'G132344');
        testAccount.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        testAccount.BranchAddress__c = 'Abu Dhabi UAE';
        testAccount.CurrencyIsoCode = 'AED';
        testAccount.BankCountry__c = 'United Arab Emirates';
        testAccount.IBANNumber__c = 'AE620030010047289020001';
        testAccount.SwiftCode__c = 'ADCBAEAA';
        testAccount.BankAccountNumber__c = 'A00032589';
        testAccount.BankName__c = 'ADCB';
        testAccount.ProposedBankDetailStatus__c = 'Pending';
        testAccount.ERPID__c = '12213';
        insert testAccount;
        
        Contact conta1 = TestObjectsFactory.contactDataSetup(testAccount.Id);
        conta1.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta1.AgentStatus__c = 'Active';
        conta1.PrimaryAgencyAdmin__c = true;
        conta1.MobileCountryCode__c  = '971';
        conta1.MobilePhone__c = '9555222639';
        conta1.Email = 'msarfaraj@aldar.com';
        conta1.BrokerType__c = Constants.AGENCY_ADMIN;
        update conta1;
        
        
        Contact conta2 = TestObjectsFactory.contactDataSetup(testAccount.Id);
        conta2.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta2.AgentStatus__c = 'Active';
        conta2.PrimaryOwner__c = true;
        conta2.MobileCountryCode__c  = '971';
        conta2.MobilePhone__c = '9555222630';
        conta2.Email = 'msarfaraj1@aldar.com';
        conta2.BrokerType__c = 'Partner/Owner';
        update conta1;
        
        System.debug('testAccount---->'+testAccount.Id);
        
        Account updateAcc             = new Account(Id=testAccount.Id);
        updateAcc.Name              = 'UpdatedAgencyName';
        updateAcc.ProposedBranchAddress__c     = 'Dubai UAE';
        updateAcc.ProposedBankCountry__c     = 'United Arab Emirates';
        updateAcc.ProposedIBANNumber__c     = 'AE620030010047289020009';
        updateAcc.ProposedSwiftCode__c       = 'ADIBAEAA';
        updateAcc.ProposedBankAccountNumber__c   = 'A00032599';
        updateAcc.ProposedBankName__c       = 'ADIB';
        updateAcc.ProposedBankDetailStatus__c   = 'Approved';
        
        TriggerHandler.processedIds = new Set<Id>();
        updateAcc.AgencyStatus__c = 'Active';
        updateAcc.SyncStatus__c = Constants.STATUS_SYNCED;
        update updateAcc;
        
        AccountTriggerHandler.suspendActiveAgencyRelatedAgents(new Set<Id>{testAccount.Id}, 'Active');
        AccountTriggerHandler.suspendActiveAgencyRelatedAgents(new Set<Id>{testAccount.Id}, 'Suspended');
    }
}