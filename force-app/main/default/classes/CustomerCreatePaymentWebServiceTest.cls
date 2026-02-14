@isTest
public class CustomerCreatePaymentWebServiceTest {

	/*@testSetUp
    static void createTestData(){
	 String query = 'SELECT Id, Name, CurrencyIsoCode, CustomerName__c, Amount__c, ProjectName__c, UnitNumber__c, Status__c, AuthenticationId__c, AuthenticationReferenceNumber__c, ';
        query += ' Account__r.PersonEmail, Account__r.PersonMobilePhone, Account__r.BillingStreet, Account__r.BillingCity, Account__r.BillingState, Account__r.BillingStateCode, Account__r.BillingPostalCode, Account__r.BillingCountry, Account__r.BillingCountryCode, ';
        query += ' Contact__r.Salutation, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email, Contact__r.MobilePhone, Contact__r.MobilePhone__c, Contact__r.MobileCountryCode__c, Contact__r.CountryOfResidence__c, Contact__r.Nationality__c, Contact__r.PassportNumber__c, Contact__r.PassportExpiryDate__c ';
        query += ' FROM ReceiptAcknowledgement__c ' + (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '');	
	}*/
	@isTest
    static void createPayment(){
        Account acc = new Account();
        acc.firstName ='test';
        acc.LastName ='test';
        acc.PersonEmail ='vasudha24@yopmail.com';
        insert acc;
          Id personAccountRecordTypeId=utilities.getRecordTypeId('Account','Person Account');
        Account customerAcc = new Account();
        customerAcc.FirstName='Test';
        customerAcc.LastName= 'Agni';
        customerAcc.PersonEmail='agni@gmail.com';
        customerAcc.RecordTypeId = personAccountRecordTypeId;
        insert customerAcc;

        Account buyerAcc = new Account();
        buyerAcc.FirstName='Test';
        buyerAcc.LastName= 'Drogo';
        buyerAcc.PersonEmail='drogo@gmail.com';
        buyerAcc.RecordTypeId = personAccountRecordTypeId;
        buyerAcc.FastTrackedAccount__c = true;
        insert buyerAcc;

        HexaBPM__SR_Status__c submittedStatus = new HexaBPM__SR_Status__c();
        submittedStatus=TestObjectsFactory.getSRStatus('Submitted');
        insert submittedStatus;

        HexaBPM__SR_Status__c cancelledStatus = new HexaBPM__SR_Status__c();
        cancelledStatus=TestObjectsFactory.getSRStatus('Cancelled');
        insert cancelledStatus;

        Project__c project=TestObjectsFactory.getProjectRecord('recordId');
        insert project;

        list<Unit__c> units = new list<unit__c>();
        unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004'; 
        unit.Project__c= project.Id;
        insert unit;

        Id PropertyTransferNOCRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC');

        HexaBPM__SR_Template__c PTNSRTemplate = new HexaBPM__SR_Template__c();
        PTNSRTemplate.HexaBPM__Active__c = true;
        PTNSRTemplate.HexaBPM__SR_RecordType_API_Name__c = 'Property Transfer NOC';
        insert PTNSRTemplate;
        
       
        HexaBPM__Service_Request__c srExists=TestObjectsFactory.getServiceRequest(submittedStatus.Id,unit.Id,'Property Transfer NOC',PropertyTransferNOCRTId,PTNSRTemplate.Id);
        srExists.TransferSellingPrice__c=19500.01;
        srExists.HexaBPM__Customer__c=customerAcc.Id;
        srExists.BuyerName__c = buyerAcc.Id;
        srExists.BuyerEmail__c = buyerAcc.PersonEmail;
        srExists.Retrive_Buyer_Acc_Docs__c= true;
        srExists.RecordTypeId = PropertyTransferNOCRTId;
        srExists.Origin__c = 'Customer Portal'; 
        insert srExists;
		String inputPayload = '{' +
    '"statusCode": 200,' +
    '"statusMessage": "success",' +
    '"data": {' +
        '"id": "pi_3QPPVRG3py9xttDl0mmq4AZj",' +
        '"object": "payment_intent",' +
        '"amount": 1001,' +
        '"amount_capturable": 0,' +
        '"amount_details": {' +
            '"tip": {}' +
        '},' +
        '"amount_received": 0,' +
        '"application": null,' +
        '"application_fee_amount": null,' +
        '"automatic_payment_methods": {' +
            '"allow_redirects": "never",' +
            '"enabled": true' +
        '},' +
        '"canceled_at": null,' +
        '"cancellation_reason": null,' +
        '"capture_method": "automatic_async",' +
        '"client_secret": "pi_3QPPVRG3py9xttDl0mmq4AZj_secret_1P9DrveOCGRVFerR7tjG4gCFh",' +
        '"confirmation_method": "automatic",' +
        '"created": 1732630365,' +
        '"currency": "aed",' +
        '"customer": "cus_RHzU0jmeSYHMO8",' +
        '"description": null,' +
        '"invoice": null,' +
        '"last_payment_error": null,' +
        '"latest_charge": null,' +
        '"livemode": false,' +
        '"metadata": {' +
            '"salesforceFee": 213123,' +
            '"buyerId": "'+acc.Id+'",' +
            '"customerEmail": "vasudha24@yopmail.com",' +
            '"orderTransactionId": "noc_test_unit_id_seller_id1732630363",' +
            '"payerId": "'+acc.Id+'",' +
            '"salesforceRequestId":"'+srExists.id+'",' +
            '"sellerId": "'+acc.Id+'",' +
            '"splits": [{"connectedAccountId":"acct_1QCfXGGyxCToA9Gs","amount":700}],' +
            '"unitId": "qweqweqwe"' +
        '},' +
        '"next_action": null,' +
        '"on_behalf_of": null,' +
        '"payment_method": null,' +
        '"payment_method_configuration_details": {' +
            '"id": "pmc_1QL6qpG3py9xttDl5oQV3Ptc",' +
            '"parent": null' +
        '},' +
        '"payment_method_options": {' +
            '"card": {' +
                '"installments": null,' +
                '"mandate_options": null,' +
                '"network": null,' +
                '"request_three_d_secure": "automatic"' +
            '},' +
            '"link": {' +
                '"persistent_token": null' +
            '}' +
        '},' +
        '"payment_method_types": [' +
            '"card",' +
            '"link"' +
        '],' +
        '"processing": null,' +
        '"receipt_email": null,' +
        '"review": null,' +
        '"setup_future_usage": null,' +
        '"shipping": null,' +
        '"source": null,' +
        '"statement_descriptor": null,' +
        '"statement_descriptor_suffix": null,' +
        '"status": "requires_payment_method",' +
        '"transfer_data": null,' +
        '"transfer_group": "tg_noc_test_unit_id_seller_id1732630363"' +
    '}' +
'}';

		Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/createstripepayment';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
        CustomerCreatePaymentWebService.doPost();
        Test.stopTest();
	}
	@isTest
    static void catchException(){
		string inputPayload='makejsonexceptionhere';
		Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/createstripepayment';
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueof(inputPayload);
        RestContext.request = req;
        RestContext.response = res;
        CustomerCreatePaymentWebService.doPost();
        Test.stopTest();
    }

}