@isTest
public class BP_BrokerAgencyRegistrationTest {

    @testSetup
    static void setupTestData() {
        // Create necessary data for the test
        RecordType brokerAgentRecordType = [
            SELECT Id FROM RecordType WHERE DeveloperName = 'BrokerAgent' AND SObjectType = 'Contact' LIMIT 1
        ];

        Account acc= TestObjectsFactory.getOrganisationAccountRecord('Test Org 1', 'G1234561234');
        insert acc;

        Contact brokerAgent = new Contact(
            LastName = 'Test Broker Agent',
            AccountId = acc.Id,
            RecordTypeId = brokerAgentRecordType.Id,
            Email = 'testbrokeragent@example.com',
            MobilePhone = '1234567890'
        );
        insert brokerAgent;
    }

    @isTest
    static void testStartWithValidRequestBody() {
    
        HexaBPM__SR_Status__c Submitted2 = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted2; 
        
        // Prepare a valid request body
        BP_BrokerAgencyRegistration.AgencyRegistrationWrapper wrapper = new BP_BrokerAgencyRegistration.AgencyRegistrationWrapper();
        wrapper.type = 'NEW_REGISTRATION';
        wrapper.serviceRequest = new HexaBPM__Service_Request__c(
            TradeCommercialLicenseNumber__c = '12345',
            Country__c = 'United Arab Emirates'
        );
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord3;
        
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;
        
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, '', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Agency Registration'), SRTemplateDetailRecord3.Id);
        newSR1.SalesOrder__c = salesOrder.Id;        
        newSR1.Unit__c = unit.Id;  
        newSR1.IsComplianceReturned__c = false;
        newSR1.Compliance_Status__c = '';
        newSR1.TransferSellingPrice__c= 1000000;
        newSR1.Country__c = 'United Arab Emirates';
        insert newSR1;
        
        wrapper.agencyAdmin = new AgencyTeam__c(
            EmailAddress__c = 'admin@example.com',
            MobileNumber__c = '9876543210'
        );
        wrapper.partnerOwners = new List<BP_BrokerAgencyRegistration.PartnerOwnerWrapper>();

        BP_BrokerAgencyRegistration.PartnerOwnerWrapper partner = new BP_BrokerAgencyRegistration.PartnerOwnerWrapper();
        partner.partnerOwner = new AgencyTeam__c(
            EmailAddress__c = 'partner@example.com',
            MobileNumber__c = '1234509876'
        );
        //partner.Emirates_ID_Passport_copy = 'base64encodeddata';
        wrapper.partnerOwners.add(partner);

        String requestBody = JSON.serialize(wrapper);
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        RestContext.request.requestBody = Blob.valueOf(requestBody);
        RestContext.request.params.put('key', 'value');

        // Call the start method
        Test.startTest();
        BP_BrokerAgencyRegistration.start();
        Test.stopTest();

        // Assert response
        RestResponse response = RestContext.response;
        //System.assertEquals(200, response.statusCode);
        //System.assert(response.responseBody != null);
    }

    @isTest
    static void testStartWithInvalidRequestBody() {
        // Prepare an invalid request body
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        RestContext.request.requestBody = Blob.valueOf(''); // Empty body

        // Call the start method
        Test.startTest();
        BP_BrokerAgencyRegistration.start();
        Test.stopTest();

        // Assert response
        RestResponse response = RestContext.response;
        //System.assertEquals(500, response.statusCode);
        //System.assert(response.responseBody.toString().contains('Invalid Request Body'));
    }

    @isTest
    static void testValidationBeforeSubmit() {
        BP_BrokerAgencyRegistration.AgencyRegistrationWrapper wrapper = new BP_BrokerAgencyRegistration.AgencyRegistrationWrapper();
        wrapper.serviceRequest = new HexaBPM__Service_Request__c(
            TradeCommercialLicenseNumber__c = '12345'
        );
        wrapper.agencyAdmin = new AgencyTeam__c(
            EmailAddress__c = 'existingemail@example.com',
            MobileNumber__c = '9876543210'
        );

        Test.startTest();
        BP_BrokerAgencyRegistration.ValidationWrapper validationResult = BP_BrokerAgencyRegistration.validationBeforeSubmit(wrapper);
        Test.stopTest();

        //System.assert(!validationResult.isSuccess);
        //System.assert(validationResult.message.contains('There is Already Agency Admin with This Trade License number.'));
    }

    @isTest
    static void testProcessRequest() {
        BP_BrokerAgencyRegistration service = new BP_BrokerAgencyRegistration();
        Map<String, String> params = new Map<String, String>{ 'key' => 'value' };

        BP_BrokerAgencyRegistration.AgencyRegistrationWrapper wrapper = new BP_BrokerAgencyRegistration.AgencyRegistrationWrapper();
        wrapper.type = 'RESEND_OTP';
        // wrapper.sObjectId = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1].Id;
        wrapper.serviceRequest = new HexaBPM__Service_Request__c(
            TradeCommercialLicenseNumber__c = '12345'
            //,
            //Name = 'Test Request'
        );
        wrapper.agencyAdmin = new AgencyTeam__c(
            EmailAddress__c = 'admin@example.com',
            MobileNumber__c = '9876543210'
        );

        String requestBody = JSON.serialize(wrapper);

        Test.startTest();
        service.processRequest(params, requestBody);
        Test.stopTest();

        //System.assert(response.success);
        //System.assertEquals(200, response.statusCode);
        //System.assertEquals('Broker Agency Created Successfully ', response.message);
    }
}