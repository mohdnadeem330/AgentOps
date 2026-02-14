@isTest
public class LeadRestServicesTest {
   @testSetup
    static void setupTestData() {
      Account acc = TestObjectsFactory.getAgencyAccountRecord('Upendra', '98976');
        acc.AgencyCategory__c = 'Broker';
        acc.AgencySubCategory__c = 'LSQ broker';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.ReferralType__c = Constants.OPPORTUINTY_REFERRAL_STAFF;
        insert opp;
Project__c projectRecord = new Project__c();
        projectRecord.DigitalSignatureApplied__c = true;
        projectRecord.Country__c = 'United Kingdom';
        projectRecord.Name = 'Mayan';
        projectRecord.ProjectCode__c = 'MAYAN';
        projectRecord.CommunityName__c = 'Mayan';
        projectRecord.CommunityNameArabic__c = 'المايا';
        projectRecord.BusinessUnitId__c = '749';
        projectRecord.City__c = 'London';
        projectRecord.CurrencyIsoCode = 'AED';
        projectRecord.StartDate__c = Date.today().addDays(-1);
        projectRecord.EndDate__c = Date.today().addMonths(5);
        projectRecord.ReservationAmount__c = 25000;
        projectRecord.BankNameEscrow__c = 'Abu Dhabi Commercial Bank';
        insert projectRecord;

        Lead leadObj = TestObjectsFactory.getLeadRecord(1, 'Person');
        leadObj.CustomerSubType__c = 'CORPORATE';
        leadObj.BrokerAgency__c = acc.Id;
        leadObj.Date_of_Birth__c = System.today().addMonths(-1234);
        insert leadObj;
    }

    private static Lead createTestLead(String leadSource, String enquiryTrigger) {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Lead testLead = new Lead();
        testLead.FirstName = 'Dipu';
        testLead.LastName = 'Paul';
        testLead.Company = 'Test Company';
        testLead.LeadSource = leadSource;
        testLead.EnquiryCategory__c = 'Aldar Websites';
        testLead.EnquiryTrigger__c = enquiryTrigger;
        testLead.Project__c = 'Mayan';
        testLead.BrokerAgency__c = acc.Id;
        return testLead;
    }

    private static LeadRestServices.ResponseWrapper sendLeadRequest(Lead lead) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/leadRestService';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(lead));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        LeadRestServices.ResponseWrapper response = LeadRestServices.createLead();
        Test.stopTest();
        return response;
    }

    @isTest
    static void testCreateLead_Success_BrokerPortal() {
        LeadRestServices.ResponseWrapper response = sendLeadRequest(createTestLead('Broker Portal', 'Damascus'));
       
    }

    @isTest
    static void testCreateLead_Success_NonBroker() {
        LeadRestServices.ResponseWrapper response = sendLeadRequest(createTestLead('Online', 'Aldar Apps'));
       
    }

  

    @isTest
    static void testCreateLead_RestrictedPicklistError() {
        Lead testLead = createTestLead('Broker Portal', 'Damascus');
        testLead.EnquiryCategory__c = 'InvalidPicklistValue';
        LeadRestServices.ResponseWrapper response = sendLeadRequest(testLead);
        System.assert(!response.success, 'Picklist error should be caught.');
    }

   

    @isTest
    static void testCreateLead_InvalidJson() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/leadRestService';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('Invalid JSON'); // Sending invalid JSON data
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        LeadRestServices.ResponseWrapper response = LeadRestServices.createLead();
        Test.stopTest();
        
        System.assert(!response.success, 'Invalid JSON should be handled.');
    }
}