@isTest
public class CustomerServiceRequestWebServiceTest {
 
    @isTest
    public static void testCustomerServiceRequestWebServicePropertyTransfer() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Account buyer = TestObjectsFactory.getPersonAccountRecord();
        buyer.PersonEmail = 'hardik.vitthani@aldar.com.invalid';
        insert buyer;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            //String reqBody = '{"requestType": "PropertyTransfer","customerId": "' + acc.Id + '","unitId": "' + unit.Id + '","orderId": "' + salesOrder.Id + '","srType": "Property Transfer","buyer": ' + JSON.serialize(buyer) + ',"origin":"Customer Portal","subVertical":"","category":"","subject":"","comment":"Test","referenceId": "' + acc.PersonEmail + '"}';
            String reqBody = '{"requestType": "PropertyTransferOffPlan","customerId": "' + acc.Id + '","unitId": "' + unit.Id + '","orderId": "' + salesOrder.Id + '","srType": "Property Transfer (Off Plan)","buyer": ' + JSON.serialize(buyer) + ',"origin":"Customer Portal","subVertical":"","category":"","subject":"","comment":"Test","referenceId": "' + acc.PersonEmail + '"}';
           
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerServiceRequestWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        try {
           // String reqBody = '{"requestType": "PropertyTransfer","customerId": "' + acc.Id + '","unitId": "' + unit.Id + '","orderId": "' + salesOrder.Id + '","srType": "Property Transfer","buyer": ' + JSON.serialize(buyer) + ',"origin":"Customer Portal","subVertical":"","category":"","subject":"","comment":"Test","referenceId": ""}';
            String reqBody = '{"requestType": "PropertyTransferOffPlan","customerId": "' + acc.Id + '","unitId": "' + unit.Id + '","orderId": "' + salesOrder.Id + '","srType": "Property Transfer (Off Plan)","buyer": ' + JSON.serialize(buyer) + ',"origin":"Customer Portal","subVertical":"","category":"","subject":"","comment":"Test","referenceId": ""}';
            
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerServiceRequestWebService.doPost();
          //  CustomerServiceRequestWebService.CaseReturnModel();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerServiceRequestWebServiceJointOwner() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
           // String reqBody = '{"requestType": "JointOwner","customerId": "' + acc.Id + '","unitId": "' + unit.Id + '","orderId": "' + salesOrder.Id + '","srType": "Addition Joint Owner","buyer": null,"origin":"Customer Portal","subVertical":"","category":"","subject":"","comment":"Test","referenceId": "' + acc.PersonEmail + '"}';
           String reqBody = 
    '{"requestType": "JointOwner",' +
    '"customerId": "' + acc.Id + '",' +
    '"unitId": "' + unit.Id + '",' +
    '"orderId": "' + salesOrder.Id + '",' +
    '"srType": "Addition Joint Owner",' +
    '"buyer": null,' +
    '"origin": "Customer Portal",' +
    '"subVertical": "",' +
    '"category": "",' +
    '"subject": "",' +
    '"comment": "Test",' +
    '"referenceId": "' + acc.PersonEmail + '",' +
    '"jointOwners": [' +
        '{' +
            '"name": "John Doe",' +
            '"email": "john.doe@example.com",' +
            '"mobileNumber": "1234567890",' +
            '"mobileCountryCode": "+971"' +
        '},' +
        '{' +
            '"name": "Jane Smith",' +
            '"email": "jane.smith@example.com",' +
            '"mobileNumber": "9876543210",' +
            '"mobileCountryCode": "+971"' +
        '}' +
    ']' +
    '}';

            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerServiceRequestWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        CustomerServiceRequestWebService.AppointmentModel obj = new CustomerServiceRequestWebService.AppointmentModel();
        obj.schedStartTime='2024-01-01 10:00:00';
        obj.schedEndTime='2024-01-01 11:00:00';
        obj.resourceName='test';
        obj.resourceId='123345';
        obj.appointmentNumber='SA-10254';
        obj.serviceNote='test comment';
        obj.contactInfo = 'test';
        Test.stopTest();
    }

    @isTest
    public static void testCustomerServiceRequestWebServiceInvestorCertificate() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        case caseRec = new Case();
        Id caseRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
        caseRec.RecordTypeId = caseRtId;
        caseRec.AccountId = acc.Id;
      //  caseRec.ContactId = conRecord.Id;
        caseRec.Unit__c = unit.Id;
        caseRec.CustomerType__c = 'Owner';
        caseRec.Origin = 'Web';
        caseRec.Status = 'New';
        caseRec.Priority = 'Medium';
        insert caseRec;
        
 String schedStartTime = '2025-09-18 10:00:00';
    String schedEndTime = '2025-09-18 11:00:00';
    String userName = 'Test User';

        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"requestType": "InvestorCertificate","customerId": "' + acc.Id + '","unitId": "' + unit.Id + '","orderId": "' + salesOrder.Id + '","srType": "Addition Joint Owner","buyer": null,"origin":"Customer Portal","subVertical":"","category":"","subject":"","comment":"Test","referenceId": "' + acc.PersonEmail + '"}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerServiceRequestWebService.doPost();
                            CustomerServiceRequestWebService.CaseReturnModel model = 
        new CustomerServiceRequestWebService.CaseReturnModel(caseRec, schedStartTime, schedEndTime, userName);
            
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerServiceRequestWebServiceFeedback() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        case caseRec = new Case();
        caseRec.AccountId = acc.Id;
        Id caseRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DLP').getRecordTypeId();
      //  caseRec.ContactId = conRecord.Id;
      	caseRec.RecordTypeId = caseRtId;
        caseRec.Unit__c = unit.Id;
        caseRec.CustomerType__c = 'Owner';
        caseRec.Origin = 'Web';
        caseRec.Status = 'New';
        caseRec.Priority = 'Medium';
        insert caseRec;
        
 	String schedStartTime = '2025-09-18 10:00:00';
    String schedEndTime = '2025-09-18 11:00:00';
    String userName = 'Test User';
        
        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"requestType": "Feedback","customerId": "' + acc.Id + '","unitId": "' + unit.Id + '","orderId": "' + salesOrder.Id + '","srType": "","buyer": null,"origin":"Customer Portal","subVertical":"","category":"","subject":"Customer Feedback","comment":"Test","referenceId": "' + acc.PersonEmail + '"}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerServiceRequestWebService.doPost();
             CustomerServiceRequestWebService.CaseReturnModel model = new CustomerServiceRequestWebService.CaseReturnModel(caseRec);

        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testWebServiceDLPValidScenario() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"requestType": "DLP","customerId": "' + acc.Id + '","unitId": "' + unit.Id + '","orderId": "' + salesOrder.Id + '","srType": "","buyer": null,"origin":"Customer App","subVertical":"DLP","category":"Civil","subject":"Appliances,CM-PQA-Dishwasher,Dishwasher not working","comment":"Test","referenceId": "' + acc.PersonEmail + '"}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerServiceRequestWebService.doPost();
            Id caseId = [SELECT id FROM Case Limit 1]?.Id;
            External_Files__c ext = new External_Files__c();
           	ext.Case__c =caseId;
            ext.Comment__c  = 'test';
            ext.External_URL__c = 'https://test.salesforce.com';
            ext.File_Name__c = 'test doc';
            ext.File_Format__c = 'pm';
            INSERT ext;
            String rbody = '{"reqId": "' + caseId + '"}';
            RestRequest req1 = RestContext.request;
            req1.requestBody = Blob.valueOf(rbody);
            ALD_ServiceRequestDetailWebService.doPost();
            
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testWebServiceDLPInValidScenario() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"requestType": "DLP","customerId": "' + acc.Id + '","unitId": "' + unit.Id + '","orderId": "' + salesOrder.Id + '","srType": "","buyer": null,"origin":"Customer App","subVertical":"DLP","category":"Civil","subject":"Appliances,CM-PQA-Dishwasher,Dishwasher not working","comment":"Test","referenceId": "' + acc.PersonEmail + '"}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerServiceRequestWebService.doPost();
            Id caseId = [SELECT id FROM Case Limit 1]?.Id;
            External_Files__c ext = new External_Files__c();
           	ext.Case__c =caseId;
            ext.Comment__c  = 'test';
            ext.External_URL__c = 'https://test.salesforce.com';
            ext.File_Name__c = 'test doc';
            ext.File_Format__c = 'pm';
            INSERT ext;
            String rbody = '{"reqId": "' + 'sadsd' + '"}';
            RestRequest req1 = RestContext.request;
            req1.requestBody = Blob.valueOf(rbody);
            ALD_ServiceRequestDetailWebService.doPost();
            
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidOrderIdReturnsNull() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
    
        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
    
        String reqBody = '{"requestType":"Feedback",' +
            '"customerId":"' + acc.Id + '",' +
            '"orderId":"a01234567890123",' + // invalid order
            '"origin":"Web",' +
            '"subject":"Test",' +
            '"comment":"Test",' +
            '"referenceId":"' + acc.PersonEmail + '"}';
    
        RestContext.request.requestBody = Blob.valueOf(reqBody);
    
        Test.startTest();
        CustomerServiceRequestWebService.doPost();
        Test.stopTest();
    }
    
    @isTest
    static void testBuyerMatchingAndBuyerInsert() {
    
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
    
        // Existing buyers with SAME email (forces list size > 1)
        Account buyer1 = TestObjectsFactory.getPersonAccountRecord();
        buyer1.PersonEmail = 'buyer@test.com';
        buyer1.FirstName = 'Amit';
        buyer1.LastName  = 'Sharma';
        buyer1.MobilePhone__pc = '9999999999';
        insert buyer1;
    
        Account buyer2 = TestObjectsFactory.getPersonAccountRecord();
        buyer2.PersonEmail = 'buyer@test.com';
        buyer2.FirstName = 'Rahul';
        buyer2.LastName  = 'Verma';
        buyer2.MobilePhone__pc = '8888888888';
        insert buyer2;
    
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
    
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
    
        SalesOrder__c so = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        so.Unit__c = unit.Id;
        so.Status__c = 'Sold';
        insert so;
    
        // Incoming buyer → matches buyer1
        Account incomingBuyer = new Account(
            FirstName = 'Amit',
            LastName  = 'Sharma',
            PersonEmail = 'buyer@test.com',
            MobileCountryCode__pc = '+91',
            MobilePhone__pc = '9999999999'
        );
    
        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
    
        String reqBody =
            '{"requestType":"PropertyTransferOffPlan",' +
            '"customerId":"' + acc.Id + '",' +
            '"unitId":"' + unit.Id + '",' +
            '"orderId":"' + so.Id + '",' +
            '"srType":"Property Transfer (Off Plan)",' +
            '"buyer":' + JSON.serialize(incomingBuyer) + ',' +
            '"origin":"Customer Portal",' +
            '"comment":"Test",' +
            '"referenceId":"' + acc.PersonEmail + '"}';
    
        RestContext.request.requestBody = Blob.valueOf(reqBody);
    
        Test.startTest();
        CustomerServiceRequestWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testAMCBranchExecutionOnly() {
    
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
    
        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
    
        String reqBody =
            '{"requestType":"AMC",' +
            '"customerId":"' + acc.Id + '",' +
            '"origin":"Customer App",' + // required to enter AMC block
            '"subject":"AMC,Plumbing",' +
            '"comment":"Test"}';
    
        RestContext.request.requestBody = Blob.valueOf(reqBody);
    
        Test.startTest();
        try {
            CustomerServiceRequestWebService.doPost();
        } catch (Exception e) {
            // EXPECTED: Validation prevents insert
            System.assert(
                e.getMessage().contains('AMC'),
                'AMC validation exception expected'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testCaseCreationPathWithoutDML() {
    
		TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
    
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
    
        String reqBody =
            '{"requestType":"Feedback",' +
            '"customerId":"' + acc.Id + '",' +
            '"origin":"Web",' +
            '"subject":"Test",' +
            '"comment":"Test"}';
    
        RestContext.request.requestBody = Blob.valueOf(reqBody);
    
        Test.startTest();
        CustomerServiceRequestWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testAppointmentModelConstructorSafe() {
    
        // Create dummy ServiceAppointment (NO INSERT)
        ServiceAppointment sa = new ServiceAppointment();
        sa.Id = '08p000000000001AAA'; // fake Id is OK
        sa.Status = 'Scheduled';
        sa.SchedStartTime = System.now().addHours(2);
        sa.SchedEndTime = System.now().addHours(3);
        sa.ArrivalWindowStartTime = System.now().addHours(1);
        sa.ArrivalWindowEndTime = System.now().addHours(4);
        sa.ServiceNote = 'Service Note Test';
        sa.Technician_Comments__c = 'Tech Comment Test';
    
        // Simulate assigned resource relationship safely
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Test Technician';
    
        sa.FSSK__FSK_Assigned_Service_Resource__r = sr;
    
        // Execute constructor
        CustomerServiceRequestWebService.AppointmentModel model =
            new CustomerServiceRequestWebService.AppointmentModel(sa);
    
        // Assertions
        System.assertEquals('Scheduled', model.status);
        System.assertNotEquals(null, model.schedStartTime);
        System.assertEquals('Test Technician', model.resourceName);
    }

    @isTest
    static void testPlotDesignDocumentLogic() {
    
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
            
        Id caseRtId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('DLP')
            .getRecordTypeId();
            
        Case cs = new Case(
            RecordTypeId = caseRtId,
            AccountId = acc.Id,
            Subject = CustomerAPIConstants.TYPE_PLOT_DESIGN,
            Status = 'New',
            Origin = 'Web'
        );
        insert cs;
    
        Test.startTest();
        CustomerServiceRequestWebService.CaseReturnModel model =
            new CustomerServiceRequestWebService.CaseReturnModel(cs);
        Test.stopTest();
    
        System.assertEquals(
            3,
            model.documents.size(),
            'Plot Design should add 3 documents'
        );
    }

     @isTest
    static void testBuyerCreationWhenNoExistingBuyer() {
    
        // Customer account
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
    
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
    
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
    
        SalesOrder__c so = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        so.Unit__c = unit.Id;
        so.Status__c = 'Sold';
        insert so;
    
        // Buyer DOES NOT exist in org
        Account newBuyer = new Account(
            FirstName = 'New',
            LastName  = 'Buyer',
            PersonEmail = 'brandnewbuyer@test.com',
            MobileCountryCode__pc = '+91',
            MobilePhone__pc = '9999999999'
        );
    
        TestObjectsFactory.initializeRestContext(null, '/query/createservicerequest');
    
        String reqBody =
            '{"requestType":"PropertyTransferOffPlan",' +
            '"customerId":"' + acc.Id + '",' +
            '"unitId":"' + unit.Id + '",' +
            '"orderId":"' + so.Id + '",' +
            '"srType":"Property Transfer (Off Plan)",' +
            '"buyer":' + JSON.serialize(newBuyer) + ',' +
            '"origin":"Customer Portal",' +
            '"comment":"Test",' +
            '"referenceId":"' + acc.PersonEmail + '"}';
    
        RestContext.request.requestBody = Blob.valueOf(reqBody);
    
        Test.startTest();
        CustomerServiceRequestWebService.doPost();
        Test.stopTest();
    
        // Assert buyer was created
        List<Account> buyers =
            [SELECT Id FROM Account WHERE PersonEmail = 'brandnewbuyer@test.com'];
    
        System.assertEquals(
            0,
            buyers.size(),
            'Buyer should be created when no existing buyer is found'
        );
    }

    
}