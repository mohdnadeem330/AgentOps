@isTest
public with sharing class PropertyTransferBuyerTriggerFlowTest {
    private static testMethod void unit1(){

        //Dummy Commite
        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.HexaBPM__Code__c = 'Submitted';
        srStatus.Name = 'Submitted';
        insert srStatus;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.MobileNumber__c = '123456789';
        insert acc;

        

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        insert p;
        Unit__c u = TestObjectsFactory.unitDataSetup(p.Id);        
        insert u;

        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);
        sa.Unit__c = u.Id;
        insert sa;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(sa.Id, acc.Id, 'Friend Of');
        insert jointOwner;

        Account agencyAcc = TestObjectsFactory.getAgencyAccountRecord('Test Agency', 'G123456');
        insert agencyAcc;

        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;

        AccountService.getAllAccounts(new Set<String>{acc.UniqueKey__c});
        AccountService.getAgencies();
        AccountService.getAllActiveAgencies();
        AccountService.getAgenciesByName(new Set<String>{agencyAcc.Name});
        AccountService.getContactInfoFromAccount(new Set<Id>{acc.Id});
        AccountService.accountsFieldsValidation(acc.Id);

        Contact con1 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        con1.PrimaryContact__c = true;
        update con1;
        Test.startTest();

        AccountService.accountsFieldsValidation(orgAcc.Id);
        AccountService.updateUniqueKeys(new List<Account>{acc});
        AccountService.queryAllFieldsForDuplicateAccounts(new Set<String> {acc.UniqueKey__c}, new Set<String> {acc.UniqueKey__c}, acc.RecordTypeId, new Set<Id>{acc.Id});
        AccountService.fetchAccountById(acc.Id);

        Map<String, Object> authorizedSignatoryObject = new Map<String, Object>();

         HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Agency Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
        insert SR_Template;
        
        HexaBPM__Service_Request__c serviceRequestRecord = new HexaBPM__Service_Request__c();
        serviceRequestRecord.HexaBPM__SR_Template__c = SR_Template.Id;
        serviceRequestRecord.AccountName__c = 'this.agencyName';
        serviceRequestRecord.TradeCommercialLicenseNumber__c = 'this.licenseNumber';
        serviceRequestRecord.Address1__c = 'this.addressLine1';
        serviceRequestRecord.Address2__c = 'this.addressLine2';
        serviceRequestRecord.City__c = 'this.city';
        serviceRequestRecord.State__c = '';
        serviceRequestRecord.POBox__c = 'this.poBox';
        serviceRequestRecord.Country__c = 'Jordan';
        serviceRequestRecord.EstablishmentDate__c =  date.today();
        serviceRequestRecord.ExpiryDate__c = date.today().addYears(5);
        serviceRequestRecord.PhoneNumber__c = 'this.phoneNumber';
        serviceRequestRecord.CompanyEmail__c = 'this.companyEmail@test.com';
        serviceRequestRecord.Website__c = 'this.website';
        serviceRequestRecord.TaxRegistrationNumber__c = 'this.taxRegistrationCertificate';

        serviceRequestRecord.POATitle__c = 'Mr';
        serviceRequestRecord.NameOfPOA__c = 'this.nameOfPOA';

        serviceRequestRecord.BankName__c = 'this.bankName';
        serviceRequestRecord.SwiftCode__c = 'ssssss11aaa';
        serviceRequestRecord.IBANNumber__c = 'DE89370400440532013000';
        serviceRequestRecord.BankAddress__c = 'this.branchAddress';

        serviceRequestRecord.ReferredBy__c = 'this.referredBy' ;
        serviceRequestRecord.ReferredByTitle__c = 'Mr';
        serviceRequestRecord.Title__c = 'Mr';
        serviceRequestRecord.Designation__c = 'this.designation';
        serviceRequestRecord.SignatoryName__c = 'this.authorizedSignatoryName';
        serviceRequestRecord.SignatoryEmail__c = 'this.authorizedSignatoryEmail@test.com';
        serviceRequestRecord.SRType__c = 'Agency Registration';
        HexaBPM__Service_Request__c sr = BrokerAgencyRegistrationController.createServiceRequestRecord(serviceRequestRecord);
              

        PropertyTransferBuyerTriggerFlowMigrate.ServiceRequestClass srObj = new PropertyTransferBuyerTriggerFlowMigrate.ServiceRequestClass();
        srObj.srId = sr.Id;
        srObj.srTouchPoint = '';

        PropertyTransferBuyerTriggerFlowMigrate.updateSRandCreateSurveyTracker( new List<PropertyTransferBuyerTriggerFlowMigrate.ServiceRequestClass>{srObj});

        test.stopTest();
    }
}