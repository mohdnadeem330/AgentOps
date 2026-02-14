@isTest
public class KYCValidityControllerTest {
    @TestSetup
    static void makeData(){
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        acc.PassportExpiryDate__pc = System.today();
        //insert acc;
        
        Account acc2 = TestObjectsFactory.getPersonAccountRecord(101, 'Afghanistan', 'V2', 'P2');
        acc2.MobileNumber__c = '123456710';
        acc2.Nationality__pc = 'Afghanistan';
        acc2.ResidentStatus__pc = 'Resident';
        //insert acc2; 
        
        Account accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        //insert accountRecord;
        
        insert new List<Account>{acc, acc2, accountRecord};
        
        AccountRelationship__c accountRelation = TestObjectsFactory.getAccountRelationship(acc.Id, acc2.Id, 'Third Party');
        insert accountRelation;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        insert p;

        Unit__c u = TestObjectsFactory.unitDataSetup(p.Id);        
        insert u;

        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);
        sa.Unit__c = u.Id;
        insert sa;
        
        Contact newcon = new Contact();
        newcon.Lastname='Alice';
        newcon.AccountId = accountRecord.Id;
        newcon.RecordTypeId = Utilities.getRecordTypeId(Constants.CONTACT_OBJECT,Constants.ORGANISATION_CONTACT_RT);
        newcon.Email = 'test13@aldar.com';	
        newcon.phone = '527583669';	
        newcon.MobilePhone = '527583669';
        insert newcon;
    }

    @IsTest
    static void testUpdateKYCvalidity(){ 
        Test.startTest();
        List<SalesOrder__c> lstOrders = [SELECT Id, ComplianceStatus__c, Account__c FROM SalesOrder__c];
        lstOrders[0].ComplianceStatus__c = Constants.CLEARED;
        System.debug('lstOrders : '+ lstOrders);
        update lstOrders;
        Test.stopTest();
    }

    @IsTest
    static void testUpdateKYCvalidityOnARCleared(){ 
        Test.startTest();
        List<AccountRelationship__c> lstARs = [SELECT Id, ComplianceStatus__c, Account__c FROM AccountRelationship__c];
        lstARs[0].ComplianceStatus__c = Constants.CLEARED;
        System.debug('lstARs : '+ lstARs);
        update lstARs;
        Test.stopTest();
    }
    @IsTest
    static void testGetUpdatedAccounts(){ 
        Test.startTest();
        List<Account> lstAccount = [SELECT Id, Nationality__pc, ResidentStatus__pc FROM Account];
        KYCValidityController.getUpdatedAccounts(lstAccount);
        Test.stopTest();
    }
    @IsTest
    static void testPopulateKycStatusIfKycMandatoryFieldsUpdated(){ 
        Test.startTest();
        List<Account> lstAccount = [SELECT Id, 	AnnualIncome__pc, Nationality__pc FROM Account];
        lstAccount[0].AnnualIncome__pc = 20000;
        lstAccount[1].AnnualIncome__pc = 20000;
        lstAccount[1].Nationality__pc = 'United Arab Emirates';
        update lstAccount;
        Test.stopTest();
    }

    @IsTest
    static void testPopulateKycStatusIfKycMandatoryFieldsUpdatedOnContact(){ 
        Test.startTest();
        List<Contact> lstContact = [SELECT Id, 	AnnualIncome__c, PassportNumber__c FROM Contact];
        lstContact[0].AnnualIncome__c = 20000;
        lstContact[0].PassportNumber__c = '123123123';
        update lstContact;
        Test.stopTest();
    }

    @IsTest
    static void testKYCBatch(){ 
        Test.startTest();
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        acc.KYC_Expired_Date__c = System.today();
        acc.KYC_Validity_Status__c = 'Valid';
        insert acc;
        Account acc2 = TestObjectsFactory.getPersonAccountRecord(101, 'Afghanistan', 'V2', 'P2');
        acc2.MobileNumber__c = '123456710';
        acc2.Nationality__pc = 'Afghanistan';
        acc2.ResidentStatus__pc = 'Resident';
        acc2.KYC_Expired_Date__c = System.today();
        acc2.KYC_Validity_Status__c = 'Valid';        
        insert acc2; 
        Database.executeBatch(new BatchToExpireKYCValidity());
        Test.stopTest();
    }

    @IsTest
    static void testKYCSchedular(){ 
        Test.startTest();
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.PassportExpiryDate__pc = System.today();
        insert acc; 
        KYCValidityExpirySchedular job = new KYCValidityExpirySchedular();
        String sch = '0 0 23 * * ?';
        String jobID = System.schedule('KYC Schedular Job', sch, job);
        Test.stopTest();
    }
    
    @isTest
    static void testupdateKYCvalidity1(){
        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        //insert account;

        Account relatedAccount = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        //insert relatedAccount;
        
        Account relatedAccount1 = TestObjectsFactory.getOrganisationAccountRecord('companyName1', 'registrationNo1');
        //insert relatedAccount1;
        
        insert new List<Account>{account, relatedAccount, relatedAccount1};

        Contact con = TestObjectsFactory.contactDataSetup(account.Id);

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
        opp.EnquiryTrigger__c=null;
        opp.EmployeeId__c = '123456789';
        opp.EmployeeEmail__c = 'test@aldar.com';
        opp.SaleType__c = 'New Sale';
        insert opp;

        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;

        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;

        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        unit.Project__c = project.Id;
        unit.Name = 'MAYAN-B1-101095';
        unit.AffectionPlan__c = 'www.google.com';
        insert unit;      
        
		Test.startTest();
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder1.Unit__c = unit.Id;
        salesOrder1.Status__c = Constants.OPPO_UNIT_STATUS_PENDING;
        salesOrder1.CustomerType__c = Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF;
        salesOrder1.OffPlanSalesOrder__c = true;
        //salesOrder1.ProjectBudget__c = projectBudget.Id;
        insert salesOrder1;
        

        TriggerHandler.processedIds = new Set<Id>();
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwner(relatedAccount.Id,20,'Friend Of');
        jointOwner.SalesOrder__c = salesOrder1.Id;
        insert jointOwner;

        TriggerHandler.processedIds = new Set<Id>();
        salesOrder1.DoorNumber__c = '2';
        salesOrder1.SyncStatus__c = Constants.STATUS_SYNCED;
        salesOrder1.IsSalesOrderChange__c = false;
        salesOrder1.Status__c = Constants.UNIT_STATUS_SOLD;
        salesOrder1.CustomerAddress__c = '{"Street":"Street","City":"City","State":"State","PostalCode":"PostalCode","Country":"Country"}';
        salesOrder1.DeliveryConfirmationEmailTime__c = Datetime.now();
        salesOrder1.QualtricsIntegrationStatus__c = Constants.QUALTRICS_IN_PROGRESS;
        //update salesOrder1;
        Test.stopTest();
    }
    
}