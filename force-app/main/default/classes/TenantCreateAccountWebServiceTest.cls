@isTest
private class TenantCreateAccountWebServiceTest {
    
    @testSetUp
    static void dataSetUp() {
        
        Trigger_Enabler__c triggerEnabler = new Trigger_Enabler__c();
        triggerEnabler.Name = 'Asset';
        triggerEnabler.Is_After_Update__c =false;
        triggerEnabler.Is_After_Insert__c =false;
        triggerEnabler.Is_After_Delete__c = false;
        triggerEnabler.Is_Before_Delete__c = false;
        triggerEnabler.Is_Before_Insert__c = false;
        triggerEnabler.Is_Before_Update__c = false;
        insert triggerEnabler;
       
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org1', 'G1234567');
        insert acc1;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc1.Id);
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT; 
        insert SRTemplateDetailRecord3;
        
        /*HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, 'Aldar Estates Move-In', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'AldarEstatesMoveIn'), SRTemplateDetailRecord3.Id);
newSR1.SalesOrder__c = salesOrder.Id;        
newSR1.Unit__c = unit.Id;        
newSR1.IsComplianceReturned__c =false;
newSR1.Compliance_Status__c = 'Cleared';
newSR1.TransferSellingPrice__c= 1000000;
newSR1.HexaBPM__Email__c = 'test@test.com';        
insert newSR1;
newSR1.Compliance_Status__c = 'Cleared';
newSR1.IsComplianceReturned__c = true;        
update newSR1;*/
        
        HexaBPM__Service_Request__c newSR1 = new HexaBPM__Service_Request__c();
        
        newSR1.Unit__c = unit.Id;
        newSR1.HexaBPM__External_SR_Status__c =  draft.Id;
        newSR1.HexaBPM__Internal_SR_Status__c =  draft.Id;
        
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true;
        insert newSR1;
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = false;
        
        
        Asset ecssUnit = TestObjectsFactory.getECSSUnitDetail(unit.Project__c,unit.BuildingSectionName__c);
        ecssUnit.Unit__c = unit.Id;
        ecssUnit.Name = 'xyz';
        insert ecssUnit;
        
        Case newCase = new Case();
       newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(String.valueOf('ECSS Query')).getRecordTypeId();
        newCase.CustomerType__c = 'Tenant';
        newCase.ECSS_CompanyOptions__C = 'Provis';
        newCase.SubVertical__c = 'Provis';
        newCase.CaseCategory__c = 'Tenant Onboarding';
        newCase.Origin = 'Customer Portal';
        newCase.AccountId = acc.Id;
        newCase.Unit__c = unit.Id;
        newCase.SalesOrder__c = salesOrder.Id;
        newCase.Status =Constants.CASE_IN_PROGRESS;
        newCase.AssetId =ecssUnit.Id;
        newCase.Tenant_Contact__c =con.Id;
        newCase.ECSS_Created_From_Component__c = true;
        newCase.ServiceCloudCaseNumber__c = 'test';
        CaseTriggerHandler.isSkipCaseTrigger = true;
        insert newCase;
        system.debug('newCase-->'+newCase);
        CaseTriggerHandler.isSkipCaseTrigger = false;
       
        
        /*Id personAccountRecordTypeId = Utilities.getRecordTypeId('Account', 'Person Account');
Account acc = new Account(
FirstName = 'Test',
LastName = 'Agni',
PersonEmail = 'agniMoveOut@gmail.com',
RecordTypeId = personAccountRecordTypeId,
CustomerAppWebUser__c = false
);
insert acc;

Project__c project = TestObjectsFactory.getProjectRecord('recordId');
project.OA_Community_Name__c = 'Al Raha Beach';
insert project;

Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
unit.Status__c = 'Sold';
unit.Name = 'MAYAN-B2-2004';
unit.Project__c = project.Id;
insert unit;

Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
opp.OwnerManger__c = UserInfo.getUserId();
insert opp;

SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
salesOrder.Unit__c = unit.Id;
salesOrder.IsBookingCompleted__c = true;
salesOrder.NetAmount__c = 100000;
salesOrder.SellingPrice__c=1000000;
insert salesOrder;*/
        
    }
    
    @isTest
    static void testCreatetenantAccount() {
        
        Case newCase = [Select Id,SalesOrder__c,Unit__c,AssetId,AccountId,ECSS_Contract_Start_Date__c,ECSS_Contract_End_Date__c,Contract_Tawtheeq_Number__c,Tenant_Contact__r.AccountId,Tenant_Contact__r.Email from case limit 1];
        
        system.debug('newCase-->'+newCase);
        
       
        
        
        Map<String, Object> tenantPayload = new Map<String, Object>{
                'operation' => 'create',
                'salesOrderId' => newCase.SalesOrder__c,
                'firstName' => 'Test',
                'lastName' => 'Test',
                'mobileCountryCode' => '91',
                'mobilePhone' => '7736143512',
                'buyerType' => 'Individual',
                'customerId' => newCase.AccountId,
                'unitId' => newCase.Unit__c,
                'email' => 'test12345@mail.com',
                'isDariVerified' => true,
                'annualRent' => '100',
                'depositAmount' => '200',
                'startDate' => Date.valueOf('2025-11-13'),
                'endDate' => Date.valueOf('2025-11-13'),
                'numberofChequesPerYear' => '2',
                'tawtheeqDoc' => 'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0OCIgaGVpZ2h0PSI0OCIgdmlld0JveD0iMCAwIDQ4IDQ4Ij4KPHBhdGggZmlsbD0iI0VBNDMzNSIgZD0iTTI0IDkuNWMzLjU0IDAgNi43MSAxLjIyIDkuMjEgMy42bDYuODUtNi44NUMzNS4xOCAyLjkzIDI5LjkxLjUgMjQgLjVDMTQuODYuNSA2LjkyIDUuOSAyLjkzIDEzLjcybDcuOTYgNi4xOEMxMy4xNCAxMy4yNCAxOC4xOCA5LjUgMjQgOS41eiIvPgo8cGF0aCBmaWxsPSIjNDI4NUY0IiBkPSJNNDYuNSAyNGMwLTEuNjItLjE1LTMuMTgtLjQzLTQuNjlIMjR2OS4zOGgxMi43Yy0uNTUgMi45OC0yLjE4IDUuNTEtNC42NiA3LjIxbDcuNDkgNS44MkM0My44MyAzNy4zNCA0Ni41IDMxLjEyIDQ2LjUgMjR6Ii8+CjxwYXRoIGZpbGw9IiNGQkJDMDUiIGQ9Ik0xMC45IDI4LjA5YTE0LjUgMTQuNSAwIDAxMC04LjE4bC03Ljk2LTYuMThhMjMuNDk4IDIzLjQ5OCAwIDAwMCAyMC41NGw3Ljk2LTYuMTh6Ii8+CjxwYXRoIGZpbGw9IiMzNEE4NTMiIGQ9Ik0yNCA0Ni41YzYuNDggMCAxMS45My0yLjE1IDE1LjkxLTUuODJsLTcuNDktNS44MmMtMi4wOSAxLjQxLTQuNzkgMi4yMy04LjQyIDIuMjMtNS44MiAwLTEwLjg2LTMuNzQtMTIuOTItOS4wMWwtNy45NiA2LjE4QzYuOTIgNDIuMSAxNC44NiA0Ni41IDI0IDQ2LjV6Ii8+Cjwvc3ZnPg=='
                };
                    
                String jsonBody = JSON.serialize(tenantPayload);
        
        // Setup RestRequest and RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/customer/createTenantAccount';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = req;
        RestContext.response = res;

        // Call the method
        Test.startTest();
        TenantCreateAccountWebService.createTenantContract(new set<Id>{newCase.Id});
        TenantCreateAccountWebService.createTenantAccount();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());

        
    }
    
   @isTest
   static void testgettenantAccount() {
        
        Case newCase = [select Id,SalesOrder__c,AccountId,Unit__c from case limit 1];
        
        system.debug('newCase-->'+newCase);
        
       
        
        
        Map<String, Object> tenantPayload = new Map<String, Object>{
                'operation' => 'get',
                'salesOrderId' => newCase.SalesOrder__c,
                'firstName' => 'Test',
                'lastName' => 'Test',
                'mobileCountryCode' => '91',
                'mobilePhone' => '7736143512',
                'buyerType' => 'Individual',
                'customerId' => newCase.AccountId,
                'unitId' => newCase.Unit__c,
                'email' => 'test12345@mail.com',
                'isDariVerified' => true,
                'annualRent' => '100',
                'depositAmount' => '200',
                'startDate' => Date.valueOf('2025-11-13'),
                'endDate' => Date.valueOf('2025-11-13'),
                'numberofChequesPerYear' => '2',
                'tawtheeqDoc' => 'PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0OCIgaGVpZ2h0PSI0OCIgdmlld0JveD0iMCAwIDQ4IDQ4Ij4KPHBhdGggZmlsbD0iI0VBNDMzNSIgZD0iTTI0IDkuNWMzLjU0IDAgNi43MSAxLjIyIDkuMjEgMy42bDYuODUtNi44NUMzNS4xOCAyLjkzIDI5LjkxLjUgMjQgLjVDMTQuODYuNSA2LjkyIDUuOSAyLjkzIDEzLjcybDcuOTYgNi4xOEMxMy4xNCAxMy4yNCAxOC4xOCA5LjUgMjQgOS41eiIvPgo8cGF0aCBmaWxsPSIjNDI4NUY0IiBkPSJNNDYuNSAyNGMwLTEuNjItLjE1LTMuMTgtLjQzLTQuNjlIMjR2OS4zOGgxMi43Yy0uNTUgMi45OC0yLjE4IDUuNTEtNC42NiA3LjIxbDcuNDkgNS44MkM0My44MyAzNy4zNCA0Ni41IDMxLjEyIDQ2LjUgMjR6Ii8+CjxwYXRoIGZpbGw9IiNGQkJDMDUiIGQ9Ik0xMC45IDI4LjA5YTE0LjUgMTQuNSAwIDAxMC04LjE4bC03Ljk2LTYuMThhMjMuNDk4IDIzLjQ5OCAwIDAwMCAyMC41NGw3Ljk2LTYuMTh6Ii8+CjxwYXRoIGZpbGw9IiMzNEE4NTMiIGQ9Ik0yNCA0Ni41YzYuNDggMCAxMS45My0yLjE1IDE1LjkxLTUuODJsLTcuNDktNS44MmMtMi4wOSAxLjQxLTQuNzkgMi4yMy04LjQyIDIuMjMtNS44MiAwLTEwLjg2LTMuNzQtMTIuOTItOS4wMWwtNy45NiA2LjE4QzYuOTIgNDIuMSAxNC44NiA0Ni41IDI0IDQ2LjV6Ii8+Cjwvc3ZnPg=='
                };
                    
                String jsonBody = JSON.serialize(tenantPayload);
        
        // Setup RestRequest and RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/customer/createTenantAccount';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = req;
        RestContext.response = res;

        // Call the method
        Test.startTest();
        //TenantCreateAccountWebService.createTenantContract(new set<Id>{newCase.Id});
        TenantCreateAccountWebService.createTenantAccount();
        Test.stopTest();

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());

        
    }
    
    @isTest
    static void testgettenantSelfAccount() {
        
        Case newCase = [select Id,SalesOrder__c,AccountId,Unit__c from case limit 1];
        
        system.debug('newCase-->'+newCase);
        
        
        
        
        Map<String, Object> tenantPayload = new Map<String, Object>{
            'operation' => 'create',
                'salesOrderId' => '',
                'firstName' => 'Test',
                'lastName' => 'Test',
                'mobileCountryCode' => '91',
                'mobilePhone' => '7736143512',
                'buyerType' => 'Individual',
                'customerId' => '',
                'unitId' => '',
                'email' => 'test12345@mail.com',
                'isDariVerified' => true,
                'annualRent' => '100',
                'depositAmount' => '200',
                'startDate' => Date.valueOf('2025-11-13'),
                'endDate' => Date.valueOf('2025-11-13'),
                'numberofChequesPerYear' => '2',
                'ADMBuildingNumber' => 'Test',
                'ADMPlotNumber'=> 'Test',
                'ADMUnitNumber'=> 'Test1',
                'projectId'=>'a22FW00000079ldYAA',
                'projectName'=>'Meera',
                'projectCode'=> 'MERA',   
                'tawtheeqDoc' => ''
                };
                    
                    String jsonBody = JSON.serialize(tenantPayload);
        
        // Setup RestRequest and RestContext
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestUri = '/services/apexrest/customer/createTenantAccount';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        //TenantCreateAccountWebService.createTenantContract(new set<Id>{newCase.Id});
        TenantCreateAccountWebService.createTenantAccount();
        //TenantCreateAccountWebService.TenantCaseCreationResponse responseTenant= new TenantCreateAccountWebService.TenantCaseCreationResponse();
        TenantCreateAccountWebService.getCaseDetails(new List<Case>{newCase});
        Test.stopTest();
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        
        
    }
    
    
}