@isTest
public class EmiratesIdValidationControllerTest {
    
    @testSetup
    public Static void setupTestData(){
        
        List<Contact> listContact = new List<Contact>();
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;

        Contact conta1 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        Contact conta2 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        conta1.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta1.AgentStatus__c = 'Active';
        conta1.PrimaryOwner__c = true;
        conta1.NationalIdNumber__c = '784923989238333983';
        conta1.Birthdate = System.Today().addYears(-30);
        conta1.Nationality__c = 'United Arab Emirates';
		//conta1.UAENationalityVerified__c = '';        

        conta2.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta2.AgentStatus__c = 'Active';
        conta2.PrimaryAgencyAdmin__c = true;
        
        listContact.add(conta1);
        listContact.add(conta2);
        update listContact;        
    }
    
     @isTest
    static void testEmiratesIDValidation() {
        
        Test.startTest();
        String responseBody = '{"result":{"emiratesIdNumber":784199341496810,"dateOfBirth":"1993-01-30","currentNationality":"united_arab_emirates","issueDate":"2022-12-21","expiryDate":"2024-12-20","eidCardNumber":"126190008"}}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        Contact con = [SELECT Id,NationalIdNumber__c,Birthdate,Nationality__c from Contact where AgentStatus__c = 'Active' AND NationalIdNumber__c != '' Limit 1];
        
        
        BatchToEmiratesIdValidation  bat = new BatchToEmiratesIdValidation();
        database.executeBatch(bat,1);
        Test.stopTest();
        
    }
    @isTest
    static void testEmiratesIDValidationFuture() {
        
        Test.startTest();
        String responseBody = '{"result":{"emiratesIdNumber":784199341496810,"dateOfBirth":"1993-01-30","currentNationality":"united_arab_emirates","issueDate":"2022-12-21","expiryDate":"2024-12-20","eidCardNumber":"126190008"}}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        Contact con = [SELECT Id,NationalIdNumber__c,Birthdate,Nationality__c from Contact where AgentStatus__c = 'Active' AND NationalIdNumber__c != '' Limit 1];
        EmiratesIdValidationController.makeCalloutFuture(new Set<Id>{con.Id});
        Test.stopTest();
        
    }
}