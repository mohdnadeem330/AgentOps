@isTest
public class CustomerGetServiceRequestWebServiceTest {

    @isTest
    public static void testCustomerGetServiceRequestWebService() {
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = Constants.PENDING_STATUS;
        status.HexaBPM__Code__c = Constants.PENDING_STATUS;
        insert status;
        
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

        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Property Transfer', 'PropertyTransfer');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;

        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
       
        Id propertyTransferId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INVESTOR_CERTIFICATE_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INVESTOR_CERTIFICATE_RT, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.SalesOrder__c = salesorder.Id;
        newSR.Origin__c = CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL;
        insert newSR;
        CustomerGetServiceRequestWebService.ServiceRequestModel srm = new CustomerGetServiceRequestWebService.ServiceRequestModel(
                newSR,
                'Draft',
                'type'
            );

       // HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        //insert newStep;

        Case cs = TestObjectsFactory.getStandardCase(acc.Id, null, 'Compliance');
        cs.Unit__c = unit.Id;
        cs.SalesOrder__c = salesOrder.Id;
        cs.Origin = CustomerAPIConstants.CASE_ORIGIN_CUSTOMER_PORTAL;
        insert cs;

        TestObjectsFactory.initializeRestContext(null, '/query/getservicerequest');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            String reqBody = '{"customerId": "' + acc.Id + '","fromDate": "' + DateTime.now().addDays(-10).format('yyyy-MM-dd') + '","toDate": "' + DateTime.now().addDays(10).format('yyyy-MM-dd') + '","status": "","type": "","searchKey": [],"referenceId": ""}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerGetServiceRequestWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        try {
            String reqBody = '{"customerId": "' + acc.Id + '","fromDate": "' + DateTime.now().addDays(-10).format('yyyy-MM-dd') + '","toDate": "' + DateTime.now().addDays(10).format('yyyy-MM-dd') + '","status": "' + CustomerAPIConstants.STATUS_PROCESSING + '","type": "","searchKey": ["mayan"],"referenceId": ""}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerGetServiceRequestWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        try {
            String reqBody = '{"customerId": "' + acc.Id + '","fromDate": "' + DateTime.now().addDays(-10).format('yyyy-MM-dd') + '","toDate": "' + DateTime.now().format('yyyy-MM-dd') + '","status": "' + CustomerAPIConstants.STATUS_CLOSED + '","type": "","searchKey": ["mayan"],"referenceId": ""}';
            RestRequest req = RestContext.request;
            req.requestBody = Blob.valueOf(reqBody);
            CustomerGetServiceRequestWebService.doPost();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }
}