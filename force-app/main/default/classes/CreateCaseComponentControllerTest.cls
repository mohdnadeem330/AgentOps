@isTest public class CreateCaseComponentControllerTest {
    @isTest static void checkForDuplicateAccounts(){
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Status__c = 'Sold';
        insert unit;
        
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.PassportNumber__pc = 'N6385378';
        newAccount.ResidentStatus__pc = 'Resident';
        newAccount.MaritalStatus__pc = 'Married';
        newAccount.EmploymentStatus__pc = 'Self Employed';
        newAccount.PersonEmail = 'test@aldar.com.invalid';
        newAccount.MobileCountryCode__pc = '971';
        newAccount.MobilePhone__pc = '9876543115';
        newAccount.Company__pc = 'XXXXX';
        newAccount.Position__pc = 'XXX';
        newAccount.CompanyAddress__pc = 'NA';
        newAccount.NoofYearswithCompany__pc = 10;
        newAccount.Industry = 'Agriculture';
        newAccount.AnnualIncome__pc = 1234567;
        newAccount.NationalIdNumber__pc = '784123456789012';
        newAccount.SourceofFunds__pc = 'Profits/Salary';
        newAccount.PersonEmail = 'tt@tt.com';
        insert newAccount;
        
        Account newAccount1 = TestObjectsFactory.getPersonAccountRecord();
        newAccount1.PassportNumber__pc = 'N6385378';
        newAccount1.ResidentStatus__pc = 'Resident';
        newAccount1.MaritalStatus__pc = 'Married';
        newAccount1.EmploymentStatus__pc = 'Self Employed';
        newAccount1.PersonEmail = 'test@aldar.com.invalid';
        newAccount1.MobileCountryCode__pc = '971';
        newAccount1.MobilePhone__pc = '9876543115';
        newAccount1.Company__pc = 'XXXXX';
        newAccount1.Position__pc = 'XXX';
        newAccount1.CompanyAddress__pc = 'NA';
        newAccount1.NoofYearswithCompany__pc = 10;
        newAccount1.Industry = 'Agriculture';
        newAccount1.AnnualIncome__pc = 1234567;
        newAccount1.NationalIdNumber__pc = '784123456789012';
        newAccount1.SourceofFunds__pc = 'Profits/Salary';
        newAccount1.PersonEmail = 'tt@tt.com';
        insert newAccount1;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.Account__c = newAccount.Id;
        insert salesOrder;
        
        Id standardRecordTypeId = Utilities.getRecordTypeId('Case', 'Standard Case');
        
        Test.startTest();
        
        CreateCaseComponentController.returnToastMessage(newAccount.Id);

        Case updatecase = TestObjectsFactory.getCaseRecord(standardRecordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unit.Id, 'Phone');
        updatecase.SubVertical__c = Constants.CONTACT_CENTRE_SUB_VERTICAL;
        updatecase.CaseCategory__c = Constants.CONTACT_DETAILS_UPDATE_CATEGORY;
        updatecase.Unit__c = unit.Id;
        updatecase.subject='Test';
        updatecase.CustomerType__c = 'Owner';
        insert updatecase;
        
        TriggerHandler.processedIds = new Set<Id>();
        updatecase.AccountId = newAccount.Id;
        update updatecase;
        
        CreateCaseComponentController.returnToastMessage(newAccount1.Id);
        delete updateCase;
        
        CreateCaseComponentController.returnToastMessage(newAccount.Id);
        CreateCaseComponentController.returnToastMessage(null);
        
        Test.stopTest();
    }
    @isTest static void checkForNonDuplicateAccounts(){
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Status__c = 'Sold';
        insert unit;
        
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        newAccount.PassportNumber__pc = 'N6385378';
        newAccount.ResidentStatus__pc = 'Resident';
        newAccount.MaritalStatus__pc = 'Married';
        newAccount.EmploymentStatus__pc = 'Self Employed';
        newAccount.PersonEmail = 'test@aldar.com.invalid';
        newAccount.MobileCountryCode__pc = '971';
        newAccount.MobilePhone__pc = '9876543115';
        newAccount.Company__pc = 'XXXXX';
        newAccount.Position__pc = 'XXX';
        newAccount.CompanyAddress__pc = 'NA';
        newAccount.NoofYearswithCompany__pc = 10;
        newAccount.Industry = 'Agriculture';
        newAccount.AnnualIncome__pc = 1234567;
        newAccount.NationalIdNumber__pc = '784123456789012';
        newAccount.SourceofFunds__pc = 'Profits/Salary';
        newAccount.PersonEmail = 'tt@tt.com';
        insert newAccount;
        
        Test.startTest();
        
        CreateCaseComponentController.returnToastMessage(newAccount.Id);
        
        Test.stopTest();
    }
    @isTest static void checkForNonPersonAccountUsers(){
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;

        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;

        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        unit.Status__c = 'Sold';
        insert unit;
        
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('kjdlkjsl', 'kjdlkfjkls');
        insert newAccount;
        
        Test.startTest();
        
        CreateCaseComponentController.returnToastMessage(newAccount.Id);
        
        Test.stopTest();
    }
}