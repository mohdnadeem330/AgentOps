@isTest
public class ALD_WorkLogHelperTest {
    
    @testSetup static void setupData() {
        Test.startTest();
        User us = [SELECT Id FROM User WHERE IsActive=true and UserName!=:Userinfo.getUserName() and ProfileId=:UserInfo.getProfileId() Limit 1];
        //try{
        Account newAccount = new Account();
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.PERSON_ACCOUNT_RT).getRecordTypeId();
        newAccount.FirstName = 'Dexter';
        newAccount.LastName = 'Morgan';
        newAccount.Salutation = 'Mr.';
        newAccount.PersonMobilePhone = '4567890';
        newAccount.PersonEmail = 'ssekar@gmail.com';
        newAccount.BillingStreet = 'Kormangala';
        newAccount.BillingCity = 'Bangalore';
        newAccount.BillingState = 'Karnataka';
        newAccount.BillingCountry = 'India';
        newAccount.BillingPostalCode = '526108';
        newAccount.ResidentialAddressSameAsPermanent__c = 'Yes';
        newAccount.Nationality__pc = 'India';
        newAccount.PassportNumber__pc = 'passportNo';
        newAccount.VisaUIDNo__pc = 'visaNo';
        newAccount.NationalIdNumber__pc = '784198784000000';
        newAccount.PassportType__pc = 'Permanent';
        newAccount.CustomerType__c = 'Existing Customer';
        newAccount.BillingStreet = 'Street';
        newAccount.BillingCity = 'Abu Dhabi';
        newAccount.BillingCountry = 'United Arab Emirates';
        newAccount.PassportIssueDate__pc = Date.Today().addDays(-100);
        newAccount.MaritalStatus__pc = 'Single';
        newAccount.PlaceofIssue__pc = 'United Arab Emirates';
        newAccount.PersonEmail = 'test@pwc.com';
        newAccount.PassportExpiryDate__pc = Date.Today().addDays(100);
        newAccount.FirstName = 'Test';
        newAccount.LastName = 'Account';
        newAccount.EmploymentStatus__pc = 'Employed';
        newAccount.Company__pc = 'PWC';
        newAccount.Position__pc = 'Developer';
        newAccount.CompanyAddress__pc = 'Dubai';
        newAccount.AnnualIncome__pc = 1200000;
        newAccount.NoofYearswithCompany__pc = 4;
        newAccount.UAEPassExists__pc = false;
        newAccount.Gender__pc = 'Male';
        newAccount.Nationality__pc = 'United Arab Emirates';
        newAccount.PersonBirthdate = Date.today().addDays(-100);
        newAccount.MobileCountryCode__c = '971';
        newAccount.MobilePhone__pc = '0545127085';
        newAccount.PersonMobilePhone = '0545127085';
        newAccount.MobileNumber__c = '0545127085';
        newAccount.MobileNumber1__c = '0545127085';
        newAccount.BillingState = 'Abu Dhabi';
        newAccount.Industry = 'Technology'; 
        newAccount.SourceofFunds__pc = 'Employment Income'; 
        newAccount.Position__pc = 'CEO';    
        newAccount.Company__pc = 'Company'; 
        newAccount.AnnualIncome__pc = 123.56;   
        newAccount.BankName__c = 'Abu Dhabi Commercial Bank';
        newAccount.BankCountry__c = 'United Arab Emirates';
        newAccount.CustomerBankName__c = 'Bank Name';
        newAccount.CustomerBankCountry__c = 'United Arab Emirates';
        newAccount.NoofYearswithCompany__pc = 1.4;
        insert newAccount;
        
        User u = createUser();
        insert u;
        
        Case newCase = TestObjectsFactory.getCase(newAccount.Id, null, 'Customer Management');
        insert newCase;
        Test.stopTest();
    }
    @isTest static void batchTest(){
        Test.StartTest();
        Case updCase = new Case();
        updCase.Id = [SELECT Id FROM Case LIMIT 1].Id;
        updCase.OwnerId = [SELECT Id FROM User LIMIT 1].Id;
        update updCase;
        
        //ALD_Work_Log__c workLog = [SELECT Id, Case__c FROM ALD_Work_Log__c WHERE Case__c <> null LIMIT 1];
        //Assert.areEqual(updCase.Id,[SELECT Id,Case__c FROM ALD_Work_Log__c WHERE Case__c <> null LIMIT 1].Case__c);
       
        Database.executeBatch(new ALD_WorkLogHandlerBatch());
        Test.StopTest();
    }
    public static User createUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Contact Centre Agent']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='test_' + math.random() + '@test.com');
        
        return u;
    }
}