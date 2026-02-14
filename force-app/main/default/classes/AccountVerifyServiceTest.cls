@isTest
public class AccountVerifyServiceTest {
    static Lead leadRec ;
    
    static void init(){
        leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.Email = 'dupetestemail@test.com';
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        //insert leadRec ;
        
    }
    
    static testmethod void testVerifyLead(){
        
        init();
        
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'123223376');
        personAcc.PersonEmail = 'chiragraiyani2@gmail.com';
        personAcc.MobilePhone__pc = '1234567890';
        personAcc.NationalIdNumber__pc = '123223376';
        personAcc.ResidentStatus__pc = 'Resident';
        insert personAcc;
        //Id leadId = [SELECT Id from Lead Limit 1].Id;
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Success","data":{"isPhoneValid":null,"isEmailValid":null,"hasDuplicates":null,"DuplicateAccounts":[{"SalesOrderCount":0,"Name":"Feb14 Test broker","CustomerType":"New Customer","CustomerSubType":null,"AccountNumber":"A00072961"}]}}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        TestObjectsFactory.initializeRestContext('{"RecordType":"Person","NationalId":"123223376","ResidentStatus":"Resident",Email":"chiragraiyani2@gmail.com","Phone":"+918980676862","SelectedAccountId":"'+personAcc.Id+'","CountryCode":"91", "DateOfBirth":"1990-05-23" }', '/verify/Account');
        AccountVerificationService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        //LeadVerifyWebService.doPost(leadId);        
        Test.stopTest();
    }
    static testmethod void testVerifyLead1(){
        
        init();
        
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'123223376');
        personAcc.PersonEmail = 'chiragraiyani2@gmail.com';
        personAcc.MobilePhone__pc = '1234567890';
        insert personAcc;
        
        //Id leadId = [SELECT Id from Lead Limit 1].Id;
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Success","data":{"isPhoneValid":null,"isEmailValid":null,"hasDuplicates":null,"DuplicateAccounts":[{"SalesOrderCount":0,"Name":"Feb14 Test broker","CustomerType":"New Customer","CustomerSubType":null,"AccountNumber":"A00072961"}]}}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        TestObjectsFactory.initializeRestContext('{"RecordType":"Person","Email":"chiragraiyani2@gmail.com","Phone":"+918980676862","SelectedAccountId":"'+personAcc.Id+'","CountryCode":"91","ResidentStatus":"Resident"}', '/verify/Account');
        AccountVerificationService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        //LeadVerifyWebService.doPost(leadId);        
        Test.stopTest();
    }
    
    static testmethod void testVerifyLeadNDupes(){
        
        init();
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'123223376');
        personAcc.PersonEmail = 'chiragraiyani2@gmail.com';
        personAcc.MobilePhone__pc = '1234567890';
        insert personAcc;
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Success","data":{"isPhoneValid":null,"isEmailValid":null,"hasDuplicates":null,"DuplicateAccounts":[{"SalesOrderCount":0,"Name":"Feb14 Test broker","CustomerType":"New Customer","CustomerSubType":null,"AccountNumber":"A00072961"}]}}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        TestObjectsFactory.initializeRestContext('{"RecordType":"UpdateContact","Email":"chiragraiyani2@gmail.com","Phone":"+918980676862","SelectedAccountId":"'+personAcc.Id+'"}', '/verify/Account');
        //TestObjectsFactory.initializeRestContext(null, '/verify/lead');
        AccountVerificationService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        //LeadVerifyWebService.doPost(leadId);        
        Test.stopTest();
    }
    static testmethod void testVerifyLeadNDupe1s(){
        
        init();
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'123223376');
        personAcc.PersonEmail = 'chiragraiyani2@gmail.com';
        personAcc.MobilePhone__pc  = '1234567890';
        insert personAcc;
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Success","data":{"isPhoneValid":null,"isEmailValid":true,"hasDuplicates":null,"DuplicateAccounts":[{"SalesOrderCount":0,"Name":"Feb14 Test broker","CustomerType":"New Customer","CustomerSubType":null,"AccountNumber":"A00072961"}]}}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        TestObjectsFactory.initializeRestContext('{"RecordType":"Organization","Email":"chiragraiyani2@gmail.com","Phone":"+918980676862","SelectedAccountId":"'+personAcc.Id+'"}', '/verify/Account');
        //TestObjectsFactory.initializeRestContext(null, '/verify/lead');
        AccountVerificationService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        //LeadVerifyWebService.doPost(leadId);        
        Test.stopTest();
    }
    
    static testmethod void testVerifyLeadNDupes1(){
        init();
        Account testAccount = TestObjectsFactory.getAgencyAccountRecord('TestAgency21213', 'G132344');
        testAccount.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        testAccount.BranchAddress__c = 'Abu Dhabi UAE';
        testAccount.CurrencyIsoCode = 'AED';
        testAccount.BankCountry__c = 'United Arab Emirates';
        testAccount.IBANNumber__c = 'AE620030010047289020001';
        testAccount.SkipDuplicateApprovalStatus__c = 'Approved';
        testAccount.SwiftCode__c = 'ADCBAEAA';
        testAccount.BankAccountNumber__c = 'A00032589';
        testAccount.BankName__c = 'ADCB';
        testAccount.ProposedBankDetailStatus__c = 'Pending';
        testAccount.ERPID__c = '12213';
        //testAccount.PassportNumber__pc = 'A123456789';
        insert testAccount;
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Success","data":{"isPhoneValid":null,"isEmailValid":null,"hasDuplicates":null,"DuplicateAccounts":[{"SalesOrderCount":0,"Name":"Feb14 Test broker","CustomerType":"New Customer","CustomerSubType":null,"AccountNumber":"A00072961"}]}}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        TestObjectsFactory.initializeRestContext('{"RecordType":"UpdateContact","Email":"chiragraiyani2@gmail.com","Phone":"+918980676862","SelectedAccountId":"'+testAccount.Id+'"}', '/verify/Account');
        //TestObjectsFactory.initializeRestContext(null, '/verify/lead');
        AccountVerificationService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        //LeadVerifyWebService.doPost(leadId);        
        Test.stopTest();
    }
    static testmethod void testVerifyLeadNDupes2(){
        
        init();
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
        testAccount.SkipDuplicateApprovalStatus__c = 'Sent for Approvals';
        //testAccount.PassportNumber__pc = 'A123456789';
        insert testAccount;
        String responseBody = '{"success":true,"statusCode":200,"requestId":null,"message":"Success","data":{"isPhoneValid":null,"isEmailValid":null,"hasDuplicates":null,"DuplicateAccounts":[{"SalesOrderCount":0,"Name":"Feb14 Test broker","CustomerType":"New Customer","CustomerSubType":null,"AccountNumber":"A00072961"}]}}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        TestObjectsFactory.initializeRestContext('{"RecordType":"UpdateAccount","residentStatus":"Resident",Email":"chiragraiyani2@gmail.com","Phone":"+918980676862","SelectedAccountId":"'+testAccount.Id+'"}', '/verify/Account');
        //TestObjectsFactory.initializeRestContext(null, '/verify/lead');
        AccountVerificationService.doPost();
        TestObjectsFactory.initializeRestContext('', '/some/path', '0.6', 'iOS', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        //LeadVerifyWebService.doPost(leadId);        
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidPhoneEmail() {
        TestObjectsFactory.initializeRestContext('{"RecordType":"Person","Email":"invalidemail","Phone":"123","SelectedAccountId":"001XXXXXXXXXXXX","CountryCode":"91", "DateOfBirth":"1990-05-23"}', '/verify/Account');
        
        Test.startTest();
        AccountVerificationService.doPost();
        Test.stopTest();
    }
    
    @isTest
    static void testWithException() {
        // Invalid JSON will cause an exception and hit the catch block
        TestObjectsFactory.initializeRestContext('invalid_json_here', '/verify/Account');
        
        Test.startTest();
        AccountVerificationService.doPost();  // should fall into catch block
        Test.stopTest();
    }
    
    @isTest
    static void testWithUnknownRecordType() {
        TestObjectsFactory.initializeRestContext('{"RecordType":"Unknown","Email":"test@test.com","Phone":"+911234567890"}', '/verify/Account');
        
        Test.startTest();
        AccountVerificationService.doPost();
        Test.stopTest();
    }
    
    @isTest
    static void testNonResidentNoDupes() {
        Account personAcc = TestObjectsFactory.getAccountRecord('Person Account',true,'987654321');
        personAcc.PersonEmail = 'testnonresident@test.com';
        personAcc.MobilePhone__pc = '0987654321';
        insert personAcc;
        
        String requestBody = '{"RecordType":"Person","NationalId":"987654321","ResidentStatus":"Non-Resident","Email":"testnonresident@test.com","Phone":"+919876543210","SelectedAccountId":"'+personAcc.Id+'","CountryCode":"91"}';
        TestObjectsFactory.initializeRestContext(requestBody, '/verify/Account');
        
        Test.startTest();
        AccountVerificationService.doPost();
        Test.stopTest();
    }
    
    @isTest
    static void testDuplicateCheckResident() {
        // Insert a Resident account that should be treated as duplicate
        Account residentAcc = new Account();
        residentAcc.RecordTypeId = Constants.PERSON_RECORD_TYPE_ID;
        residentAcc.NationalIdNumber__pc = 'RES123456';
        residentAcc.ResidentStatus__pc = 'Resident';
        residentAcc.PersonEmail = 'resident@example.com';
        residentAcc.MobilePhone__pc = '1234567890';
        residentAcc.Phone = '1234567890';
        residentAcc.LastName = 'Test';
        insert residentAcc;
        
        String requestBody = '{"RecordType":"Person","NationalId":"RES123456","ResidentStatus":"Resident","Email":"resident@example.com","Phone":"+971500000001","SelectedAccountId":"'+residentAcc.Id+'","CountryCode":"971","DateOfBirth":"1990-01-01"}';
        
        TestObjectsFactory.initializeRestContext(requestBody, '/verify/Account');
        
        Test.startTest();
        AccountVerificationService.doPost();
        Test.stopTest();
        
        // You can add assertions to confirm the behavior if needed
        System.debug('Resident dupe test completed');
    }
    
    
}