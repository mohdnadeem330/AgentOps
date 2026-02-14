@isTest
public class DLPCalloutUtilitiesTest {
    @isTest static void successCall() {
        
        Account account = TestObjectsFactory.getPersonAccountRecord();
        insert account;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Project__c pr = new Project__c(Id=unit.Project__c);
        pr.AsiteProjectName__c = 'Test';
        update pr;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 100000;
        insert salesOrder;
        
        Case cs = getStandardCase(account.Id, null, 'Compliance');
        //cs.Category__c = '';
        cs.SubVertical__c = 'DLP';
        cs.CaseCategory__c = 'Civil';
        cs.SubCategory__c = 'Walls/Ceiling';
        cs.Unit__c = unit.Id;
        insert cs;

        Appointment__c app = new Appointment__c();
        app.CaseNumber__c = cs.CaseNumber;
        app.AppointmentType__c = Constants.ASSESSMENT;
        insert app;
        
        Set<Id> casesIds = new Set<Id>();
        Set<Id> appointmentsIds = new Set<Id>();

        casesIds.add(cs.Id);
        appointmentsIds.add(app.Id);
        
        String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "201","correlationId": "67b32bd0-9cc1-11ed-8ad7-064a47d2b2b6","results": {"projectId": "2140476$$RKDreg","instanceGroupID": "10660700$$ePFXHa","formId": "11168550$$YNVeUT","msgId": "11560509$$hc8UnO"}}';
        //String failResponseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "500"}';

        Test.startTest();
        
        DLPMockResponse mock = new DLPMockResponse(responseBody, 201);
        
        Test.setMock(HttpCalloutMock.class, mock);
        System.enqueueJob(new DLPCalloutUtilities.AsiteIntegration(casesIds));
        System.enqueueJob(new DLPCalloutUtilities.BookingSystemIntegration(appointmentsIds));            
        
        Test.stopTest();
        
        
    }
    
    @isTest static void failCall() {
        
        Account account = TestObjectsFactory.getPersonAccountRecord();
        insert account;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Project__c pr = new Project__c(Id=unit.Project__c);
        pr.AsiteProjectName__c = 'Test';
        update pr;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 100000;
        insert salesOrder;
        
        Case cs = getStandardCase(account.Id, null, 'Compliance');
        //cs.Category__c = '';
        cs.SubVertical__c = 'DLP';
        cs.CaseCategory__c = 'Civil';
        cs.SubCategory__c = 'Walls/Ceiling';
        cs.Unit__c = unit.Id;
        insert cs;

        Appointment__c app = new Appointment__c();
        app.CaseNumber__c = cs.CaseNumber;
        app.AppointmentType__c = Constants.ASSESSMENT;
        insert app;
        
        Set<Id> casesIds = new Set<Id>();
        Set<Id> appointmentsIds = new Set<Id>();

        casesIds.add(cs.Id);
        appointmentsIds.add(app.Id);
        
        String responseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "500","correlationId": "67b32bd0-9cc1-11ed-8ad7-064a47d2b2b6","results": {"projectId": "2140476$$RKDreg","instanceGroupID": "10660700$$ePFXHa","formId": "11168550$$YNVeUT","msgId": "11560509$$hc8UnO"}}';
        //String failResponseBody = '{"applicationName": "x-ald-sferp-api","success": true,"statusCode": "500"}';

        Test.startTest();
        
        DLPMockResponse mock = new DLPMockResponse(responseBody, 500);
        
        Test.setMock(HttpCalloutMock.class, mock);
        System.enqueueJob(new DLPCalloutUtilities.AsiteIntegration(casesIds));
        System.enqueueJob(new DLPCalloutUtilities.BookingSystemIntegration(appointmentsIds));            
        
        Test.stopTest();
        
        
    }
    public static Case getStandardCase(Id accountId, Id contactId, String category) {
        Case newCase = new Case();
        newCase.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();
        newCase.Subject = 'Test Subject';
        newCase.Description = 'Test Description';
        newCase.Status = 'New';
        newCase.AccountId = accountId;
        newCase.ContactId = contactId;
        newCase.Category__c = category;
        newCase.CaseCategory__c = 'Unit Swap';
        newCase.SubVertical__c = 'Defaults & Collection';
        return newCase;
    }
}