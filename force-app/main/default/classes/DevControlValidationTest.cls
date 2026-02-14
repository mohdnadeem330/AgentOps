@isTest
public class DevControlValidationTest {
    @isTest
    Public static void method1(){
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;
        //Dummy Commit - SSP-348
BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;
       

        Unit__c unit = new Unit__c();
        unit.Name='Test';
        unit.BuildingSectionName__c=buildingSection.id;
        unit.Project__c=project.id;
        unit.UnitType__c='Apartment';
        unit.RecordTypeId = Schema.SObjectType.Unit__c.getRecordTypeInfosByName().get('Plot').getRecordTypeId();
        unit.GFAArea__c=200;
        unit.MultiPurposeAmount__c=1000;
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
       newAccount.SourceofFunds__pc='Profit';
        insert newAccount;
       
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id );
        opp.EnquiryTrigger__c=null;
        opp.EmployeeId__c = '123456789';
        opp.EmployeeEmail__c = 'test@aldar.com';
        opp.SaleType__c = 'New Sale';
        insert opp;
        
        SalesOrder__c so=new SalesOrder__c();
        so.Account__c=newAccount.id;
        so.Unit__c=unit.id;
        so.Opportunity__c=opp.id;
        so.Status__c='sold';
        insert so;
         Case newCase = new Case();
        newCase.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Development_Control').getRecordTypeId();
        newCase.type='GFA';
        
        newCase.Subject = 'Test Subject';
        newCase.Description = 'Test Description';
        newCase.Status = 'Assigned';
        newCase.AccountId = newAccount.Id;
        newCase.Unit__c = Unit.id;
       
        insert newCase;
        
    }

}