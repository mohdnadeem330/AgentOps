@isTest
public class ProvisOutstandingDuesControllerTest {
    @testSetup
    static void makeData(){
        Id personAccountRecordTypeId = utilities.getRecordTypeId('Account','Person Account');
        
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'Agni';
        acc.PersonEmail = 'agni@gmail.com';
        acc.RecordTypeId = personAccountRecordTypeId;
        acc.CustomerAppWebUser__c = false;
        acc.ERPID__c = '7777';
        insert acc;
        Project__c project = TestObjectsFactory.getProjectRecord('recordId');
        insert project;
        unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004'; 
        unit.Project__c = project.Id;
        insert unit;
        unit__c unit2 = TestObjectsFactory.unitDataSetup('25083');
        unit2.Status__c = 'Sold';
        unit2.Name = 'Test MAYAN-B1-1004'; 
        unit2.Project__c = project.Id;
        insert unit2;
        HexaBPM__SR_Status__c submittedStatus = TestObjectsFactory.getSRStatus('Submitted');
        insert submittedStatus;
        Id PropertyTransferNOCRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC');
        HexaBPM__SR_Template__c PTNSRTemplate = new HexaBPM__SR_Template__c();
        PTNSRTemplate.HexaBPM__Active__c = true;
        PTNSRTemplate.HexaBPM__SR_RecordType_API_Name__c = 'Property Transfer NOC';
        insert PTNSRTemplate;
        HexaBPM__Service_Request__c srExists = TestObjectsFactory.getServiceRequest(submittedStatus.Id, unit.Id, 'Property Transfer NOC', PropertyTransferNOCRTId, PTNSRTemplate.Id);
        srExists.TransferSellingPrice__c = 19500.01;
        srExists.HexaBPM__Customer__c = acc.Id;
        srExists.origin__c = 'Customer Portal';
        insert srExists;
    }
 
    @isTest
    static void callDuesCtrlr() {
        List<HexaBPM__Service_Request__c> existingSRs = [SELECT Id, Case__c FROM HexaBPM__Service_Request__c WHERE SRType__c = 'Property Transfer NOC' AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled')];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        ProvisOutstandingDuesController.getOutstandingFromERP(existingSRs[0].Id);
        List<String> labels = new List<String>{'mock_label'}; 
        Map<String, Object> state = new Map<String, Object>();       
        state.put('key', 'value');
        Object result = ProvisOutstandingDuesController.handleERPResponse(labels, state);
        Test.stopTest();
    }
 
    @isTest
    static void callDuesCtrlrExe() {
        List<HexaBPM__Service_Request__c> existingSRs = [SELECT Id, Case__c FROM HexaBPM__Service_Request__c WHERE SRType__c = 'Property Transfer NOC' AND HexaBPM__External_Status_Name__c NOT IN ('Draft', 'Cancelled')];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseExec());
        Test.startTest();
        ProvisOutstandingDuesController.getOutstandingFromERP(existingSRs[0].Id);
        List<String> labels = new List<String>{'mock_label'}; 
        Map<String, Object> state = new Map<String, Object>();       
        state.put('key', 'value');
        //Object result = ProvisOutstandingDuesController.handleERPResponse(labels, state);
        Test.stopTest();
    }
    

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"outstanding_dues": 5000}');
            return res;
        }
    }
 
    public class MockHttpResponseExec implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"outstanding_dues"}');
            return res;
        }
    }
}